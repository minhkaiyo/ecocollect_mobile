import 'package:cloud_firestore/cloud_firestore.dart';

class PointTransaction {
  final String id;
  final String userId;
  final int amount; // + cộng, - trừ
  final String type; // earn_recycle, redeem_voucher, bonus
  final String description;
  final DateTime createdAt;
  final String? orderId;

  PointTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
    this.orderId,
  });

  factory PointTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PointTransaction(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: data['amount'] ?? 0,
      type: data['type'] ?? 'unknown',
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      orderId: data['orderId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'amount': amount,
      'type': type,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      if (orderId != null) 'orderId': orderId,
    };
  }
}
