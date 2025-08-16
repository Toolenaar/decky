import 'package:cloud_firestore/cloud_firestore.dart';

abstract class BaseModel {
  String id;
  Timestamp? createdAt;
  Timestamp? updatedAt;
  DocumentReference<Map<String, dynamic>> get ref;

  Map<String, dynamic> toJson();

  BaseModel({required this.id});

  Future create() async {
    var data = toJson();
    data['createdAt'] = Timestamp.now();
    await ref.set(data);
  }

  Future update(Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.now();

    await ref.set(data, SetOptions(merge: true));
  }

  Future delete() async {
    await ref.delete();
  }

  static String newId(CollectionReference<Map<String, dynamic>> collection) {
    return collection.doc().id;
  }
}
