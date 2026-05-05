import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';
import 'base_repository.dart';

class OrderRepository extends BaseRepository {
  final CollectionReference _collection = FirebaseFirestore.instance.collection('orders');

  Stream<List<EcoOrder>> watchUserOrders(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EcoOrder.fromFirestore(doc))
            .toList())
        .handleError((_) => <EcoOrder>[]); // Firestore index chưa tạo → trả list rỗng
  }

  Stream<EcoOrder?> watchActiveOrder(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['pending', 'accepted', 'collecting'])
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final orders = snapshot.docs.map((doc) => EcoOrder.fromFirestore(doc)).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders.first;
    }).handleError((_) => null); // Firestore index chưa tạo → trả null
  }

  Future<void> createOrder(Map<String, dynamic> orderData) async {
    try {
      final docId = orderData['id'] ?? generateId;
      await _collection.doc(docId).set({
        ...orderData,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception('Lỗi Firebase: ${e.message}');
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _collection.doc(orderId).update({'status': status});
  }

  Future<void> cancelOrder(String orderId) async {
    await _collection.doc(orderId).update({'status': 'cancelled'});
  }
}
