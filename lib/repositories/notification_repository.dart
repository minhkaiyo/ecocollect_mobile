import 'package:cloud_firestore/cloud_firestore.dart';

import 'base_repository.dart';

class NotificationRepository extends BaseRepository {
  CollectionReference<Map<String, dynamic>> get _collection =>
      db.collection('notifications');

  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    String? orderId,
  }) async {
    await _collection.doc().set({
      'userId': userId,
      'title': title,
      'body': body,
      'orderId': orderId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchUserNotifications(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((s) => s.docs.map((e) => {'id': e.id, ...e.data()}).toList());
  }
}
