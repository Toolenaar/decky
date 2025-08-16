class RelatedCards {
  final List<String>? reverseRelated;
  final List<String>? spellbook;

  RelatedCards({
    this.reverseRelated,
    this.spellbook,
  });

  factory RelatedCards.fromJson(Map<String, dynamic> json) {
    return RelatedCards(
      reverseRelated: json['reverseRelated'] != null 
          ? List<String>.from(json['reverseRelated'])
          : null,
      spellbook: json['spellbook'] != null 
          ? List<String>.from(json['spellbook'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (reverseRelated != null) 'reverseRelated': reverseRelated,
      if (spellbook != null) 'spellbook': spellbook,
    };
  }
}