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
  final String type; // 'pickup' (Người mua đến lấy) hoặc 'collection' (Người bán mang đến)

  const PickupLocation({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.label,
    required this.address,
    required this.geoPoint,
    required this.createdAt,
    required this.active,
    this.type = 'pickup',
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
      type: data['type'] ?? 'pickup',
    );
  }
}
