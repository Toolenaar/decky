import 'search_filters.dart';

class FilterOptions {
  final List<ColorOption> colors;
  final List<String> types;
  final List<String> subtypes;
  final List<String> supertypes;
  final List<String> rarities;
  final List<SetOption> sets;
  final List<String> keywords;
  final List<String> formats;
  final List<String> layouts;
  final List<String> frameEffects;
  final Map<String, int> aggregations;

  const FilterOptions({
    required this.colors,
    required this.types,
    required this.subtypes,
    required this.supertypes,
    required this.rarities,
    required this.sets,
    required this.keywords,
    required this.formats,
    required this.layouts,
    required this.frameEffects,
    this.aggregations = const {},
  });

  factory FilterOptions.empty() {
    return const FilterOptions(
      colors: [],
      types: [],
      subtypes: [],
      supertypes: [],
      rarities: [],
      sets: [],
      keywords: [],
      formats: [],
      layouts: [],
      frameEffects: [],
    );
  }

  factory FilterOptions.defaults() {
    return FilterOptions(
      colors: [
        ColorOption('W', 'White', 0xFFFFFBD5),
        ColorOption('U', 'Blue', 0xFF0E68AB),
        ColorOption('B', 'Black', 0xFF150B00),
        ColorOption('R', 'Red', 0xFFD3202A),
        ColorOption('G', 'Green', 0xFF00733E),
        ColorOption('C', 'Colorless', 0xFFCCC2C0),
      ],
      types: ['Artifact', 'Battle', 'Creature', 'Enchantment', 'Instant', 'Land', 'Planeswalker', 'Sorcery', 'Tribal'],
      subtypes: [], // Will be populated from aggregations
      supertypes: ['Basic', 'Legendary', 'Snow', 'World'],
      rarities: ['common', 'uncommon', 'rare', 'mythic'],
      sets: [], // Will be populated from aggregations
      keywords: [], // Will be populated from aggregations
      formats: ['standard', 'modern', 'legacy', 'vintage', 'commander', 'pioneer', 'historic', 'pauper', 'brawl'],
      layouts: ['normal', 'split', 'flip', 'transform', 'modal_dfc', 'adventure', 'planar', 'scheme', 'vanguard'],
      frameEffects: [
        'legendary',
        'miracle',
        'nyxtouched',
        'draft',
        'devoid',
        'tombstone',
        'colorshifted',
        'inverted',
        'snow',
        'showcase',
        'extendedart',
        'companion',
      ],
    );
  }

  FilterOptions copyWith({
    List<ColorOption>? colors,
    List<String>? types,
    List<String>? subtypes,
    List<String>? supertypes,
    List<String>? rarities,
    List<SetOption>? sets,
    List<String>? keywords,
    List<String>? formats,
    List<String>? layouts,
    List<String>? frameEffects,
    Map<String, int>? aggregations,
  }) {
    return FilterOptions(
      colors: colors ?? this.colors,
      types: types ?? this.types,
      subtypes: subtypes ?? this.subtypes,
      supertypes: supertypes ?? this.supertypes,
      rarities: rarities ?? this.rarities,
      sets: sets ?? this.sets,
      keywords: keywords ?? this.keywords,
      formats: formats ?? this.formats,
      layouts: layouts ?? this.layouts,
      frameEffects: frameEffects ?? this.frameEffects,
      aggregations: aggregations ?? this.aggregations,
    );
  }
}

class ColorOption {
  final String symbol;
  final String name;
  final int color;

  const ColorOption(this.symbol, this.name, this.color);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ColorOption && other.symbol == symbol;
  }

  @override
  int get hashCode => symbol.hashCode;
}

class SetOption {
  final String code;
  final String name;
  final String? releaseDate;
  final int cardCount;

  const SetOption({required this.code, required this.name, this.releaseDate, this.cardCount = 0});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SetOption && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}

class QuickFilter {
  final String name;
  final String description;
  final SearchFilters filters;
  final String icon;

  const QuickFilter({required this.name, required this.description, required this.filters, required this.icon});

  static List<QuickFilter> get defaults => [
    QuickFilter(
      name: 'Standard Legal',
      description: 'Cards legal in Standard format',
      filters: SearchFilters(formatLegalities: {'standard': 'legal'}, sortBy: 'name.keyword'),
      icon: '⚖️',
    ),
    QuickFilter(
      name: 'Budget Cards',
      description: 'Cards under \$1',
      filters: SearchFilters(price: RangeFilter(max: 1.0), priceCurrency: 'usd', sortBy: 'name.keyword'),
      icon: '💰',
    ),
    QuickFilter(
      name: 'Creatures',
      description: 'All creature cards',
      filters: SearchFilters(types: ['Creature'], sortBy: 'mana_value'),
      icon: '🐲',
    ),
    QuickFilter(
      name: 'Legendary',
      description: 'Legendary permanents',
      filters: SearchFilters(supertypes: ['Legendary'], sortBy: 'name.keyword'),
      icon: '👑',
    ),
    QuickFilter(
      name: 'Artifacts',
      description: 'All artifact cards',
      filters: SearchFilters(types: ['Artifact'], sortBy: 'mana_value'),
      icon: '⚙️',
    ),
    QuickFilter(
      name: 'Planeswalkers',
      description: 'All planeswalker cards',
      filters: SearchFilters(types: ['Planeswalker'], sortBy: 'mana_value'),
      icon: '✨',
    ),
  ];
}
