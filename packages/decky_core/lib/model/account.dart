import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decky_core/model/base_model.dart';

class Account extends BaseModel {
  final String email;
  final Timestamp? lastLoginAt;

  Account({required super.id, required this.email, this.lastLoginAt});

  @override
  DocumentReference<Map<String, dynamic>> get ref => FirebaseFirestore.instance.collection('accounts').doc(id);

  @override
  Map<String, dynamic> toJson() {
    return {'email': email, 'lastLoginAt': lastLoginAt};
  }

  static Account fromJson(Map<String, dynamic> json) {
    return Account(id: json['id'], email: json['email'], lastLoginAt: json['lastLoginAt']);
  }

  static Future<Account?> getAccount(String uid) async {
    final snapshot = await FirebaseFirestore.instance.collection('accounts').doc(uid).get();
    return snapshot.data() != null ? Account.fromJson(snapshot.data()!) : null;
  }
}
