import 'package:cloud_firestore/cloud_firestore.dart';
import '../base_model.dart';
import 'card_set_deck.dart';

class MtgDeck extends BaseModel {
  final String code;
  final List<CardSetDeck>? commander;
  final List<CardSetDeck> mainBoard;
  final String name;
  final String? releaseDate;
  final List<String>? sealedProductUuids;
  final List<CardSetDeck> sideBoard;
  final String type;
  final String setCode;

  MtgDeck({
    required super.id, // This will be a combination of setCode and deck code
    required this.code,
    this.commander,
    required this.mainBoard,
    required this.name,
    this.releaseDate,
    this.sealedProductUuids,
    required this.sideBoard,
    required this.type,
    required this.setCode,
  });

  @override
  DocumentReference<Map<String, dynamic>> get ref => 
      FirebaseFirestore.instance.collection('decks').doc(id);

  @override
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      if (commander != null) 'commander': commander?.map((e) => e.toJson()).toList(),
      'mainBoard': mainBoard.map((e) => e.toJson()).toList(),
      'name': name,
      if (releaseDate != null) 'releaseDate': releaseDate,
      if (sealedProductUuids != null) 'sealedProductUuids': sealedProductUuids,
      'sideBoard': sideBoard.map((e) => e.toJson()).toList(),
      'type': type,
      'setCode': setCode,
    };
  }

  factory MtgDeck.fromJson(Map<String, dynamic> json) {
    return MtgDeck(
      id: json['id'] ?? '${json['setCode']}_${json['code']}', // Generate ID if not present
      code: json['code'],
      commander: json['commander'] != null 
          ? (json['commander'] as List).map((e) => CardSetDeck.fromJson(e)).toList()
          : null,
      mainBoard: (json['mainBoard'] as List).map((e) => CardSetDeck.fromJson(e)).toList(),
      name: json['name'],
      releaseDate: json['releaseDate'],
      sealedProductUuids: json['sealedProductUuids'] != null 
          ? List<String>.from(json['sealedProductUuids'])
          : null,
      sideBoard: (json['sideBoard'] as List).map((e) => CardSetDeck.fromJson(e)).toList(),
      type: json['type'],
      setCode: json['setCode'],
    );
  }
}