import 'package:cloud_firestore/cloud_firestore.dart';
import '../base_model.dart';

class MtgSet extends BaseModel {
  final int baseSetSize;
  final String? block;
  final int? cardsphereSetId;
  final String code;
  final String? codeV3;
  final bool? isForeignOnly;
  final bool isFoilOnly;
  final bool? isNonFoilOnly;
  final bool isOnlineOnly;
  final bool? isPaperOnly;
  final bool? isPartialPreview;
  final String keyruneCode;
  final List<String>? languages;
  final int? mcmId;
  final int? mcmIdExtras;
  final String? mcmName;
  final String? mtgoCode;
  final String name;
  final String? parentCode;
  final String releaseDate;
  final int? tcgplayerGroupId;
  final String? tokenSetCode;
  final int totalSetSize;
  final String type;
  final Map<String, String> translations;
  final int cardCount;
  final int tokenCount;
  final int deckCount;
  final int sealedProductCount;

  MtgSet({
    required super.id,
    required this.baseSetSize,
    this.block,
    this.cardsphereSetId,
    required this.code,
    this.codeV3,
    this.isForeignOnly,
    required this.isFoilOnly,
    this.isNonFoilOnly,
    required this.isOnlineOnly,
    this.isPaperOnly,
    this.isPartialPreview,
    required this.keyruneCode,
    this.languages,
    this.mcmId,
    this.mcmIdExtras,
    this.mcmName,
    this.mtgoCode,
    required this.name,
    this.parentCode,
    required this.releaseDate,
    this.tcgplayerGroupId,
    this.tokenSetCode,
    required this.totalSetSize,
    required this.type,
    required this.translations,
    required this.cardCount,
    required this.tokenCount,
    required this.deckCount,
    required this.sealedProductCount,
  });

  @override
  DocumentReference<Map<String, dynamic>> get ref => 
      FirebaseFirestore.instance.collection('sets').doc(id);

  @override
  Map<String, dynamic> toJson() {
    return {
      'baseSetSize': baseSetSize,
      if (block != null) 'block': block,
      if (cardsphereSetId != null) 'cardsphereSetId': cardsphereSetId,
      'code': code,
      if (codeV3 != null) 'codeV3': codeV3,
      if (isForeignOnly != null) 'isForeignOnly': isForeignOnly,
      'isFoilOnly': isFoilOnly,
      if (isNonFoilOnly != null) 'isNonFoilOnly': isNonFoilOnly,
      'isOnlineOnly': isOnlineOnly,
      if (isPaperOnly != null) 'isPaperOnly': isPaperOnly,
      if (isPartialPreview != null) 'isPartialPreview': isPartialPreview,
      'keyruneCode': keyruneCode,
      if (languages != null) 'languages': languages,
      if (mcmId != null) 'mcmId': mcmId,
      if (mcmIdExtras != null) 'mcmIdExtras': mcmIdExtras,
      if (mcmName != null) 'mcmName': mcmName,
      if (mtgoCode != null) 'mtgoCode': mtgoCode,
      'name': name,
      if (parentCode != null) 'parentCode': parentCode,
      'releaseDate': releaseDate,
      if (tcgplayerGroupId != null) 'tcgplayerGroupId': tcgplayerGroupId,
      if (tokenSetCode != null) 'tokenSetCode': tokenSetCode,
      'totalSetSize': totalSetSize,
      'type': type,
      'translations': translations,
      'cardCount': cardCount,
      'tokenCount': tokenCount,
      'deckCount': deckCount,
      'sealedProductCount': sealedProductCount,
    };
  }

  factory MtgSet.fromJson(Map<String, dynamic> json) {
    return MtgSet(
      id: json['code'], // Use code as ID for sets
      baseSetSize: json['baseSetSize'],
      block: json['block'],
      cardsphereSetId: json['cardsphereSetId'],
      code: json['code'],
      codeV3: json['codeV3'],
      isForeignOnly: json['isForeignOnly'],
      isFoilOnly: json['isFoilOnly'] ?? false,
      isNonFoilOnly: json['isNonFoilOnly'],
      isOnlineOnly: json['isOnlineOnly'] ?? false,
      isPaperOnly: json['isPaperOnly'],
      isPartialPreview: json['isPartialPreview'],
      keyruneCode: json['keyruneCode'],
      languages: json['languages'] != null 
          ? List<String>.from(json['languages'])
          : null,
      mcmId: json['mcmId'],
      mcmIdExtras: json['mcmIdExtras'],
      mcmName: json['mcmName'],
      mtgoCode: json['mtgoCode'],
      name: json['name'],
      parentCode: json['parentCode'],
      releaseDate: json['releaseDate'],
      tcgplayerGroupId: json['tcgplayerGroupId'],
      tokenSetCode: json['tokenSetCode'],
      totalSetSize: json['totalSetSize'],
      type: json['type'],
      translations: Map<String, String>.from(json['translations'] ?? {}),
      cardCount: json['cardCount'] ?? 0,
      tokenCount: json['tokenCount'] ?? 0,
      deckCount: json['deckCount'] ?? 0,
      sealedProductCount: json['sealedProductCount'] ?? 0,
    );
  }
}