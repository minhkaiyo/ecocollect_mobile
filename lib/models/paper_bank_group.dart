import 'package:cloud_firestore/cloud_firestore.dart';

class PaperBankGroup {
  final String id;
  final String name;
  final String type; // class, club, office
  final int memberCount;
  final double totalKgCollected;
  final double targetKg;
  final String createdBy;
  final List<String> members;
  final DateTime createdAt;
  final DateTime? lastPickupAt;
  final String scheduleDay;

  PaperBankGroup({
    required this.id,
    required this.name,
    required this.type,
    required this.memberCount,
    required this.totalKgCollected,
    required this.targetKg,
    required this.createdBy,
    required this.members,
    required this.createdAt,
    this.lastPickupAt,
    required this.scheduleDay,
  });

  factory PaperBankGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PaperBankGroup(
      id: doc.id,
      name: data['name'] ?? 'Nhóm chưa đặt tên',
      type: data['type'] ?? 'class',
      memberCount: data['memberCount'] ?? 1,
      totalKgCollected: (data['totalKgCollected'] ?? 0).toDouble(),
      targetKg: (data['targetKg'] ?? 50.0).toDouble(),
      createdBy: data['createdBy'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastPickupAt: (data['lastPickupAt'] as Timestamp?)?.toDate(),
      scheduleDay: data['scheduleDay'] ?? 'saturday',
    );
  }
}
