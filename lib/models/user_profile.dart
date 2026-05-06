import 'package:cloud_firestore/cloud_firestore.dart';

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

  UserProfile({
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
      displayName: data['displayName'] ?? 'Người dùng',
      phone: data['phone'] ?? 'Chưa cập nhật',
      address: data['address'] ?? 'Chưa cập nhật',
      photoUrl: data['photoUrl'],
      greenPoints: data['greenPoints'] ?? 0,
      totalKgRecycled: (data['totalKgRecycled'] ?? 0).toDouble(),
      totalOrders: data['totalOrders'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      role: data['role'] ?? 'seller',
      maxPickupLocations: data['maxPickupLocations'] ?? 2,
      savedPartners: List<String>.from(data['savedPartners'] ?? []),
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
}
