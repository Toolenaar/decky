import 'package:cloud_firestore/cloud_firestore.dart';
import '../base_model.dart';
import 'identifiers.dart';
import 'related_cards.dart';

class MtgToken extends BaseModel {
  final String? artist;
  final List<String>? artistIds;
  final String? asciiName;
  final List<String> availability;
  final List<String>? boosterTypes;
  final String borderColor;
  final List<String>? cardParts;
  final List<String> colorIdentity;
  final List<String>? colorIndicator;
  final List<String> colors;
  final double? edhrecSaltiness;
  final String? faceName;
  final String? faceFlavorName;
  final List<String> finishes;
  final String? flavorName;
  final String? flavorText;
  final List<String>? frameEffects;
  final String frameVersion;
  final bool hasFoil;
  final bool hasNonFoil;
  final Identifiers identifiers;
  final bool? isFullArt;
  final bool? isFunny;
  final bool? isOnlineOnly;
  final bool? isOversized;
  final bool? isPromo;
  final bool? isReprint;
  final bool? isTextless;
  final List<String>? keywords;
  final String language;
  final String layout;
  final String? loyalty;
  final String? manaCost;
  final String name;
  final String number;
  final String? orientation;
  final String? originalText;
  final String? originalType;
  final List<String>? otherFaceIds;
  final String? power;
  final List<String>? promoTypes;
  final RelatedCards? relatedCards;
  final List<String>? reverseRelated;
  final String? securityStamp;
  final String setCode;
  final String? side;
  final String? signature;
  final List<String>? sourceProducts;
  final List<String>? subsets;
  final List<String> subtypes;
  final List<String> supertypes;
  final String? text;
  final String? toughness;
  final String type;
  final List<String> types;
  final String? watermark;

  MtgToken({
    required super.id, // This will be the UUID
    this.artist,
    this.artistIds,
    this.asciiName,
    required this.availability,
    this.boosterTypes,
    required this.borderColor,
    this.cardParts,
    required this.colorIdentity,
    this.colorIndicator,
    required this.colors,
    this.edhrecSaltiness,
    this.faceName,
    this.faceFlavorName,
    required this.finishes,
    this.flavorName,
    this.flavorText,
    this.frameEffects,
    required this.frameVersion,
    required this.hasFoil,
    required this.hasNonFoil,
    required this.identifiers,
    this.isFullArt,
    this.isFunny,
    this.isOnlineOnly,
    this.isOversized,
    this.isPromo,
    this.isReprint,
    this.isTextless,
    this.keywords,
    required this.language,
    required this.layout,
    this.loyalty,
    this.manaCost,
    required this.name,
    required this.number,
    this.orientation,
    this.originalText,
    this.originalType,
    this.otherFaceIds,
    this.power,
    this.promoTypes,
    this.relatedCards,
    this.reverseRelated,
    this.securityStamp,
    required this.setCode,
    this.side,
    this.signature,
    this.sourceProducts,
    this.subsets,
    required this.subtypes,
    required this.supertypes,
    this.text,
    this.toughness,
    required this.type,
    required this.types,
    this.watermark,
  });

  @override
  DocumentReference<Map<String, dynamic>> get ref => 
      FirebaseFirestore.instance.collection('tokens').doc(id);

  @override
  Map<String, dynamic> toJson() {
    return {
      if (artist != null) 'artist': artist,
      if (artistIds != null) 'artistIds': artistIds,
      if (asciiName != null) 'asciiName': asciiName,
      'availability': availability,
      if (boosterTypes != null) 'boosterTypes': boosterTypes,
      'borderColor': borderColor,
      if (cardParts != null) 'cardParts': cardParts,
      'colorIdentity': colorIdentity,
      if (colorIndicator != null) 'colorIndicator': colorIndicator,
      'colors': colors,
      if (edhrecSaltiness != null) 'edhrecSaltiness': edhrecSaltiness,
      if (faceName != null) 'faceName': faceName,
      if (faceFlavorName != null) 'faceFlavorName': faceFlavorName,
      'finishes': finishes,
      if (flavorName != null) 'flavorName': flavorName,
      if (flavorText != null) 'flavorText': flavorText,
      if (frameEffects != null) 'frameEffects': frameEffects,
      'frameVersion': frameVersion,
      'hasFoil': hasFoil,
      'hasNonFoil': hasNonFoil,
      'identifiers': identifiers.toJson(),
      if (isFullArt != null) 'isFullArt': isFullArt,
      if (isFunny != null) 'isFunny': isFunny,
      if (isOnlineOnly != null) 'isOnlineOnly': isOnlineOnly,
      if (isOversized != null) 'isOversized': isOversized,
      if (isPromo != null) 'isPromo': isPromo,
      if (isReprint != null) 'isReprint': isReprint,
      if (isTextless != null) 'isTextless': isTextless,
      if (keywords != null) 'keywords': keywords,
      'language': language,
      'layout': layout,
      if (loyalty != null) 'loyalty': loyalty,
      if (manaCost != null) 'manaCost': manaCost,
      'name': name,
      'number': number,
      if (orientation != null) 'orientation': orientation,
      if (originalText != null) 'originalText': originalText,
      if (originalType != null) 'originalType': originalType,
      if (otherFaceIds != null) 'otherFaceIds': otherFaceIds,
      if (power != null) 'power': power,
      if (promoTypes != null) 'promoTypes': promoTypes,
      if (relatedCards != null) 'relatedCards': relatedCards?.toJson(),
      if (reverseRelated != null) 'reverseRelated': reverseRelated,
      if (securityStamp != null) 'securityStamp': securityStamp,
      'setCode': setCode,
      if (side != null) 'side': side,
      if (signature != null) 'signature': signature,
      if (sourceProducts != null) 'sourceProducts': sourceProducts,
      if (subsets != null) 'subsets': subsets,
      'subtypes': subtypes,
      'supertypes': supertypes,
      if (text != null) 'text': text,
      if (toughness != null) 'toughness': toughness,
      'type': type,
      'types': types,
      if (watermark != null) 'watermark': watermark,
    };
  }

  factory MtgToken.fromJson(Map<String, dynamic> json) {
    return MtgToken(
      id: json['uuid'], // Use UUID as ID for tokens
      artist: json['artist'],
      artistIds: json['artistIds'] != null ? List<String>.from(json['artistIds']) : null,
      asciiName: json['asciiName'],
      availability: List<String>.from(json['availability'] ?? []),
      boosterTypes: json['boosterTypes'] != null ? List<String>.from(json['boosterTypes']) : null,
      borderColor: json['borderColor'],
      cardParts: json['cardParts'] != null ? List<String>.from(json['cardParts']) : null,
      colorIdentity: List<String>.from(json['colorIdentity'] ?? []),
      colorIndicator: json['colorIndicator'] != null ? List<String>.from(json['colorIndicator']) : null,
      colors: List<String>.from(json['colors'] ?? []),
      edhrecSaltiness: json['edhrecSaltiness']?.toDouble(),
      faceName: json['faceName'],
      faceFlavorName: json['faceFlavorName'],
      finishes: List<String>.from(json['finishes'] ?? []),
      flavorName: json['flavorName'],
      flavorText: json['flavorText'],
      frameEffects: json['frameEffects'] != null ? List<String>.from(json['frameEffects']) : null,
      frameVersion: json['frameVersion'],
      hasFoil: json['hasFoil'] ?? false,
      hasNonFoil: json['hasNonFoil'] ?? false,
      identifiers: Identifiers.fromJson(json['identifiers']),
      isFullArt: json['isFullArt'],
      isFunny: json['isFunny'],
      isOnlineOnly: json['isOnlineOnly'],
      isOversized: json['isOversized'],
      isPromo: json['isPromo'],
      isReprint: json['isReprint'],
      isTextless: json['isTextless'],
      keywords: json['keywords'] != null ? List<String>.from(json['keywords']) : null,
      language: json['language'],
      layout: json['layout'],
      loyalty: json['loyalty'],
      manaCost: json['manaCost'],
      name: json['name'],
      number: json['number'],
      orientation: json['orientation'],
      originalText: json['originalText'],
      originalType: json['originalType'],
      otherFaceIds: json['otherFaceIds'] != null ? List<String>.from(json['otherFaceIds']) : null,
      power: json['power'],
      promoTypes: json['promoTypes'] != null ? List<String>.from(json['promoTypes']) : null,
      relatedCards: json['relatedCards'] != null 
          ? RelatedCards.fromJson(json['relatedCards'])
          : null,
      reverseRelated: json['reverseRelated'] != null ? List<String>.from(json['reverseRelated']) : null,
      securityStamp: json['securityStamp'],
      setCode: json['setCode'],
      side: json['side'],
      signature: json['signature'],
      sourceProducts: json['sourceProducts'] != null ? List<String>.from(json['sourceProducts']) : null,
      subsets: json['subsets'] != null ? List<String>.from(json['subsets']) : null,
      subtypes: List<String>.from(json['subtypes'] ?? []),
      supertypes: List<String>.from(json['supertypes'] ?? []),
      text: json['text'],
      toughness: json['toughness'],
      type: json['type'],
      types: List<String>.from(json['types'] ?? []),
      watermark: json['watermark'],
    );
  }
}