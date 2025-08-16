import 'package:cloud_firestore/cloud_firestore.dart';
import '../base_model.dart';
import 'identifiers.dart';
import 'legalities.dart';
import 'foreign_data.dart';
import 'purchase_urls.dart';
import 'related_cards.dart';
import 'rulings.dart';
import 'leadership_skills.dart';
import 'source_products.dart';

class MtgCard extends BaseModel {
  final String? artist;
  final List<String>? artistIds;
  final String? asciiName;
  final List<int>? attractionLights;
  final List<String> availability;
  final List<String>? boosterTypes;
  final String borderColor;
  final List<String>? cardParts;
  final List<String> colorIdentity;
  final List<String>? colorIndicator;
  final List<String> colors;
  final double convertedManaCost;
  final String? defense;
  final String? duelDeck;
  final int? edhrecRank;
  final double? edhrecSaltiness;
  final double? faceConvertedManaCost;
  final String? faceFlavorName;
  final double? faceManaValue;
  final String? faceName;
  final List<String> finishes;
  final String? flavorName;
  final String? flavorText;
  final List<ForeignData>? foreignData;
  final List<String>? frameEffects;
  final String frameVersion;
  final String? hand;
  final bool? hasAlternativeDeckLimit;
  final bool? hasContentWarning;
  final bool hasFoil;
  final bool hasNonFoil;
  final Identifiers identifiers;
  final bool? isAlternative;
  final bool? isFullArt;
  final bool? isFunny;
  final bool? isGameChanger;
  final bool? isOnlineOnly;
  final bool? isOversized;
  final bool? isPromo;
  final bool? isRebalanced;
  final bool? isReprint;
  final bool? isReserved;
  final bool? isStarter;
  final bool? isStorySpotlight;
  final bool? isTextless;
  final bool? isTimeshifted;
  final List<String>? keywords;
  final String language;
  final String layout;
  final LeadershipSkills? leadershipSkills;
  final Legalities legalities;
  final String? life;
  final String? loyalty;
  final String? manaCost;
  final double manaValue;
  final String name;
  final String number;
  final List<String>? originalPrintings;
  final String? originalReleaseDate;
  final String? originalText;
  final String? originalType;
  final List<String>? otherFaceIds;
  final String? power;
  final List<String>? printings;
  final List<String>? promoTypes;
  final PurchaseUrls purchaseUrls;
  final String rarity;
  final RelatedCards? relatedCards;
  final List<String>? rebalancedPrintings;
  final List<Rulings>? rulings;
  final String? securityStamp;
  final String setCode;
  final String? side;
  final String? signature;
  final SourceProducts? sourceProducts;
  final List<String>? subsets;
  final List<String> subtypes;
  final List<String> supertypes;
  final String? text;
  final String? toughness;
  final String type;
  final List<String> types;
  final List<String>? variations;
  final String? watermark;

  MtgCard({
    required super.id, // This will be the UUID
    this.artist,
    this.artistIds,
    this.asciiName,
    this.attractionLights,
    required this.availability,
    this.boosterTypes,
    required this.borderColor,
    this.cardParts,
    required this.colorIdentity,
    this.colorIndicator,
    required this.colors,
    required this.convertedManaCost,
    this.defense,
    this.duelDeck,
    this.edhrecRank,
    this.edhrecSaltiness,
    this.faceConvertedManaCost,
    this.faceFlavorName,
    this.faceManaValue,
    this.faceName,
    required this.finishes,
    this.flavorName,
    this.flavorText,
    this.foreignData,
    this.frameEffects,
    required this.frameVersion,
    this.hand,
    this.hasAlternativeDeckLimit,
    this.hasContentWarning,
    required this.hasFoil,
    required this.hasNonFoil,
    required this.identifiers,
    this.isAlternative,
    this.isFullArt,
    this.isFunny,
    this.isGameChanger,
    this.isOnlineOnly,
    this.isOversized,
    this.isPromo,
    this.isRebalanced,
    this.isReprint,
    this.isReserved,
    this.isStarter,
    this.isStorySpotlight,
    this.isTextless,
    this.isTimeshifted,
    this.keywords,
    required this.language,
    required this.layout,
    this.leadershipSkills,
    required this.legalities,
    this.life,
    this.loyalty,
    this.manaCost,
    required this.manaValue,
    required this.name,
    required this.number,
    this.originalPrintings,
    this.originalReleaseDate,
    this.originalText,
    this.originalType,
    this.otherFaceIds,
    this.power,
    this.printings,
    this.promoTypes,
    required this.purchaseUrls,
    required this.rarity,
    this.relatedCards,
    this.rebalancedPrintings,
    this.rulings,
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
    this.variations,
    this.watermark,
  });

  @override
  DocumentReference<Map<String, dynamic>> get ref => 
      FirebaseFirestore.instance.collection('cards').doc(id);

  @override
  Map<String, dynamic> toJson() {
    return {
      if (artist != null) 'artist': artist,
      if (artistIds != null) 'artistIds': artistIds,
      if (asciiName != null) 'asciiName': asciiName,
      if (attractionLights != null) 'attractionLights': attractionLights,
      'availability': availability,
      if (boosterTypes != null) 'boosterTypes': boosterTypes,
      'borderColor': borderColor,
      if (cardParts != null) 'cardParts': cardParts,
      'colorIdentity': colorIdentity,
      if (colorIndicator != null) 'colorIndicator': colorIndicator,
      'colors': colors,
      'convertedManaCost': convertedManaCost,
      if (defense != null) 'defense': defense,
      if (duelDeck != null) 'duelDeck': duelDeck,
      if (edhrecRank != null) 'edhrecRank': edhrecRank,
      if (edhrecSaltiness != null) 'edhrecSaltiness': edhrecSaltiness,
      if (faceConvertedManaCost != null) 'faceConvertedManaCost': faceConvertedManaCost,
      if (faceFlavorName != null) 'faceFlavorName': faceFlavorName,
      if (faceManaValue != null) 'faceManaValue': faceManaValue,
      if (faceName != null) 'faceName': faceName,
      'finishes': finishes,
      if (flavorName != null) 'flavorName': flavorName,
      if (flavorText != null) 'flavorText': flavorText,
      if (foreignData != null) 'foreignData': foreignData?.map((e) => e.toJson()).toList(),
      if (frameEffects != null) 'frameEffects': frameEffects,
      'frameVersion': frameVersion,
      if (hand != null) 'hand': hand,
      if (hasAlternativeDeckLimit != null) 'hasAlternativeDeckLimit': hasAlternativeDeckLimit,
      if (hasContentWarning != null) 'hasContentWarning': hasContentWarning,
      'hasFoil': hasFoil,
      'hasNonFoil': hasNonFoil,
      'identifiers': identifiers.toJson(),
      if (isAlternative != null) 'isAlternative': isAlternative,
      if (isFullArt != null) 'isFullArt': isFullArt,
      if (isFunny != null) 'isFunny': isFunny,
      if (isGameChanger != null) 'isGameChanger': isGameChanger,
      if (isOnlineOnly != null) 'isOnlineOnly': isOnlineOnly,
      if (isOversized != null) 'isOversized': isOversized,
      if (isPromo != null) 'isPromo': isPromo,
      if (isRebalanced != null) 'isRebalanced': isRebalanced,
      if (isReprint != null) 'isReprint': isReprint,
      if (isReserved != null) 'isReserved': isReserved,
      if (isStarter != null) 'isStarter': isStarter,
      if (isStorySpotlight != null) 'isStorySpotlight': isStorySpotlight,
      if (isTextless != null) 'isTextless': isTextless,
      if (isTimeshifted != null) 'isTimeshifted': isTimeshifted,
      if (keywords != null) 'keywords': keywords,
      'language': language,
      'layout': layout,
      if (leadershipSkills != null) 'leadershipSkills': leadershipSkills?.toJson(),
      'legalities': legalities.toJson(),
      if (life != null) 'life': life,
      if (loyalty != null) 'loyalty': loyalty,
      if (manaCost != null) 'manaCost': manaCost,
      'manaValue': manaValue,
      'name': name,
      'number': number,
      if (originalPrintings != null) 'originalPrintings': originalPrintings,
      if (originalReleaseDate != null) 'originalReleaseDate': originalReleaseDate,
      if (originalText != null) 'originalText': originalText,
      if (originalType != null) 'originalType': originalType,
      if (otherFaceIds != null) 'otherFaceIds': otherFaceIds,
      if (power != null) 'power': power,
      if (printings != null) 'printings': printings,
      if (promoTypes != null) 'promoTypes': promoTypes,
      'purchaseUrls': purchaseUrls.toJson(),
      'rarity': rarity,
      if (relatedCards != null) 'relatedCards': relatedCards?.toJson(),
      if (rebalancedPrintings != null) 'rebalancedPrintings': rebalancedPrintings,
      if (rulings != null) 'rulings': rulings?.map((e) => e.toJson()).toList(),
      if (securityStamp != null) 'securityStamp': securityStamp,
      'setCode': setCode,
      if (side != null) 'side': side,
      if (signature != null) 'signature': signature,
      if (sourceProducts != null) 'sourceProducts': sourceProducts?.toJson(),
      if (subsets != null) 'subsets': subsets,
      'subtypes': subtypes,
      'supertypes': supertypes,
      if (text != null) 'text': text,
      if (toughness != null) 'toughness': toughness,
      'type': type,
      'types': types,
      if (variations != null) 'variations': variations,
      if (watermark != null) 'watermark': watermark,
    };
  }

  factory MtgCard.fromJson(Map<String, dynamic> json) {
    return MtgCard(
      id: json['uuid'], // Use UUID as ID for cards
      artist: json['artist'],
      artistIds: json['artistIds'] != null ? List<String>.from(json['artistIds']) : null,
      asciiName: json['asciiName'],
      attractionLights: json['attractionLights'] != null ? List<int>.from(json['attractionLights']) : null,
      availability: List<String>.from(json['availability'] ?? []),
      boosterTypes: json['boosterTypes'] != null ? List<String>.from(json['boosterTypes']) : null,
      borderColor: json['borderColor'],
      cardParts: json['cardParts'] != null ? List<String>.from(json['cardParts']) : null,
      colorIdentity: List<String>.from(json['colorIdentity'] ?? []),
      colorIndicator: json['colorIndicator'] != null ? List<String>.from(json['colorIndicator']) : null,
      colors: List<String>.from(json['colors'] ?? []),
      convertedManaCost: (json['convertedManaCost'] ?? 0).toDouble(),
      defense: json['defense'],
      duelDeck: json['duelDeck'],
      edhrecRank: json['edhrecRank'],
      edhrecSaltiness: json['edhrecSaltiness']?.toDouble(),
      faceConvertedManaCost: json['faceConvertedManaCost']?.toDouble(),
      faceFlavorName: json['faceFlavorName'],
      faceManaValue: json['faceManaValue']?.toDouble(),
      faceName: json['faceName'],
      finishes: List<String>.from(json['finishes'] ?? []),
      flavorName: json['flavorName'],
      flavorText: json['flavorText'],
      foreignData: json['foreignData'] != null 
          ? (json['foreignData'] as List).map((e) => ForeignData.fromJson(e)).toList()
          : null,
      frameEffects: json['frameEffects'] != null ? List<String>.from(json['frameEffects']) : null,
      frameVersion: json['frameVersion'],
      hand: json['hand'],
      hasAlternativeDeckLimit: json['hasAlternativeDeckLimit'],
      hasContentWarning: json['hasContentWarning'],
      hasFoil: json['hasFoil'] ?? false,
      hasNonFoil: json['hasNonFoil'] ?? false,
      identifiers: Identifiers.fromJson(json['identifiers']),
      isAlternative: json['isAlternative'],
      isFullArt: json['isFullArt'],
      isFunny: json['isFunny'],
      isGameChanger: json['isGameChanger'],
      isOnlineOnly: json['isOnlineOnly'],
      isOversized: json['isOversized'],
      isPromo: json['isPromo'],
      isRebalanced: json['isRebalanced'],
      isReprint: json['isReprint'],
      isReserved: json['isReserved'],
      isStarter: json['isStarter'],
      isStorySpotlight: json['isStorySpotlight'],
      isTextless: json['isTextless'],
      isTimeshifted: json['isTimeshifted'],
      keywords: json['keywords'] != null ? List<String>.from(json['keywords']) : null,
      language: json['language'],
      layout: json['layout'],
      leadershipSkills: json['leadershipSkills'] != null 
          ? LeadershipSkills.fromJson(json['leadershipSkills'])
          : null,
      legalities: Legalities.fromJson(json['legalities']),
      life: json['life'],
      loyalty: json['loyalty'],
      manaCost: json['manaCost'],
      manaValue: (json['manaValue'] ?? 0).toDouble(),
      name: json['name'],
      number: json['number'],
      originalPrintings: json['originalPrintings'] != null ? List<String>.from(json['originalPrintings']) : null,
      originalReleaseDate: json['originalReleaseDate'],
      originalText: json['originalText'],
      originalType: json['originalType'],
      otherFaceIds: json['otherFaceIds'] != null ? List<String>.from(json['otherFaceIds']) : null,
      power: json['power'],
      printings: json['printings'] != null ? List<String>.from(json['printings']) : null,
      promoTypes: json['promoTypes'] != null ? List<String>.from(json['promoTypes']) : null,
      purchaseUrls: PurchaseUrls.fromJson(json['purchaseUrls'] ?? {}),
      rarity: json['rarity'],
      relatedCards: json['relatedCards'] != null 
          ? RelatedCards.fromJson(json['relatedCards'])
          : null,
      rebalancedPrintings: json['rebalancedPrintings'] != null ? List<String>.from(json['rebalancedPrintings']) : null,
      rulings: json['rulings'] != null 
          ? (json['rulings'] as List).map((e) => Rulings.fromJson(e)).toList()
          : null,
      securityStamp: json['securityStamp'],
      setCode: json['setCode'],
      side: json['side'],
      signature: json['signature'],
      sourceProducts: json['sourceProducts'] != null 
          ? SourceProducts.fromJson(json['sourceProducts'])
          : null,
      subsets: json['subsets'] != null ? List<String>.from(json['subsets']) : null,
      subtypes: List<String>.from(json['subtypes'] ?? []),
      supertypes: List<String>.from(json['supertypes'] ?? []),
      text: json['text'],
      toughness: json['toughness'],
      type: json['type'],
      types: List<String>.from(json['types'] ?? []),
      variations: json['variations'] != null ? List<String>.from(json['variations']) : null,
      watermark: json['watermark'],
    );
  }
}