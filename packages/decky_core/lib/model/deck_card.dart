import 'package:cloud_firestore/cloud_firestore.dart';

class DeckCard {
  final String cardUuid;
  final int count;
  final bool isFoil;
  final String? notes;
  final String? acquiredFrom;
  final Timestamp? acquiredAt;
  final double? acquiredPrice;
  final List<String>? tags;
  final bool isCommander;
  final bool isInSideboard;

  DeckCard({
    required this.cardUuid,
    required this.count,
    this.isFoil = false,
    this.notes,
    this.acquiredFrom,
    this.acquiredAt,
    this.acquiredPrice,
    this.tags,
    this.isCommander = false,
    this.isInSideboard = false,
  });

  factory DeckCard.fromJson(Map<String, dynamic> json) {
    return DeckCard(
      cardUuid: json['cardUuid'],
      count: json['count'],
      isFoil: json['isFoil'] ?? false,
      notes: json['notes'],
      acquiredFrom: json['acquiredFrom'],
      acquiredAt: json['acquiredAt'],
      acquiredPrice: json['acquiredPrice']?.toDouble(),
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      isCommander: json['isCommander'] ?? false,
      isInSideboard: json['isInSideboard'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cardUuid': cardUuid,
      'count': count,
      'isFoil': isFoil,
      if (notes != null) 'notes': notes,
      if (acquiredFrom != null) 'acquiredFrom': acquiredFrom,
      if (acquiredAt != null) 'acquiredAt': acquiredAt,
      if (acquiredPrice != null) 'acquiredPrice': acquiredPrice,
      if (tags != null) 'tags': tags,
      'isCommander': isCommander,
      'isInSideboard': isInSideboard,
    };
  }

  DeckCard copyWith({
    String? cardUuid,
    int? count,
    bool? isFoil,
    String? notes,
    String? acquiredFrom,
    Timestamp? acquiredAt,
    double? acquiredPrice,
    List<String>? tags,
    bool? isCommander,
    bool? isInSideboard,
  }) {
    return DeckCard(
      cardUuid: cardUuid ?? this.cardUuid,
      count: count ?? this.count,
      isFoil: isFoil ?? this.isFoil,
      notes: notes ?? this.notes,
      acquiredFrom: acquiredFrom ?? this.acquiredFrom,
      acquiredAt: acquiredAt ?? this.acquiredAt,
      acquiredPrice: acquiredPrice ?? this.acquiredPrice,
      tags: tags ?? this.tags,
      isCommander: isCommander ?? this.isCommander,
      isInSideboard: isInSideboard ?? this.isInSideboard,
    );
  }
}