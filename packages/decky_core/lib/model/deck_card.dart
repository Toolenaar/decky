import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decky_core/decky_core.dart';
import 'base_model.dart';

class DeckCard extends BaseModel {
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
  final String accountId;
  final String deckId;
  final MtgCard mtgCardReference;

  DeckCard({
    required super.id,
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
    required this.accountId,
    required this.deckId,
    required this.mtgCardReference,
  });

  factory DeckCard.fromJson(Map<String, dynamic> json, String id) {
    // Handle the case where mtgCardReference might be null or missing
    MtgCard mtgCardReference = MtgCard.fromJson(json['mtgCardReference'], json['mtgCardReference']['id']);

    return DeckCard(
      id: id,
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
      accountId: json['accountId'],
      deckId: json['deckId'],
      mtgCardReference: mtgCardReference,
    );
  }

  @override
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
      'accountId': accountId,
      'deckId': deckId,
      'mtgCardReference': mtgCardReference.toJson(),
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
    String? accountId,
    String? deckId,
    MtgCard? mtgCardReference,
  }) {
    return DeckCard(
      id: id,
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
      accountId: accountId ?? this.accountId,
      deckId: deckId ?? this.deckId,
      mtgCardReference: mtgCardReference ?? this.mtgCardReference,
    );
  }

  @override
  DocumentReference<Map<String, dynamic>> get ref => FirebaseFirestore.instance
      .collection('accounts')
      .doc(accountId)
      .collection('decks')
      .doc(deckId)
      .collection('cards')
      .doc(id);
}
