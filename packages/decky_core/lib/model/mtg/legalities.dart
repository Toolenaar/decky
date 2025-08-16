class Legalities {
  final String? alchemy;
  final String? brawl;
  final String? commander;
  final String? duel;
  final String? explorer;
  final String? future;
  final String? gladiator;
  final String? historic;
  final String? historicbrawl;
  final String? legacy;
  final String? modern;
  final String? oathbreaker;
  final String? oldschool;
  final String? pauper;
  final String? paupercommander;
  final String? penny;
  final String? pioneer;
  final String? predh;
  final String? premodern;
  final String? standard;
  final String? standardbrawl;
  final String? timeless;
  final String? vintage;

  Legalities({
    this.alchemy,
    this.brawl,
    this.commander,
    this.duel,
    this.explorer,
    this.future,
    this.gladiator,
    this.historic,
    this.historicbrawl,
    this.legacy,
    this.modern,
    this.oathbreaker,
    this.oldschool,
    this.pauper,
    this.paupercommander,
    this.penny,
    this.pioneer,
    this.predh,
    this.premodern,
    this.standard,
    this.standardbrawl,
    this.timeless,
    this.vintage,
  });

  factory Legalities.fromJson(Map<String, dynamic> json) {
    return Legalities(
      alchemy: json['alchemy'],
      brawl: json['brawl'],
      commander: json['commander'],
      duel: json['duel'],
      explorer: json['explorer'],
      future: json['future'],
      gladiator: json['gladiator'],
      historic: json['historic'],
      historicbrawl: json['historicbrawl'],
      legacy: json['legacy'],
      modern: json['modern'],
      oathbreaker: json['oathbreaker'],
      oldschool: json['oldschool'],
      pauper: json['pauper'],
      paupercommander: json['paupercommander'],
      penny: json['penny'],
      pioneer: json['pioneer'],
      predh: json['predh'],
      premodern: json['premodern'],
      standard: json['standard'],
      standardbrawl: json['standardbrawl'],
      timeless: json['timeless'],
      vintage: json['vintage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (alchemy != null) 'alchemy': alchemy,
      if (brawl != null) 'brawl': brawl,
      if (commander != null) 'commander': commander,
      if (duel != null) 'duel': duel,
      if (explorer != null) 'explorer': explorer,
      if (future != null) 'future': future,
      if (gladiator != null) 'gladiator': gladiator,
      if (historic != null) 'historic': historic,
      if (historicbrawl != null) 'historicbrawl': historicbrawl,
      if (legacy != null) 'legacy': legacy,
      if (modern != null) 'modern': modern,
      if (oathbreaker != null) 'oathbreaker': oathbreaker,
      if (oldschool != null) 'oldschool': oldschool,
      if (pauper != null) 'pauper': pauper,
      if (paupercommander != null) 'paupercommander': paupercommander,
      if (penny != null) 'penny': penny,
      if (pioneer != null) 'pioneer': pioneer,
      if (predh != null) 'predh': predh,
      if (premodern != null) 'premodern': premodern,
      if (standard != null) 'standard': standard,
      if (standardbrawl != null) 'standardbrawl': standardbrawl,
      if (timeless != null) 'timeless': timeless,
      if (vintage != null) 'vintage': vintage,
    };
  }
}