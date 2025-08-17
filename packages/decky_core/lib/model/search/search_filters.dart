// Sentinel object to distinguish between null and unset parameters
const _sentinel = Object();

class SearchFilters {
  final String? query;
  final String? oracleText;
  final List<String>? colors;
  final List<String>? colorIdentity;
  final List<String>? types;
  final List<String>? subtypes;
  final List<String>? supertypes;
  final List<String>? keywords;
  final String? manaCost;
  final RangeFilter? manaValue;
  final RangeFilter? power;
  final RangeFilter? toughness;
  final RangeFilter? loyalty;
  final List<String>? rarities;
  final List<String>? sets;
  final Map<String, String>? formatLegalities; // format -> legality ('legal', 'restricted', 'banned')
  final RangeFilter? price;
  final String? priceCurrency; // 'usd', 'eur', 'tix'
  final String? artist;
  final bool? isReserved;
  final bool? isPromo;
  final bool? isFullArt;
  final bool? isReprint;
  final String? layout;
  final List<String>? frameEffects;
  final String? sortBy;
  final String? sortOrder; // 'asc' or 'desc'

  const SearchFilters({
    this.query,
    this.oracleText,
    this.colors,
    this.colorIdentity,
    this.types,
    this.subtypes,
    this.supertypes,
    this.keywords,
    this.manaCost,
    this.manaValue,
    this.power,
    this.toughness,
    this.loyalty,
    this.rarities,
    this.sets,
    this.formatLegalities,
    this.price,
    this.priceCurrency = 'usd',
    this.artist,
    this.isReserved,
    this.isPromo,
    this.isFullArt,
    this.isReprint,
    this.layout,
    this.frameEffects,
    this.sortBy,
    this.sortOrder = 'desc',
  });

  SearchFilters copyWith({
    String? query,
    String? oracleText,
    Object? colors = _sentinel,
    Object? colorIdentity = _sentinel,
    Object? types = _sentinel,
    Object? subtypes = _sentinel,
    Object? supertypes = _sentinel,
    Object? keywords = _sentinel,
    String? manaCost,
    Object? manaValue = _sentinel,
    Object? power = _sentinel,
    Object? toughness = _sentinel,
    Object? loyalty = _sentinel,
    Object? rarities = _sentinel,
    Object? sets = _sentinel,
    Object? formatLegalities = _sentinel,
    Object? price = _sentinel,
    String? priceCurrency,
    String? artist,
    bool? isReserved,
    bool? isPromo,
    bool? isFullArt,
    bool? isReprint,
    String? layout,
    Object? frameEffects = _sentinel,
    String? sortBy,
    String? sortOrder,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      oracleText: oracleText ?? this.oracleText,
      colors: colors == _sentinel ? this.colors : colors as List<String>?,
      colorIdentity: colorIdentity == _sentinel ? this.colorIdentity : colorIdentity as List<String>?,
      types: types == _sentinel ? this.types : types as List<String>?,
      subtypes: subtypes == _sentinel ? this.subtypes : subtypes as List<String>?,
      supertypes: supertypes == _sentinel ? this.supertypes : supertypes as List<String>?,
      keywords: keywords == _sentinel ? this.keywords : keywords as List<String>?,
      manaCost: manaCost ?? this.manaCost,
      manaValue: manaValue == _sentinel ? this.manaValue : manaValue as RangeFilter?,
      power: power == _sentinel ? this.power : power as RangeFilter?,
      toughness: toughness == _sentinel ? this.toughness : toughness as RangeFilter?,
      loyalty: loyalty == _sentinel ? this.loyalty : loyalty as RangeFilter?,
      rarities: rarities == _sentinel ? this.rarities : rarities as List<String>?,
      sets: sets == _sentinel ? this.sets : sets as List<String>?,
      formatLegalities: formatLegalities == _sentinel
          ? this.formatLegalities
          : formatLegalities as Map<String, String>?,
      price: price == _sentinel ? this.price : price as RangeFilter?,
      priceCurrency: priceCurrency ?? this.priceCurrency,
      artist: artist ?? this.artist,
      isReserved: isReserved ?? this.isReserved,
      isPromo: isPromo ?? this.isPromo,
      isFullArt: isFullArt ?? this.isFullArt,
      isReprint: isReprint ?? this.isReprint,
      layout: layout ?? this.layout,
      frameEffects: frameEffects == _sentinel ? this.frameEffects : frameEffects as List<String>?,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  bool get hasActiveFilters {
    return query?.isNotEmpty == true ||
        oracleText?.isNotEmpty == true ||
        colors?.isNotEmpty == true ||
        colorIdentity?.isNotEmpty == true ||
        types?.isNotEmpty == true ||
        subtypes?.isNotEmpty == true ||
        supertypes?.isNotEmpty == true ||
        keywords?.isNotEmpty == true ||
        manaCost?.isNotEmpty == true ||
        manaValue != null ||
        power != null ||
        toughness != null ||
        loyalty != null ||
        rarities?.isNotEmpty == true ||
        sets?.isNotEmpty == true ||
        formatLegalities?.isNotEmpty == true ||
        price != null ||
        artist?.isNotEmpty == true ||
        isReserved != null ||
        isPromo != null ||
        isFullArt != null ||
        isReprint != null ||
        layout?.isNotEmpty == true ||
        frameEffects?.isNotEmpty == true;
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'oracleText': oracleText,
      'colors': colors,
      'colorIdentity': colorIdentity,
      'types': types,
      'subtypes': subtypes,
      'supertypes': supertypes,
      'keywords': keywords,
      'manaCost': manaCost,
      'manaValue': manaValue?.toJson(),
      'power': power?.toJson(),
      'toughness': toughness?.toJson(),
      'loyalty': loyalty?.toJson(),
      'rarities': rarities,
      'sets': sets,
      'formatLegalities': formatLegalities,
      'price': price?.toJson(),
      'priceCurrency': priceCurrency,
      'artist': artist,
      'isReserved': isReserved,
      'isPromo': isPromo,
      'isFullArt': isFullArt,
      'isReprint': isReprint,
      'layout': layout,
      'frameEffects': frameEffects,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };
  }

  factory SearchFilters.fromJson(Map<String, dynamic> json) {
    return SearchFilters(
      query: json['query'],
      oracleText: json['oracleText'],
      colors: json['colors']?.cast<String>(),
      colorIdentity: json['colorIdentity']?.cast<String>(),
      types: json['types']?.cast<String>(),
      subtypes: json['subtypes']?.cast<String>(),
      supertypes: json['supertypes']?.cast<String>(),
      keywords: json['keywords']?.cast<String>(),
      manaCost: json['manaCost'],
      manaValue: json['manaValue'] != null ? RangeFilter.fromJson(json['manaValue']) : null,
      power: json['power'] != null ? RangeFilter.fromJson(json['power']) : null,
      toughness: json['toughness'] != null ? RangeFilter.fromJson(json['toughness']) : null,
      loyalty: json['loyalty'] != null ? RangeFilter.fromJson(json['loyalty']) : null,
      rarities: json['rarities']?.cast<String>(),
      sets: json['sets']?.cast<String>(),
      formatLegalities: json['formatLegalities']?.cast<String, String>(),
      price: json['price'] != null ? RangeFilter.fromJson(json['price']) : null,
      priceCurrency: json['priceCurrency'] ?? 'usd',
      artist: json['artist'],
      isReserved: json['isReserved'],
      isPromo: json['isPromo'],
      isFullArt: json['isFullArt'],
      isReprint: json['isReprint'],
      layout: json['layout'],
      frameEffects: json['frameEffects']?.cast<String>(),
      sortBy: json['sortBy'],
      sortOrder: json['sortOrder'] ?? 'desc',
    );
  }
}

class RangeFilter {
  final double? min;
  final double? max;

  const RangeFilter({this.min, this.max});

  RangeFilter copyWith({double? min, double? max}) {
    return RangeFilter(min: min ?? this.min, max: max ?? this.max);
  }

  Map<String, dynamic> toJson() {
    return {'min': min, 'max': max};
  }

  factory RangeFilter.fromJson(Map<String, dynamic> json) {
    return RangeFilter(min: json['min']?.toDouble(), max: json['max']?.toDouble());
  }

  bool get hasValue => min != null || max != null;
}
