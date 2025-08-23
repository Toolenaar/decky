import 'dart:async';
import '../controller/user_collection_controller.dart';
import '../model/search/card_search_result.dart';
import '../model/search/search_filters.dart';
import '../model/search/filter_options.dart';
import '../model/collection_card.dart';
import 'base_search_provider.dart';

class CollectionSearchProvider extends BaseSearchProvider {
  final UserCollectionController _collectionController;
  
  CollectionSearchProvider(this._collectionController) {
    _initializeSearch();
  }

  // State management
  SearchState _state = SearchState.initial;
  @override
  SearchState get state => _state;

  String? _errorMessage;
  @override
  String get errorMessage => _errorMessage ?? '';

  // Search query and filters
  String _query = '';
  @override
  String get query => _query;

  SearchFilters _filters = const SearchFilters();
  @override
  SearchFilters get filters => _filters;

  // Results
  List<CardSearchResult> _results = [];
  @override
  List<CardSearchResult> get results => _results;

  bool _hasMoreResults = true;
  @override
  bool get hasMoreResults => _hasMoreResults;

  int _totalResults = 0;
  @override
  int get totalResults => _totalResults;

  // Filter options - populated from collection
  FilterOptions _filterOptions = FilterOptions.empty();
  @override
  FilterOptions get filterOptions => _filterOptions;

  // Autocomplete (simplified for collection)
  List<String> _autocompleteSuggestions = [];
  @override
  List<String> get autocompleteSuggestions => _autocompleteSuggestions;

  // Recent searches
  List<String> _recentSearches = [];
  @override
  List<String> get recentSearches => _recentSearches;

  // Pagination
  static const int _pageSize = 20;
  int _currentPage = 0;

  // Collection data cache
  List<CollectionCard> _allCollectionCards = [];
  List<CollectionCard> _filteredCards = [];
  StreamSubscription<List<CollectionCard>>? _collectionSubscription;

  void _initializeSearch() {
    // Listen to collection cards stream for real-time updates
    _collectionSubscription = _collectionController.collectionCardsStream.listen((cards) {
      _allCollectionCards = cards;
      _buildFilterOptions();
      // Re-perform search if there are active filters/query
      if (_query.isNotEmpty || _filters.hasActiveFilters) {
        _performSearch(reset: true);
      }
      notifyListeners();
    });
    _collectionController.addListener(_onCollectionChanged);
  }

  void _onCollectionChanged() {
    _loadCollectionData();
  }

  Future<void> _loadCollectionData() async {
    try {
      _setState(SearchState.loading);
      _allCollectionCards = _collectionController.collectionCards;
      _buildFilterOptions();
      // Perform initial search to populate results if there are active filters/query
      if (_query.isNotEmpty || _filters.hasActiveFilters) {
        await _performSearch(reset: true);
      } else {
        _setState(SearchState.loaded);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setState(SearchState.error);
    }
  }

  void _buildFilterOptions() {
    final colors = <String>{};
    final types = <String>{};
    final rarities = <String>{};

    for (final card in _allCollectionCards) {
      // Extract colors
      if (card.mtgCardReference.colorIdentity?.isNotEmpty == true) {
        colors.addAll(card.mtgCardReference.colorIdentity!);
      }
      
      // Extract types
      if (card.mtgCardReference.type?.isNotEmpty == true) {
        final cardTypes = card.mtgCardReference.type!.split(' ');
        for (final type in cardTypes) {
          if (type.isNotEmpty && !['—', '-', '//'].contains(type)) {
            types.add(type);
          }
        }
      }
      
      // Extract rarities
      if (card.mtgCardReference.rarity?.isNotEmpty == true) {
        rarities.add(card.mtgCardReference.rarity!);
      }
    }

    _filterOptions = FilterOptions(
      colors: colors.map((color) => ColorOption(color, color, 0xFFCCCCCC)).toList(),
      types: types.toList()..sort(),
      subtypes: [],
      supertypes: [],
      rarities: rarities.toList()..sort(),
      sets: [],
      keywords: [],
      formats: [],
      layouts: [],
      frameEffects: [],
    );
  }

  @override
  void updateQuery(String newQuery) {
    if (_query != newQuery) {
      _query = newQuery;
      _filters = _filters.copyWith(query: newQuery.isEmpty ? null : newQuery);
      _performSearch(reset: true);
      notifyListeners();
    }
  }

  @override
  void updateFilters(SearchFilters newFilters) {
    if (_filters != newFilters) {
      _filters = newFilters;
      notifyListeners();
      _performSearch(reset: true);
    }
  }

  @override
  void addColorFilter(String color) {
    final colors = List<String>.from(_filters.colors ?? []);
    if (!colors.contains(color)) {
      colors.add(color);
      updateFilters(_filters.copyWith(colors: colors));
    }
  }

  @override
  void removeColorFilter(String color) {
    final colors = List<String>.from(_filters.colors ?? []);
    colors.remove(color);
    updateFilters(_filters.copyWith(colors: colors.isEmpty ? null : colors));
  }

  @override
  void addTypeFilter(String type) {
    final types = List<String>.from(_filters.types ?? []);
    if (!types.contains(type)) {
      types.add(type);
      updateFilters(_filters.copyWith(types: types));
    }
  }

  @override
  void removeTypeFilter(String type) {
    final types = List<String>.from(_filters.types ?? []);
    types.remove(type);
    updateFilters(_filters.copyWith(types: types.isEmpty ? null : types));
  }

  @override
  void addRarityFilter(String rarity) {
    final rarities = List<String>.from(_filters.rarities ?? []);
    if (!rarities.contains(rarity)) {
      rarities.add(rarity);
      updateFilters(_filters.copyWith(rarities: rarities));
    }
  }

  @override
  void removeRarityFilter(String rarity) {
    final rarities = List<String>.from(_filters.rarities ?? []);
    rarities.remove(rarity);
    updateFilters(_filters.copyWith(rarities: rarities.isEmpty ? null : rarities));
  }

  @override
  void addConvertedManaCostFilter(String manaCost) {
    final manaCosts = List<String>.from(_filters.convertedManaCosts ?? []);
    if (!manaCosts.contains(manaCost)) {
      manaCosts.add(manaCost);
      updateFilters(_filters.copyWith(convertedManaCosts: manaCosts));
    }
  }

  @override
  void removeConvertedManaCostFilter(String manaCost) {
    final manaCosts = List<String>.from(_filters.convertedManaCosts ?? []);
    manaCosts.remove(manaCost);
    updateFilters(_filters.copyWith(convertedManaCosts: manaCosts.isEmpty ? null : manaCosts));
  }

  @override
  void setManaValueRange(double? min, double? max) {
    final range = (min == null && max == null) ? null : RangeFilter(min: min, max: max);
    updateFilters(_filters.copyWith(manaValue: range));
  }

  @override
  void setPriceRange(double? min, double? max) {
    final range = (min == null && max == null) ? null : RangeFilter(min: min, max: max);
    updateFilters(_filters.copyWith(price: range));
  }

  @override
  void setFormatLegality(String format, String? legality) {
    final legalities = Map<String, String>.from(_filters.formatLegalities ?? {});
    if (legality == null) {
      legalities.remove(format);
    } else {
      legalities[format] = legality;
    }
    updateFilters(_filters.copyWith(formatLegalities: legalities.isEmpty ? null : legalities));
  }

  @override
  void applySortOrder(String sortBy, String sortOrder) {
    updateFilters(_filters.copyWith(sortBy: sortBy, sortOrder: sortOrder));
  }

  @override
  void applyQuickFilter(SearchFilters quickFilters) {
    updateFilters(quickFilters);
  }

  @override
  void clearFilters() {
    _filters = SearchFilters(query: _query.isEmpty ? null : _query);
    _performSearch(reset: true);
  }

  @override
  void clearAll() {
    _query = '';
    _filters = const SearchFilters();
    _results.clear();
    _filteredCards.clear();
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

    _setState(SearchState.loading);

    try {
      // Filter collection cards based on filters
      _filteredCards = _filterCollectionCards();
      
      // Sort results
      _sortFilteredCards();
      
      // Paginate results
      final startIndex = _currentPage * _pageSize;
      final endIndex = (startIndex + _pageSize).clamp(0, _filteredCards.length);
      
      final pageCards = _filteredCards.sublist(startIndex, endIndex);
      final pageResults = pageCards.map((card) => _convertToSearchResult(card)).toList();
      
      if (reset) {
        _results = pageResults;
      } else {
        _results.addAll(pageResults);
      }

      _hasMoreResults = endIndex < _filteredCards.length;
      _totalResults = _filteredCards.length;

      if (reset && _query.isNotEmpty && !_recentSearches.contains(_query)) {
        _recentSearches.insert(0, _query);
        if (_recentSearches.length > 10) {
          _recentSearches = _recentSearches.take(10).toList();
        }
      }

      _setState(SearchState.loaded);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(SearchState.error);
    }
  }

  List<CollectionCard> _filterCollectionCards() {
    return _allCollectionCards.where((collectionCard) {
      final card = collectionCard.mtgCardReference;
      
      // Text search
      if (_query.isNotEmpty) {
        final searchText = _query.toLowerCase();
        if (!(card.name.toLowerCase().contains(searchText) ||
              (card.text?.toLowerCase().contains(searchText) == true) ||
              card.type.toLowerCase().contains(searchText))) {
          return false;
        }
      }
      
      // Color filters
      if (_filters.colors?.isNotEmpty == true) {
        final cardColors = Set<String>.from(card.colorIdentity);
        final selectedColors = Set<String>.from(_filters.colors!);
        if (!selectedColors.any((color) => cardColors.contains(color))) {
          return false;
        }
      }
      
      // Type filters
      if (_filters.types?.isNotEmpty == true) {
        final cardType = card.type.toLowerCase();
        if (!_filters.types!.any((type) => cardType.contains(type.toLowerCase()))) {
          return false;
        }
      }
      
      // Rarity filters
      if (_filters.rarities?.isNotEmpty == true) {
        if (!_filters.rarities!.contains(card.rarity)) {
          return false;
        }
      }
      
      // Mana cost filters
      if (_filters.convertedManaCosts?.isNotEmpty == true) {
        final manaValue = card.manaValue;
        bool matchesManaCost = false;
        
        for (final filter in _filters.convertedManaCosts!) {
          switch (filter) {
            case '1-':
              if (manaValue <= 1) matchesManaCost = true;
              break;
            case '2':
              if (manaValue == 2) matchesManaCost = true;
              break;
            case '3':
              if (manaValue == 3) matchesManaCost = true;
              break;
            case '4':
              if (manaValue == 4) matchesManaCost = true;
              break;
            case '5':
              if (manaValue == 5) matchesManaCost = true;
              break;
            case '6+':
              if (manaValue >= 6) matchesManaCost = true;
              break;
          }
        }
        
        if (!matchesManaCost) return false;
      }
      
      // Mana value range
      if (_filters.manaValue != null) {
        final manaValue = card.manaValue;
        if (_filters.manaValue!.min != null && manaValue < _filters.manaValue!.min!) {
          return false;
        }
        if (_filters.manaValue!.max != null && manaValue > _filters.manaValue!.max!) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  void _sortFilteredCards() {
    final sortBy = _filters.sortBy ?? 'name';
    final isAscending = _filters.sortOrder != 'desc';
    
    _filteredCards.sort((a, b) {
      late int comparison;
      
      switch (sortBy) {
        case 'name':
          comparison = a.mtgCardReference.name.compareTo(b.mtgCardReference.name);
          break;
        case 'mana_value':
          comparison = a.mtgCardReference.manaValue.compareTo(b.mtgCardReference.manaValue);
          break;
        case 'rarity':
          final rarityOrder = ['common', 'uncommon', 'rare', 'mythic'];
          final aRarity = rarityOrder.indexOf(a.mtgCardReference.rarity.toLowerCase());
          final bRarity = rarityOrder.indexOf(b.mtgCardReference.rarity.toLowerCase());
          comparison = aRarity.compareTo(bRarity);
          break;
        case 'quantity':
          comparison = a.count.compareTo(b.count);
          break;
        default:
          comparison = a.mtgCardReference.name.compareTo(b.mtgCardReference.name);
      }
      
      return isAscending ? comparison : -comparison;
    });
  }

  CardSearchResult _convertToSearchResult(CollectionCard collectionCard) {
    final card = collectionCard.mtgCardReference;
    return CardSearchResult(
      id: card.id,
      name: card.name,
      manaCost: card.manaCost,
      type: card.type,
      setCode: card.setCode,
      rarity: card.rarity,
      colors: card.colors,
      firebaseImageUris: card.firebaseImageUris,
    );
  }

  @override
  Future<void> loadMore() async {
    if (!_hasMoreResults || _state == SearchState.loading) return;
    
    _currentPage++;
    await _performSearch();
  }

  @override
  Future<void> refresh() async {
    await _loadCollectionData();
    await _performSearch(reset: true);
  }

  @override
  Future<void> loadAutocompleteSuggestions(String query) async {
    if (query.isEmpty) {
      _autocompleteSuggestions.clear();
      notifyListeners();
      return;
    }

    final suggestions = <String>{};
    final searchText = query.toLowerCase();
    
    for (final collectionCard in _allCollectionCards) {
      final card = collectionCard.mtgCardReference;
      if (card.name.toLowerCase().contains(searchText)) {
        suggestions.add(card.name);
      }
    }
    
    _autocompleteSuggestions = suggestions.take(10).toList()..sort();
    notifyListeners();
  }

  void _setState(SearchState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _collectionSubscription?.cancel();
    _collectionController.removeListener(_onCollectionChanged);
    super.dispose();
  }

  // Utility getters
  @override
  bool get hasResults => _results.isNotEmpty;
  
  @override
  bool get isLoading => _state == SearchState.loading;
  
  @override
  bool get hasError => _state == SearchState.error;
  
  @override
  bool get isEmpty => _state == SearchState.loaded && _results.isEmpty;
  
  @override
  bool get hasActiveFilters => _filters.hasActiveFilters;

  // Quick access to common filter states
  @override
  List<String> get selectedColors => _filters.colors ?? [];
  
  @override
  List<String> get selectedTypes => _filters.types ?? [];
  
  @override
  List<String> get selectedRarities => _filters.rarities ?? [];
  
  @override
  List<String> get selectedConvertedManaCosts => _filters.convertedManaCosts ?? [];
  
  @override
  Map<String, String> get selectedFormats => _filters.formatLegalities ?? {};
  
  @override
  RangeFilter? get manaValueRange => _filters.manaValue;
  
  @override
  RangeFilter? get priceRange => _filters.price;

  // Active filter count for UI
  @override
  int get activeFilterCount {
    int count = 0;
    if (_filters.colors?.isNotEmpty == true) count++;
    if (_filters.types?.isNotEmpty == true) count++;
    if (_filters.rarities?.isNotEmpty == true) count++;
    if (_filters.convertedManaCosts?.isNotEmpty == true) count++;
    if (_filters.formatLegalities?.isNotEmpty == true) count++;
    if (_filters.manaValue != null) count++;
    if (_filters.price != null) count++;
    if (_filters.oracleText?.isNotEmpty == true) count++;
    if (_filters.artist?.isNotEmpty == true) count++;
    if (_filters.isReserved != null) count++;
    if (_filters.isPromo != null) count++;
    return count;
  }
}

