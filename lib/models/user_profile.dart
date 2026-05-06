import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

/// User profile model representing a user in the system
/// 
/// Roles:
/// - 'seller': Regular user who sells waste
/// - 'collector': Waste collector
/// - 'station': Recycling station
class UserProfile {
  final String uid;
  final String displayName;
  final String phone;
  final String address;
  final String? photoUrl;
  final int greenPoints;
  final double totalKgRecycled;
  final int totalOrders;
  final DateTime createdAt;
  final String role;
  final int maxPickupLocations;
  final List<String> savedPartners;
  final GeoPoint? location;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.phone,
    required this.address,
    this.photoUrl,
    required this.greenPoints,
    required this.totalKgRecycled,
    required this.totalOrders,
    required this.createdAt,
    required this.role,
    required this.maxPickupLocations,
    this.savedPartners = const [],
    this.location,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserProfile(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? 'Người dùng',
      phone: data['phone'] as String? ?? 'Chưa cập nhật',
      address: data['address'] as String? ?? 'Chưa cập nhật',
      photoUrl: data['photoUrl'] as String?,
      greenPoints: (data['greenPoints'] as num?)?.toInt() ?? 0,
      totalKgRecycled: (data['totalKgRecycled'] as num?)?.toDouble() ?? 0.0,
      totalOrders: (data['totalOrders'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      role: data['role'] as String? ?? 'seller',
      maxPickupLocations: (data['maxPickupLocations'] as num?)?.toInt() ?? 
          AppConstants.maxPickupLocationsDefault,
      savedPartners: List<String>.from(data['savedPartners'] as List? ?? []),
      location: data['location'] as GeoPoint?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'phone': phone,
      'address': address,
      'photoUrl': photoUrl,
      'greenPoints': greenPoints,
      'totalKgRecycled': totalKgRecycled,
      'totalOrders': totalOrders,
      'createdAt': Timestamp.fromDate(createdAt),
      'role': role,
      'maxPickupLocations': maxPickupLocations,
      'savedPartners': savedPartners,
      if (location != null) 'location': location,
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? phone,
    String? address,
    String? photoUrl,
    int? greenPoints,
    double? totalKgRecycled,
    int? totalOrders,
    String? role,
    int? maxPickupLocations,
    List<String>? savedPartners,
    GeoPoint? location,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      greenPoints: greenPoints ?? this.greenPoints,
      totalKgRecycled: totalKgRecycled ?? this.totalKgRecycled,
      totalOrders: totalOrders ?? this.totalOrders,
      createdAt: createdAt,
      role: role ?? this.role,
      maxPickupLocations: maxPickupLocations ?? this.maxPickupLocations,
      savedPartners: savedPartners ?? this.savedPartners,
      location: location ?? this.location,
    );
  }

  /// Check if user is a collector
  bool get isCollector => role == 'collector';

  /// Check if user is a station
  bool get isStation => role == 'station';

  /// Check if user is a seller (regular user)
  bool get isSeller => role == 'seller';

  /// Get formatted points display
  String get pointsDisplay => '$greenPoints Điểm';

  /// Get formatted kg recycled display
  String get kgRecycledDisplay => '${totalKgRecycled.toStringAsFixed(1)} kg';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() => 'UserProfile(uid: $uid, displayName: $displayName, role: $role)';
}
