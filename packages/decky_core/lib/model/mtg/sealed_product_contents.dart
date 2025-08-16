class SealedProductCard {
  final bool? foil;
  final String name;
  final String number;
  final String set;
  final String uuid;

  SealedProductCard({
    this.foil,
    required this.name,
    required this.number,
    required this.set,
    required this.uuid,
  });

  factory SealedProductCard.fromJson(Map<String, dynamic> json) {
    return SealedProductCard(
      foil: json['foil'],
      name: json['name'],
      number: json['number'],
      set: json['set'],
      uuid: json['uuid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (foil != null) 'foil': foil,
      'name': name,
      'number': number,
      'set': set,
      'uuid': uuid,
    };
  }
}

class SealedProductDeck {
  final String name;
  final String set;

  SealedProductDeck({
    required this.name,
    required this.set,
  });

  factory SealedProductDeck.fromJson(Map<String, dynamic> json) {
    return SealedProductDeck(
      name: json['name'],
      set: json['set'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'set': set,
    };
  }
}

class SealedProductOther {
  final String name;

  SealedProductOther({
    required this.name,
  });

  factory SealedProductOther.fromJson(Map<String, dynamic> json) {
    return SealedProductOther(
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }
}

class SealedProductPack {
  final String code;
  final String set;

  SealedProductPack({
    required this.code,
    required this.set,
  });

  factory SealedProductPack.fromJson(Map<String, dynamic> json) {
    return SealedProductPack(
      code: json['code'],
      set: json['set'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'set': set,
    };
  }
}

class SealedProductSealed {
  final int count;
  final String name;
  final String set;
  final String uuid;

  SealedProductSealed({
    required this.count,
    required this.name,
    required this.set,
    required this.uuid,
  });

  factory SealedProductSealed.fromJson(Map<String, dynamic> json) {
    return SealedProductSealed(
      count: json['count'],
      name: json['name'],
      set: json['set'],
      uuid: json['uuid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'name': name,
      'set': set,
      'uuid': uuid,
    };
  }
}

class SealedProductContents {
  final List<SealedProductCard>? card;
  final List<SealedProductDeck>? deck;
  final List<SealedProductOther>? other;
  final List<SealedProductPack>? pack;
  final List<SealedProductSealed>? sealed;
  final List<Map<String, List<SealedProductContents>>>? variable;

  SealedProductContents({
    this.card,
    this.deck,
    this.other,
    this.pack,
    this.sealed,
    this.variable,
  });

  factory SealedProductContents.fromJson(Map<String, dynamic> json) {
    return SealedProductContents(
      card: json['card'] != null 
          ? (json['card'] as List).map((e) => SealedProductCard.fromJson(e)).toList()
          : null,
      deck: json['deck'] != null 
          ? (json['deck'] as List).map((e) => SealedProductDeck.fromJson(e)).toList()
          : null,
      other: json['other'] != null 
          ? (json['other'] as List).map((e) => SealedProductOther.fromJson(e)).toList()
          : null,
      pack: json['pack'] != null 
          ? (json['pack'] as List).map((e) => SealedProductPack.fromJson(e)).toList()
          : null,
      sealed: json['sealed'] != null 
          ? (json['sealed'] as List).map((e) => SealedProductSealed.fromJson(e)).toList()
          : null,
      variable: json['variable'] != null 
          ? (json['variable'] as List).map((e) => {
              'configs': (e['configs'] as List).map((config) => SealedProductContents.fromJson(config)).toList()
            }).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (card != null) 'card': card?.map((e) => e.toJson()).toList(),
      if (deck != null) 'deck': deck?.map((e) => e.toJson()).toList(),
      if (other != null) 'other': other?.map((e) => e.toJson()).toList(),
      if (pack != null) 'pack': pack?.map((e) => e.toJson()).toList(),
      if (sealed != null) 'sealed': sealed?.map((e) => e.toJson()).toList(),
      if (variable != null) 'variable': variable?.map((e) => {
        'configs': e['configs']?.map((config) => config.toJson()).toList()
      }).toList(),
    };
  }
}