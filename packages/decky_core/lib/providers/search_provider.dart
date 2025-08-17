import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controller/elasticsearch_service.dart';
import '../controller/task_controller.dart';
import '../model/search/card_search_result.dart';
import '../model/search/search_filters.dart';
import '../model/search/filter_options.dart';
import '../model/mtg/mtg_card.dart';

enum SearchState { initial, loading, loaded, error }

class SearchProvider extends ChangeNotifier {
  final ElasticsearchService _elasticsearchService;
  final TaskController _taskController = TaskController();

  SearchProvider(this._elasticsearchService) {
    _initializeSearch();
  }

  // State management
  SearchState _state = SearchState.initial;
  SearchState get state => _state;

  String? _errorMessage;
  String get errorMessage => _errorMessage ?? '';

  // Search query and filters
  String _query = '';
  String get query => _query;

  SearchFilters _filters = const SearchFilters();
  SearchFilters get filters => _filters;

  // Results
  List<CardSearchResult> _results = [];
  List<CardSearchResult> get results => _results;

  bool _hasMoreResults = true;
  bool get hasMoreResults => _hasMoreResults;

  int _totalResults = 0;
  int get totalResults => _totalResults;

  // Pagination
  static const int _pageSize = 20;
  int _currentPage = 0;

  // Filter options
  FilterOptions _filterOptions = FilterOptions.empty();
  FilterOptions get filterOptions => _filterOptions;

  // Autocomplete
  List<String> _autocompleteSuggestions = [];
  List<String> get autocompleteSuggestions => _autocompleteSuggestions;

  // Recent searches
  List<String> _recentSearches = [];
  List<String> get recentSearches => _recentSearches;

  // Search history with debouncing
  final BehaviorSubject<String> _searchSubject = BehaviorSubject<String>();
  StreamSubscription? _searchSubscription;

  void _initializeSearch() {
    // Load filter options
    _loadFilterOptions();

    // Set up debounced search
    _searchSubscription = _searchSubject.debounceTime(const Duration(milliseconds: 300)).distinct().listen((query) {
      if (query.isNotEmpty) {
        _performSearch(reset: true);
      }
    });
  }

  Future<void> _loadFilterOptions() async {
    try {
      _filterOptions = await _elasticsearchService.getFilterOptions();
      notifyListeners();
    } catch (e) {
      _filterOptions = FilterOptions.defaults();
      notifyListeners();
    }
  }

  void updateQuery(String newQuery) {
    if (_query != newQuery) {
      _query = newQuery;
      _filters = _filters.copyWith(query: newQuery.isEmpty ? null : newQuery);
      _searchSubject.add(newQuery);
      notifyListeners();
    }
  }

  void updateFilters(SearchFilters newFilters) {
    if (_filters != newFilters) {
      _filters = newFilters;
      notifyListeners();
      _performSearch(reset: true);
    }
  }

  void addColorFilter(String color) {
    final colors = List<String>.from(_filters.colors ?? []);
    if (!colors.contains(color)) {
      colors.add(color);
      updateFilters(_filters.copyWith(colors: colors));
    }
  }

  void removeColorFilter(String color) {
    final colors = List<String>.from(_filters.colors ?? []);
    colors.remove(color);
    updateFilters(_filters.copyWith(colors: colors.isEmpty ? null : colors));
  }

  void addTypeFilter(String type) {
    final types = List<String>.from(_filters.types ?? []);
    if (!types.contains(type)) {
      types.add(type);
      updateFilters(_filters.copyWith(types: types));
    }
  }

  void removeTypeFilter(String type) {
    final types = List<String>.from(_filters.types ?? []);
    types.remove(type);
    updateFilters(_filters.copyWith(types: types.isEmpty ? null : types));
  }

  void addRarityFilter(String rarity) {
    final rarities = List<String>.from(_filters.rarities ?? []);
    if (!rarities.contains(rarity)) {
      rarities.add(rarity);
      updateFilters(_filters.copyWith(rarities: rarities));
    }
  }

  void removeRarityFilter(String rarity) {
    final rarities = List<String>.from(_filters.rarities ?? []);
    rarities.remove(rarity);
    updateFilters(_filters.copyWith(rarities: rarities.isEmpty ? null : rarities));
  }

  void setManaValueRange(double? min, double? max) {
    final range = (min == null && max == null) ? null : RangeFilter(min: min, max: max);
    updateFilters(_filters.copyWith(manaValue: range));
  }

  void setPriceRange(double? min, double? max) {
    final range = (min == null && max == null) ? null : RangeFilter(min: min, max: max);
    updateFilters(_filters.copyWith(price: range));
  }

  void setFormatLegality(String format, String? legality) {
    final legalities = Map<String, String>.from(_filters.formatLegalities ?? {});
    if (legality == null) {
      legalities.remove(format);
    } else {
      legalities[format] = legality;
    }
    updateFilters(_filters.copyWith(formatLegalities: legalities.isEmpty ? null : legalities));
  }

  void applySortOrder(String sortBy, String sortOrder) {
    updateFilters(_filters.copyWith(sortBy: sortBy, sortOrder: sortOrder));
  }

  void applyQuickFilter(SearchFilters quickFilters) {
    updateFilters(quickFilters);
  }

  void clearFilters() {
    _filters = SearchFilters(query: _query.isEmpty ? null : _query);
    _performSearch(reset: true);
  }

  void clearAll() {
    _query = '';
    _filters = const SearchFilters();
    _results.clear();
    _hasMoreResults = true;
    _totalResults = 0;
    _currentPage = 0;
    _state = SearchState.initial;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _performSearch({bool reset = false}) async {
    if (reset) {
      _currentPage = 0;
      _results.clear();
      _hasMoreResults = true;
    }

    if (_state == SearchState.loading) return;

    _setState(SearchState.loading);

    try {
      final searchResults = await _elasticsearchService.searchCardsWithFilters(
        filters: _filters,
        size: _pageSize,
        from: _currentPage * _pageSize,
      );

      if (reset) {
        _results = searchResults;
      } else {
        _results.addAll(searchResults);
      }

      _hasMoreResults = searchResults.length == _pageSize;
      _totalResults = _results.length; // This is a simplified count

      if (reset && _query.isNotEmpty && !_recentSearches.contains(_query)) {
        _recentSearches.insert(0, _query);
        if (_recentSearches.length > 10) {
          _recentSearches = _recentSearches.take(10).toList();
        }
      }

      _setState(SearchState.loaded);

      // Check for cards that need updating and create tasks (do this after setting loaded state)
      // Run asynchronously to not block the UI
      _checkAndCreateUpdateTasks(searchResults);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(SearchState.error);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMoreResults || _state == SearchState.loading) return;

    _currentPage++;
    await _performSearch();
  }

  Future<void> refresh() async {
    await _performSearch(reset: true);
  }

  Future<void> loadAutocompleteSuggestions(String query) async {
    if (query.isEmpty) {
      _autocompleteSuggestions.clear();
      notifyListeners();
      return;
    }

    try {
      _autocompleteSuggestions = await _elasticsearchService.getAutocompleteSuggestions(query);
      notifyListeners();
    } catch (e) {
      _autocompleteSuggestions.clear();
      notifyListeners();
    }
  }

  void _setState(SearchState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchSubscription?.cancel();
    _searchSubject.close();
    super.dispose();
  }

  // Utility getters
  bool get hasResults => _results.isNotEmpty;
  bool get isLoading => _state == SearchState.loading;
  bool get hasError => _state == SearchState.error;
  bool get isEmpty => _state == SearchState.loaded && _results.isEmpty;
  bool get hasActiveFilters => _filters.hasActiveFilters;

  // Quick access to common filter states
  List<String> get selectedColors => _filters.colors ?? [];
  List<String> get selectedTypes => _filters.types ?? [];
  List<String> get selectedRarities => _filters.rarities ?? [];
  Map<String, String> get selectedFormats => _filters.formatLegalities ?? {};
  RangeFilter? get manaValueRange => _filters.manaValue;
  RangeFilter? get priceRange => _filters.price;

  // Active filter count for UI
  int get activeFilterCount {
    int count = 0;
    if (_filters.colors?.isNotEmpty == true) count++;
    if (_filters.types?.isNotEmpty == true) count++;
    if (_filters.rarities?.isNotEmpty == true) count++;
    if (_filters.formatLegalities?.isNotEmpty == true) count++;
    if (_filters.manaValue != null) count++;
    if (_filters.price != null) count++;
    if (_filters.oracleText?.isNotEmpty == true) count++;
    if (_filters.artist?.isNotEmpty == true) count++;
    if (_filters.isReserved != null) count++;
    if (_filters.isPromo != null) count++;
    return count;
  }

  // Check search results for cards that need updating and create tasks
  Future<void> _checkAndCreateUpdateTasks(List<CardSearchResult> searchResults) async {
    // Don't create tasks if we have errors
    if (_state == SearchState.error) {
      return;
    }

    // Limit the number of cards we check per search to avoid overwhelming the system
    const maxCardsToCheck = 10;
    final cardsToCheck = searchResults.take(maxCardsToCheck).toList();

    if (kDebugMode) {
      print('Checking ${cardsToCheck.length} cards for updates (state: ${_state.name})');
    }

    for (final result in cardsToCheck) {
      try {
        // Quick check: if the card has no images in search results, it definitely needs updating
        if (result.firebaseImageUris == null || !result.firebaseImageUris!.hasAnyImage) {
          await _createUpdateTaskForCard(result.id, 'missing_images_in_search');
          continue;
        }

        // For more detailed checks, we'd need to fetch the full card document
        // For now, we'll do a basic check based on search result data
        await _checkCardNeedsDetailedUpdate(result.id);
      } catch (e) {
        // Continue with other cards if one fails
        continue;
      }
    }
  }

  Future<void> _checkCardNeedsDetailedUpdate(String cardId) async {
    try {
      // Fetch the full card document to make detailed checks
      final cardDoc = await FirebaseFirestore.instance.collection('cards').doc(cardId).get();
      if (!cardDoc.exists) return;

      final card = MtgCard.fromJson({...cardDoc.data()!, 'uuid': cardDoc.id});

      if (await _taskController.shouldUpdateCard(card)) {
        final reason = await _taskController.determineUpdateReason(card);
        await _createUpdateTaskForCard(cardId, reason);
      }
    } catch (e) {
      // Silently fail - we don't want search to break because of task creation issues
    }
  }

  Future<void> _createUpdateTaskForCard(String cardId, String reason) async {
    try {
      // Check if task already exists
      if (await _taskController.hasExistingTask(cardId)) {
        if (kDebugMode) {
          print('Task already exists for card: $cardId');
        }
        return; // Task already exists
      }

      // Determine if we should skip image download based on reason
      final skipImageDownload = reason == 'scheduled_refresh' && reason != 'missing_images_in_search';

      final task = await _taskController.createCardUpdateTask(
        cardId,
        skipImageDownload: skipImageDownload,
        reason: reason,
      );

      if (kDebugMode) {
        if (task != null) {
          // print('Created update task for card: $cardId (reason: $reason)');
        } else {
          print('Failed to create task for card: $cardId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating task for card $cardId: $e');
      }
      // Silently fail - we don't want search to break because of task creation issues
    }
  }
}
