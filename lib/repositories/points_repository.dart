import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/point_transaction.dart';
import 'base_repository.dart';

class PointsRepository extends BaseRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<PointTransaction>> watchHistory(String userId, {int limit = 20}) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('points_history')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PointTransaction.fromFirestore(doc))
            .toList());
  }

  Future<void> addPoints(
      String userId, int amount, String type, String description,
      {String? orderId}) async {
    final batch = _db.batch();

    // 1. Tạo transaction mới
    final newTxRef = _db
        .collection('users')
        .doc(userId)
        .collection('points_history')
        .doc();
        
    final txData = {
      'userId': userId,
      'amount': amount,
      'type': type,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      if (orderId != null) 'orderId': orderId,
    };
    batch.set(newTxRef, txData);

    // 2. Cập nhật tổng điểm trong UserProfile
    final userRef = _db.collection('users').doc(userId);
    batch.update(userRef, {
      'greenPoints': FieldValue.increment(amount),
    });

    await batch.commit();
  }
}
