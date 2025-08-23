import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decky_core/decky_core.dart';

class CollectionCard extends BaseModel {
  final String cardUuid;
  final int count;
  final String accountId;
  final String collectionId;
  final MtgCard mtgCardReference;
  final bool? isFoil;
  final String? notes;
  final String? acquiredFrom;
  final Timestamp? acquiredAt;
  final double? acquiredPrice;
  final List<String>? tags;

  CollectionCard({
    required super.id,
    required this.cardUuid,
    this.count = 1,
    required this.accountId,
    required this.collectionId,
    required this.mtgCardReference,
    this.isFoil,
    this.notes,
    this.acquiredFrom,
    this.acquiredAt,
    this.acquiredPrice,
    this.tags,
  });

  factory CollectionCard.fromJson(Map<String, dynamic> json, String id) {
    // Handle the case where mtgCardReference might be null or missing
    MtgCard mtgCardReference = MtgCard.fromJson(json['mtgCardReference'], json['mtgCardReference']['id']);

    return CollectionCard(
      id: id,
      cardUuid: json['cardUuid'],
      count: json['count'] ?? 1,
      accountId: json['accountId'],
      collectionId: json['collectionId'],
      mtgCardReference: mtgCardReference,
      isFoil: json['isFoil'],
      notes: json['notes'],
      acquiredFrom: json['acquiredFrom'],
      acquiredAt: json['acquiredAt'],
      acquiredPrice: json['acquiredPrice']?.toDouble(),
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'cardUuid': cardUuid,
      'count': count,
      'accountId': accountId,
      'collectionId': collectionId,
      'mtgCardReference': mtgCardReference.toJson(),
      if (isFoil != null) 'isFoil': isFoil,
      if (notes != null) 'notes': notes,
      if (acquiredFrom != null) 'acquiredFrom': acquiredFrom,
      if (acquiredAt != null) 'acquiredAt': acquiredAt,
      if (acquiredPrice != null) 'acquiredPrice': acquiredPrice,
      if (tags != null) 'tags': tags,
    };
  }

  CollectionCard copyWith({
    String? cardUuid,
    int? count,
    bool? isFoil,
    String? notes,
    String? acquiredFrom,
    Timestamp? acquiredAt,
    double? acquiredPrice,
    List<String>? tags,
    String? accountId,
    MtgCard? mtgCardReference,
    String? collectionId,
  }) {
    return CollectionCard(
      id: id,
      cardUuid: cardUuid ?? this.cardUuid,
      count: count ?? this.count,
      accountId: accountId ?? this.accountId,
      collectionId: collectionId ?? this.collectionId,
      mtgCardReference: mtgCardReference ?? this.mtgCardReference,
      isFoil: isFoil ?? this.isFoil,
      notes: notes ?? this.notes,
      acquiredFrom: acquiredFrom ?? this.acquiredFrom,
      acquiredAt: acquiredAt ?? this.acquiredAt,
      acquiredPrice: acquiredPrice ?? this.acquiredPrice,
      tags: tags ?? this.tags,
    );
  }

  @override
  DocumentReference<Map<String, dynamic>> get ref => FirebaseFirestore.instance
      .collection('accounts')
      .doc(accountId)
      .collection('collections')
      .doc(collectionId)
      .collection('cards')
      .doc(id);
}
