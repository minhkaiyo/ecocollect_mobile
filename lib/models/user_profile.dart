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
    );
  }
}
