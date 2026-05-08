import 'package:cloud_firestore/cloud_firestore.dart';

class SavedVoucher {
  final String id;
  final String voucherId;
  final String title;
  final String description;
  final String category;
  final int pointsCost;
  final DateTime savedAt;
  final DateTime? expiresAt;
  final String status; // active, used, expired
  final String? imageUrl;

  SavedVoucher({
    required this.id,
    required this.voucherId,
    required this.title,
    required this.description,
    required this.category,
    required this.pointsCost,
    required this.savedAt,
    this.expiresAt,
    required this.status,
    this.imageUrl,
  });

  factory SavedVoucher.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SavedVoucher(
      id: doc.id,
      voucherId: data['voucherId'] ?? '',
      title: data['title'] ?? 'Voucher',
      description: data['description'] ?? '',
      category: data['category'] ?? 'other',
      pointsCost: data['pointsCost'] ?? 0,
      savedAt: (data['savedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'active',
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'voucherId': voucherId,
      'title': title,
      'description': description,
      'category': category,
      'pointsCost': pointsCost,
      'savedAt': Timestamp.fromDate(savedAt),
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      'status': status,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}
