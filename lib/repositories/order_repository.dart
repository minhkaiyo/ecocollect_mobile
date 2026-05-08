import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';
import '../utils/error_handler.dart';
import 'base_repository.dart';
import 'notification_repository.dart';

/// Repository for managing orders in Firestore
class OrderRepository extends BaseRepository {
  final CollectionReference _collection = 
      FirebaseFirestore.instance.collection('orders');
  final _notifRepo = NotificationRepository();

  /// Watch all orders for a specific user
  /// 
  /// Returns orders sorted by creation date (newest first)
  Stream<List<EcoOrder>> watchUserOrders(String userId) {
    final stream = _collection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
            final list = snapshot.docs.map((doc) => EcoOrder.fromFirestore(doc)).toList();
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return list;
        });
    
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

      // Notify seller
      await _notifRepo.createNotification(
        userId: orderData['userId'],
        title: 'Đã gửi yêu cầu',
        body: 'Yêu cầu thu gom ${orderData['wasteType']} đã được gửi. Đang đợi người thu mua nhận đơn.',
        orderId: docId,
      );
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
        .snapshots()
        .map((snapshot) {
            final list = snapshot.docs.map(EcoOrder.fromFirestore).toList();
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return list;
        })
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

      // Notify users
      final order = await getOrder(orderId);
      if (order != null) {
        // Notify seller
        await _notifRepo.createNotification(
          userId: order.userId,
          title: 'Đơn hàng được nhận',
          body: 'Người thu mua $collectorName đã nhận đơn và đang di chuyển đến bạn.',
          orderId: orderId,
        );

        // Notify collector
        await _notifRepo.createNotification(
          userId: collectorId,
          title: 'Nhận đơn thành công',
          body: 'Bạn đã nhận thu gom đơn hàng của ${order.userId.substring(0, 5)}. Hãy đến địa chỉ người bán.',
          orderId: orderId,
        );
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      throw Exception('Không thể nhận đơn: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  /// Complete an order and award points to the seller
  Future<void> completeOrder(String orderId, {required int earnedPoints}) async {
    try {
      final orderRef = db.collection('orders').doc(orderId);
      
      await db.runTransaction((transaction) async {
        // 1. Get order data
        final orderSnap = await transaction.get(orderRef);
        if (!orderSnap.exists) throw Exception('Đơn hàng không tồn tại.');
        
        final orderData = orderSnap.data() as Map<String, dynamic>;
        final sellerId = orderData['userId'] as String;
        final collectorId = orderData['collectorId'] as String?;
        
        if (collectorId == null) throw Exception('Đơn hàng chưa có người thu gom.');
        
        final sellerRef = db.collection('users').doc(sellerId);
        final collectorRef = db.collection('users').doc(collectorId);
        
        // 2. Get users data
        final sellerSnap = await transaction.get(sellerRef);
        final collectorSnap = await transaction.get(collectorRef);
        
        if (!collectorSnap.exists) throw Exception('Tài khoản người thu gom không tồn tại.');
        
        final collectorData = collectorSnap.data() ?? {};
        final collectorPoints = (collectorData['greenPoints'] ?? 0) as num;
        
        // 3. Validation
        if (collectorPoints < earnedPoints) {
          throw Exception('Số dư điểm xanh không đủ (Cần $earnedPoints, hiện có ${collectorPoints.toInt()}).');
        }
        
        final fee = (earnedPoints * 0.005).ceil();
        final netEarned = earnedPoints - fee;
        final weight = (orderData['weight'] as num?)?.toDouble() ?? 0.0;

        // 4. Update order
        transaction.update(orderRef, {
          'status': 'completed',
          'earnedPoints': earnedPoints,
          'feePoints': fee,
          'completedAt': FieldValue.serverTimestamp(),
        });
        
        // 5. Update collector
        transaction.update(collectorRef, {
          'greenPoints': FieldValue.increment(-earnedPoints),
          'totalOrders': FieldValue.increment(1),
        });
        
        // 6. Update seller
        if (sellerSnap.exists) {
          transaction.update(sellerRef, {
            'greenPoints': FieldValue.increment(netEarned),
            'totalOrders': FieldValue.increment(1),
            'totalKgRecycled': FieldValue.increment(weight),
          });
        }
        
        // 7. Transaction logs
        final txCollectorRef = db.collection('point_transactions').doc();
        transaction.set(txCollectorRef, {
          'userId': collectorId,
          'amount': -earnedPoints,
          'type': 'order_payment',
          'description': 'Thanh toán đơn hàng: ${orderData['wasteType']}',
          'timestamp': FieldValue.serverTimestamp(),
          'orderId': orderId,
        });

        final txSellerRef = db.collection('point_transactions').doc();
        transaction.set(txSellerRef, {
          'userId': sellerId,
          'amount': netEarned,
          'type': 'order_reward',
          'description': 'Thu nhập từ đơn: ${orderData['wasteType']}',
          'timestamp': FieldValue.serverTimestamp(),
          'orderId': orderId,
        });
      });
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, stackTrace);
      // Re-throw the error message directly to be caught by the UI
      throw e.toString().replaceFirst('Exception: ', '');
    }
  }

  /// Watch orders accepted by a collector
  Stream<List<EcoOrder>> watchCollectorOrders(String collectorId) {
    return _collection
        .where('collectorId', isEqualTo: collectorId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) {
            final list = snapshot.docs.map(EcoOrder.fromFirestore).toList();
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return list;
        })
        .handleError((error, stackTrace) {
      ErrorHandler.logError(error, stackTrace);
      return <EcoOrder>[];
    });
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
