import 'package:cloud_firestore/cloud_firestore.dart';

class PricePoint {
  final DateTime time;
  final double price;

  const PricePoint({
    required this.time,
    required this.price,
  });

  factory PricePoint.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PricePoint(
      time: (data['time'] as Timestamp).toDate(),
      price: (data['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'time': Timestamp.fromDate(time),
      'price': price,
    };
  }
}
