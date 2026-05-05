import 'package:cloud_firestore/cloud_firestore.dart';

class EcoOrder {
  final String id;
  final String userId;
  final String wasteType;
  final double weight;
  final int estimatedPrice;
  final String status;
  final String? collectorId;
  final String? collectorName;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? address;
  final GeoPoint? location;
  final int earnedPoints;

  EcoOrder({
    required this.id,
    required this.userId,
    required this.wasteType,
    required this.weight,
    required this.estimatedPrice,
    required this.status,
    this.collectorId,
    this.collectorName,
    required this.createdAt,
    this.completedAt,
    this.address,
    this.location,
    this.earnedPoints = 0,
  });

  factory EcoOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EcoOrder(
      id: doc.id,
      userId: data['userId'] ?? '',
      wasteType: data['wasteType'] ?? '',
      weight: (data['weight'] ?? 0).toDouble(),
      estimatedPrice: data['totalPrice'] ?? data['estimatedPrice'] ?? 0,
      status: data['status'] ?? 'pending',
      collectorId: data['collectorId'],
      collectorName: data['collectorName'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      address: data['address'],
      location: data['location'] as GeoPoint?,
      earnedPoints: data['earnedPoints'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'wasteType': wasteType,
      'weight': weight,
      'totalPrice': estimatedPrice,
      'status': status,
      if (collectorId != null) 'collectorId': collectorId,
      if (collectorName != null) 'collectorName': collectorName,
      'createdAt': Timestamp.fromDate(createdAt),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      if (address != null) 'address': address,
      if (location != null) 'location': location,
      if (earnedPoints > 0) 'earnedPoints': earnedPoints,
    };
  }
}
