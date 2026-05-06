import 'package:cloud_firestore/cloud_firestore.dart';

class PickupSchedule {
  final String id;
  final String userId;
  final String wasteType;
  final String frequency;
  final String timeSlot;
  final DateTime createdAt;
  final bool active;

  const PickupSchedule({
    required this.id,
    required this.userId,
    required this.wasteType,
    required this.frequency,
    required this.timeSlot,
    required this.createdAt,
    required this.active,
  });

  factory PickupSchedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PickupSchedule(
      id: doc.id,
      userId: data['userId'] ?? '',
      wasteType: data['wasteType'] ?? 'Tổng hợp',
      frequency: data['frequency'] ?? 'Hàng tuần',
      timeSlot: data['timeSlot'] ?? '08:00 - 10:00',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      active: data['active'] ?? true,
    );
  }
}
