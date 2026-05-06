import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/voucher.dart';
import 'base_repository.dart';

class VoucherRepository extends BaseRepository {
  Stream<List<Voucher>> watchAvailable() {
    return db
        .collection('vouchers')
        .where('isActive', isEqualTo: true)
        .where('category', isEqualTo: 'platform') // Only platform vouchers
        .orderBy('pointsCost')
        .snapshots()
        .map((snap) => snap.docs.map(Voucher.fromFirestore).toList())
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
      'pointsCost': 0, // Buyer vouchers usually don't cost points for the seller, they are earned by Kg
      'category': 'buyer_reward',
      'isActive': true,
      'createdBy': uid,
      'targetSellerId': targetSellerId,
      'minKgRequired': minKg,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> redeemVoucher(String uid, Voucher voucher, int currentPoints) async {
    if (currentPoints < voucher.pointsCost) {
      throw Exception('Không đủ điểm để đổi voucher này.');
    }

    final batch = db.batch();

    // 1. Trừ điểm user
    final userRef = db.collection('users').doc(uid);
    batch.update(userRef, {
      'greenPoints': FieldValue.increment(-voucher.pointsCost),
    });

    // 2. Tạo giao dịch (transaction)
    final txRef = db.collection('point_transactions').doc();
    batch.set(txRef, {
      'userId': uid,
      'amount': -voucher.pointsCost,
      'type': 'redeem',
      'description': 'Đổi voucher: ${voucher.title}',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 3. Lưu vào lịch sử voucher đã đổi
    final userVoucherRef = db.collection('users').doc(uid).collection('vouchers').doc();
    batch.set(userVoucherRef, {
      'voucherId': voucher.id,
      'title': voucher.title,
      'redeemedAt': FieldValue.serverTimestamp(),
      'status': 'active', // active, used, expired
    });

    await batch.commit();
  }
}
