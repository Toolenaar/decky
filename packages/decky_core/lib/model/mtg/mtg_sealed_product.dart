import 'package:cloud_firestore/cloud_firestore.dart';
import '../base_model.dart';
import 'identifiers.dart';
import 'purchase_urls.dart';
import 'sealed_product_contents.dart';

class MtgSealedProduct extends BaseModel {
  final int? cardCount;
  final String? category;
  final SealedProductContents? contents;
  final Identifiers identifiers;
  final String name;
  final int? productSize;
  final PurchaseUrls purchaseUrls;
  final String? releaseDate;
  final String? subtype;
  final String setCode;

  MtgSealedProduct({
    required super.id, // This will be the UUID
    this.cardCount,
    this.category,
    this.contents,
    required this.identifiers,
    required this.name,
    this.productSize,
    required this.purchaseUrls,
    this.releaseDate,
    this.subtype,
    required this.setCode,
  });

  @override
  DocumentReference<Map<String, dynamic>> get ref => 
      FirebaseFirestore.instance.collection('sealed-products').doc(id);

  @override
  Map<String, dynamic> toJson() {
    return {
      if (cardCount != null) 'cardCount': cardCount,
      if (category != null) 'category': category,
      if (contents != null) 'contents': contents?.toJson(),
      'identifiers': identifiers.toJson(),
      'name': name,
      if (productSize != null) 'productSize': productSize,
      'purchaseUrls': purchaseUrls.toJson(),
      if (releaseDate != null) 'releaseDate': releaseDate,
      if (subtype != null) 'subtype': subtype,
      'setCode': setCode,
    };
  }

  factory MtgSealedProduct.fromJson(Map<String, dynamic> json) {
    return MtgSealedProduct(
      id: json['uuid'], // Use UUID as ID for sealed products
      cardCount: json['cardCount'],
      category: json['category'],
      contents: json['contents'] != null 
          ? SealedProductContents.fromJson(json['contents'])
          : null,
      identifiers: Identifiers.fromJson(json['identifiers']),
      name: json['name'],
      productSize: json['productSize'],
      purchaseUrls: PurchaseUrls.fromJson(json['purchaseUrls'] ?? {}),
      releaseDate: json['releaseDate'],
      subtype: json['subtype'],
      setCode: json['setCode'],
    );
  }
}