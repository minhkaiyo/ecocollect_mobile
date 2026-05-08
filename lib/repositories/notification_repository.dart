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
        .snapshots()
        .map((s) {
          final list = s.docs.map((e) => {'id': e.id, ...e.data()}).toList();
          list.sort((a, b) {
            final tA = a['createdAt'] as Timestamp?;
            final tB = b['createdAt'] as Timestamp?;
            if (tA == null || tB == null) return 0;
            return tB.compareTo(tA);
          });
          return list;
        });
  }
}
