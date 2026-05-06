import 'package:cloud_firestore/cloud_firestore.dart';

class PickupLocation {
  final String id;
  final String ownerId;
  final String ownerName;
  final String label;
  final String address;
  final GeoPoint geoPoint;
  final DateTime createdAt;
  final bool active;

  const PickupLocation({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.label,
    required this.address,
    required this.geoPoint,
    required this.createdAt,
    required this.active,
  });

  factory PickupLocation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PickupLocation(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? 'Người thu mua',
      label: data['label'] ?? 'Điểm thu mua',
      address: data['address'] ?? '',
      geoPoint: data['geoPoint'] as GeoPoint? ?? const GeoPoint(21.0285, 105.8542),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      active: data['active'] ?? true,
    );
  }
}
