class CardSetDeck {
  final int count;
  final bool? isFoil;
  final String uuid;

  CardSetDeck({
    required this.count,
    this.isFoil,
    required this.uuid,
  });

  factory CardSetDeck.fromJson(Map<String, dynamic> json) {
    return CardSetDeck(
      count: json['count'],
      isFoil: json['isFoil'],
      uuid: json['uuid'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      if (isFoil != null) 'isFoil': isFoil,
      'uuid': uuid,
    };
  }
}