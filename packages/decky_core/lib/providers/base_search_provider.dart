import 'package:flutter/foundation.dart';
import '../model/search/card_search_result.dart';
import '../model/search/search_filters.dart';
import '../model/search/filter_options.dart';

enum SearchState { initial, loading, loaded, error }

abstract class BaseSearchProvider extends ChangeNotifier {
  SearchState get state;
  String get errorMessage;
  String get query;
  SearchFilters get filters;
  List<CardSearchResult> get results;
  bool get hasMoreResults;
  int get totalResults;
  FilterOptions get filterOptions;
  List<String> get autocompleteSuggestions;
  List<String> get recentSearches;

  // State getters
  bool get hasResults;
  bool get isLoading;
  bool get hasError;
  bool get isEmpty;
  bool get hasActiveFilters;

  // Filter getters
  List<String> get selectedColors;
  List<String> get selectedTypes;
  List<String> get selectedRarities;
  List<String> get selectedConvertedManaCosts;
  Map<String, String> get selectedFormats;
  RangeFilter? get manaValueRange;
  RangeFilter? get priceRange;
  int get activeFilterCount;

  // Search methods
  void updateQuery(String newQuery);
  void updateFilters(SearchFilters newFilters);

  // Filter methods
  void addColorFilter(String color);
  void removeColorFilter(String color);
  void addTypeFilter(String type);
  void removeTypeFilter(String type);
  void addRarityFilter(String rarity);
  void removeRarityFilter(String rarity);
  void addConvertedManaCostFilter(String manaCost);
  void removeConvertedManaCostFilter(String manaCost);
  void setManaValueRange(double? min, double? max);
  void setPriceRange(double? min, double? max);
  void setFormatLegality(String format, String? legality);
  void applySortOrder(String sortBy, String sortOrder);
  void applyQuickFilter(SearchFilters quickFilters);

  // Clear methods
  void clearFilters();
  void clearAll();

  // Load methods
  Future<void> loadMore();
  Future<void> refresh();
  Future<void> loadAutocompleteSuggestions(String query);
}