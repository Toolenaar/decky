import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decky_core/model/base_model.dart';

class UserCollection extends BaseModel {
  final String accountId;
  final String name;
  final int totalCards;

  UserCollection({required super.id, required this.accountId, required this.name, required this.totalCards});

  @override
  DocumentReference<Map<String, dynamic>> get ref =>
      FirebaseFirestore.instance.collection('accounts').doc(accountId).collection('collections').doc("default");

  @override
  Map<String, dynamic> toJson() {
    return {'accountId': accountId, 'name': name, 'totalCards': totalCards};
  }
}
