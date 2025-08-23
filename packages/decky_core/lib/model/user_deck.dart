import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_model.dart';
import 'deck_card.dart';
import 'deck_metadata.dart';

enum MtgFormat {
  standard,
  pioneer,
  modern,
  legacy,
  vintage,
  commander,
  commanderOnehundred,
  pauper,
  pauperCommander,
  historic,
  alchemy,
  explorer,
  brawl,
  standardBrawl,
  limited,
  cube,
  custom,
}

class UserDeck extends BaseModel {
  final String accountId;
  final String name;
  final MtgFormat format;
  final DeckMetadata metadata;
  final String? parentDeckId;
  final bool isTemplate;
  final Map<String, dynamic>? aiSuggestions;
  final double? estimatedValue;
  final String? notes;
  final String? coverImageUrl;

  UserDeck({
    required super.id,
    required this.accountId,
    required this.name,
    required this.format,
    required this.metadata,
    this.parentDeckId,
    this.isTemplate = false,
    this.aiSuggestions,
    this.estimatedValue,
    this.notes,
    this.coverImageUrl,
  });

  @override
  DocumentReference<Map<String, dynamic>> get ref =>
      FirebaseFirestore.instance.collection('accounts').doc(accountId).collection('decks').doc(id);

  DocumentReference<Map<String, dynamic>> get deckCardsRef => FirebaseFirestore.instance.collection('decks').doc(id);

  // List<DeckCard> get commanders => cards.where((card) => card.isCommander).toList();

  // List<DeckCard> get mainboard => cards.where((card) => !card.isCommander && !card.isInSideboard).toList();

  // List<DeckCard> get sideboard => cards.where((card) => card.isInSideboard).toList();

  // int get totalCards => cards.fold(0, (total, card) => total + (card.isInSideboard ? 0 : card.count));

  // int get sideboardCount => cards.fold(0, (total, card) => total + (card.isInSideboard ? card.count : 0));

  bool get isCommanderFormat =>
      format == MtgFormat.commander ||
      format == MtgFormat.commanderOnehundred ||
      format == MtgFormat.pauperCommander ||
      format == MtgFormat.brawl ||
      format == MtgFormat.standardBrawl;

  // bool get isValidForFormat {
  //   switch (format) {
  //     case MtgFormat.commander:
  //     case MtgFormat.pauperCommander:
  //     case MtgFormat.brawl:
  //     case MtgFormat.standardBrawl:
  //       return commanders.isNotEmpty && commanders.length <= 2 && totalCards == 100;
  //     case MtgFormat.commanderOnehundred:
  //       return commanders.length == 1 && totalCards == 100;
  //     case MtgFormat.standard:
  //     case MtgFormat.pioneer:
  //     case MtgFormat.modern:
  //     case MtgFormat.legacy:
  //     case MtgFormat.vintage:
  //     case MtgFormat.historic:
  //     case MtgFormat.alchemy:
  //     case MtgFormat.explorer:
  //       return totalCards >= 60 && sideboardCount <= 15;
  //     case MtgFormat.pauper:
  //       return totalCards >= 60 && sideboardCount <= 15;
  //     case MtgFormat.limited:
  //       return totalCards >= 40;
  //     case MtgFormat.cube:
  //     case MtgFormat.custom:
  //       return true;
  //   }
  // }

  @override
  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'name': name,
      'format': format.toString().split('.').last,
      'metadata': metadata.toJson(),
      if (parentDeckId != null) 'parentDeckId': parentDeckId,
      'isTemplate': isTemplate,
      if (aiSuggestions != null) 'aiSuggestions': aiSuggestions,
      if (estimatedValue != null) 'estimatedValue': estimatedValue,
      if (notes != null) 'notes': notes,
      if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
    };
  }

  factory UserDeck.fromJson(String id, Map<String, dynamic> json) {
    return UserDeck(
      id: id,
      accountId: json['accountId'],
      name: json['name'],
      format: MtgFormat.values.firstWhere(
        (e) => e.toString().split('.').last == json['format'],
        orElse: () => MtgFormat.custom,
      ),
      metadata: DeckMetadata.fromJson(json['metadata'] ?? {}),
      parentDeckId: json['parentDeckId'],
      isTemplate: json['isTemplate'] ?? false,
      aiSuggestions: json['aiSuggestions'] != null ? Map<String, dynamic>.from(json['aiSuggestions']) : null,
      estimatedValue: json['estimatedValue']?.toDouble(),
      notes: json['notes'],
      coverImageUrl: json['coverImageUrl'],
    );
  }

  UserDeck copyWith({
    String? name,
    MtgFormat? format,
    List<DeckCard>? cards,
    DeckMetadata? metadata,
    String? parentDeckId,
    bool? isTemplate,
    Map<String, dynamic>? aiSuggestions,
    double? estimatedValue,
    String? notes,
    String? coverImageUrl,
  }) {
    return UserDeck(
      id: id,
      accountId: accountId,
      name: name ?? this.name,
      format: format ?? this.format,

      metadata: metadata ?? this.metadata,
      parentDeckId: parentDeckId ?? this.parentDeckId,
      isTemplate: isTemplate ?? this.isTemplate,
      aiSuggestions: aiSuggestions ?? this.aiSuggestions,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      notes: notes ?? this.notes,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    );
  }
}
