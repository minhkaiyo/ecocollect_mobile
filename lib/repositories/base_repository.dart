import 'package:cloud_firestore/cloud_firestore.dart';

abstract class BaseRepository<T> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  
  // Các hàm tiện ích dùng chung có thể viết ở đây
  String get generateId => db.collection('tmp').doc().id;
}
