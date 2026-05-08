import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/voucher.dart';
import '../models/saved_voucher.dart';
import 'base_repository.dart';

class VoucherRepository extends BaseRepository {
  Stream<List<Voucher>> watchAvailable() {
    return db
        .collection('vouchers')
        .where('isActive', isEqualTo: true)
        .where('category', isEqualTo: 'platform') // Only platform vouchers
        .orderBy('pointsCost')
        .snapshots()
        .map((snap) => snap.docs
            .map(Voucher.fromFirestore)
            .where((v) => 
              !v.title.contains('Tái chế thông minh') && 
              !v.title.contains('Bus/Metro')
            )
            .toList())
        .handleError((e) => <Voucher>[]);
  }

  Stream<List<Voucher>> watchBuyerVouchers(String buyerUid) {
    return db
        .collection('vouchers')
        .where('createdBy', isEqualTo: buyerUid)
        .orderBy('expiresAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Voucher.fromFirestore).toList())
        .handleError((e) => <Voucher>[]);
  }

  Stream<List<Voucher>> watchVouchersForSeller(String sellerUid) {
    return db
        .collection('vouchers')
        .where('targetSellerId', isEqualTo: sellerUid)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map(Voucher.fromFirestore).toList())
        .handleError((e) => <Voucher>[]);
  }

  Future<void> addVoucher(Voucher voucher) async {
    await db.collection('vouchers').add(voucher.toFirestore());
  }

  Future<void> createBuyerVoucher({
    required String uid,
    required String title,
    required String description,
    String? targetSellerId,
    required double minKg,
    required DateTime expiresAt,
  }) async {
    await db.collection('vouchers').add({
      'title': title,
      'description': description,
      'pointsCost': 0, 
      'category': 'buyer_reward',
      'isActive': true,
      'createdBy': uid,
      'targetSellerId': targetSellerId,
      'minKgRequired': minKg,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> redeemVoucher(String uid, Voucher voucher) async {
    await db.runTransaction((transaction) async {
      final userRef = db.collection('users').doc(uid);
      final userSnap = await transaction.get(userRef);
      
      if (!userSnap.exists) throw Exception('Người dùng không tồn tại.');
      
      final userData = userSnap.data()!;
      final currentPoints = (userData['greenPoints'] ?? 0) as num;

      if (currentPoints < voucher.pointsCost) {
        throw Exception('Bạn cần ${voucher.pointsCost} điểm để đổi voucher này. Hiện có $currentPoints điểm.');
      }

      transaction.update(userRef, {
        'greenPoints': FieldValue.increment(-voucher.pointsCost),
      });

      final txRef = db.collection('point_transactions').doc();
      transaction.set(txRef, {
        'userId': uid,
        'amount': -voucher.pointsCost,
        'type': 'redeem',
        'description': 'Đổi voucher: ${voucher.title}',
        'timestamp': FieldValue.serverTimestamp(),
      });

      final userVoucherRef = userRef.collection('saved_vouchers').doc();
      transaction.set(userVoucherRef, {
        'voucherId': voucher.id,
        'title': voucher.title,
        'description': voucher.description,
        'category': voucher.category,
        'pointsCost': voucher.pointsCost,
        'savedAt': FieldValue.serverTimestamp(),
        if (voucher.expiresAt != null) 'expiresAt': Timestamp.fromDate(voucher.expiresAt!),
        'status': 'active',
        if (voucher.imageUrl != null) 'imageUrl': voucher.imageUrl,
      });
    });
  }

  Future<void> saveVoucher(String uid, Voucher voucher) async {
    final userVoucherRef = db.collection('users').doc(uid).collection('saved_vouchers').doc();
    await userVoucherRef.set({
      'voucherId': voucher.id,
      'title': voucher.title,
      'description': voucher.description,
      'category': voucher.category,
      'pointsCost': voucher.pointsCost,
      'savedAt': FieldValue.serverTimestamp(),
      if (voucher.expiresAt != null) 'expiresAt': Timestamp.fromDate(voucher.expiresAt!),
      'status': 'active',
      if (voucher.imageUrl != null) 'imageUrl': voucher.imageUrl,
    });
  }

  Stream<List<SavedVoucher>> watchSavedVouchers(String uid) {
    return db
        .collection('users')
        .doc(uid)
        .collection('saved_vouchers')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SavedVoucher.fromFirestore).toList())
        .handleError((e) => <SavedVoucher>[]);
  }

  Future<void> markVoucherUsed(String uid, String savedId) async {
    await db
        .collection('users')
        .doc(uid)
        .collection('saved_vouchers')
        .doc(savedId)
        .update({
      'status': 'used',
    });
  }

  Stream<List<Voucher>> watchVouchersByCategory(String? category) {
    Query<Map<String, dynamic>> query = db.collection('vouchers').where('isActive', isEqualTo: true);
    
    if (category != null && category != 'Tất cả') {
      String backendCategory = category;
      switch (category) {
        case 'Điểm xanh': backendCategory = 'points'; break;
        case 'Ăn uống': backendCategory = 'food'; break;
        case 'Mua sắm': backendCategory = 'shopping'; break;
        case 'Di chuyển': backendCategory = 'transport'; break;
        case 'Tái chế': backendCategory = 'recycle'; break;
      }
      query = query.where('category', isEqualTo: backendCategory);
    }
    
    return query
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map(Voucher.fromFirestore)
              .where((v) => 
                !v.title.contains('Tái chế thông minh') && 
                !v.title.contains('Bus/Metro')
              )
              .toList();
          list.sort((a, b) => a.pointsCost.compareTo(b.pointsCost));
          return list;
        })
        .handleError((e) => <Voucher>[]);
  }

  Future<void> deleteVoucher(String voucherId) async {
    await db.collection('vouchers').doc(voucherId).delete();
  }
}
