import 'package:cloud_firestore/cloud_firestore.dart';

class Voucher {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final String category;
  final bool isActive;
  final String? createdBy;
  final String? targetSellerId;
  final double minKgRequired;
  final DateTime? expiresAt;
  final String? imageUrl;

  Voucher({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.category,
    required this.isActive,
    this.createdBy,
    this.targetSellerId,
    this.minKgRequired = 0.0,
    this.expiresAt,
    this.imageUrl,
  });

  factory Voucher.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Voucher(
      id: doc.id,
      title: data['title'] ?? 'Voucher',
      description: data['description'] ?? '',
      pointsCost: data['pointsCost'] ?? 0,
      category: data['category'] ?? 'other',
      isActive: data['isActive'] ?? true,
      createdBy: data['createdBy'],
      targetSellerId: data['targetSellerId'],
      minKgRequired: (data['minKgRequired'] ?? 0).toDouble(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'pointsCost': pointsCost,
      'category': category,
      'isActive': isActive,
      if (createdBy != null) 'createdBy': createdBy,
      if (targetSellerId != null) 'targetSellerId': targetSellerId,
      'minKgRequired': minKgRequired,
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}
