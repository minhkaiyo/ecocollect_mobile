import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';
import '../utils/error_handler.dart';
import 'base_repository.dart';

/// Repository for managing orders in Firestore
class OrderRepository extends BaseRepository {
  final CollectionReference _collection = 
      FirebaseFirestore.instance.collection('orders');

  /// Watch all orders for a specific user
  /// 
  /// Returns orders sorted by creation date (newest first)
  Stream<List<EcoOrder>> watchUserOrders(String userId) {
    final stream = _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EcoOrder.fromFirestore(doc)).toList());
    
    return stream.transform(
      StreamTransformer<List<EcoOrder>, List<EcoOrder>>.fromHandlers(
        handleError: (error, stackTrace, sink) {
          ErrorHandler.logError(error, stackTrace);
          sink.add(const []);
        },
      ),
    );
  }

  /// Watch active order for a user (pending, accepted, or collecting)
  /// 
  /// Returns the most recent active order or null if none exists
  Stream<EcoOrder?> watchActiveOrder(String userId) {
    final stream = _collection
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['pending', 'accepted', 'collecting'])
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      
      final orders = snapshot.docs
          .map((doc) => EcoOrder.fromFirestore(doc))
          .toList();
      
      // Sort by creation date and return the most recent
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders.first;
    });
    
    return stream.transform(
      StreamTransformer<EcoOrder?, EcoOrder?>.fromHandlers(
        handleError: (error, stackTrace, sink) {
          ErrorHandler.logError(error, stackTrace);
          sink.add(null);
        },
      ),
    );
  }

  /// Create a new order
  /// 
  /// Throws an exception if the order cannot be created
  Future<void> createOrder(Map<String, dynamic> orderData) async {
    try {
      final docId = orderData['id'] as String? ?? generateId;
      await _collection.doc(docId).set({
        ...orderData,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      throw Exception('Lỗi Firebase: ${ErrorHandler.getFirestoreErrorMessage(e)}');
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      throw Exception('Không thể tạo đơn hàng: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _collection.doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      throw Exception('Không thể cập nhật trạng thái: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Cancel an order
  Future<void> cancelOrder(String orderId) async {
    try {
      await _collection.doc(orderId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      throw Exception('Không thể hủy đơn: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Watch all pending orders (for collectors)
  Stream<List<EcoOrder>> watchPendingOrders() {
    return _collection
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map(EcoOrder.fromFirestore).toList())
        .handleError((error, stackTrace) {
      ErrorHandler.logError(error, stackTrace);
      return <EcoOrder>[];
    });
  }

  /// Accept an order (for collectors)
  Future<void> acceptOrder({
    required String orderId,
    required String collectorId,
    required String collectorName,
  }) async {
    try {
      await _collection.doc(orderId).update({
        'status': 'accepted',
        'collectorId': collectorId,
        'collectorName': collectorName,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      throw Exception('Không thể nhận đơn: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Complete an order
  Future<void> completeOrder(String orderId, {int? earnedPoints}) async {
    try {
      final updateData = {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      };
      
      if (earnedPoints != null) {
        updateData['earnedPoints'] = earnedPoints;
      }
      
      await _collection.doc(orderId).update(updateData);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      throw Exception('Không thể hoàn thành đơn: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Get order by ID
  Future<EcoOrder?> getOrder(String orderId) async {
    try {
      final doc = await _collection.doc(orderId).get();
      if (!doc.exists) return null;
      return EcoOrder.fromFirestore(doc);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      return null;
    }
  }
}
