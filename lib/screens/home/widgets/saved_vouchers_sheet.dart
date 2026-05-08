import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../models/saved_voucher.dart';
import '../../../repositories/voucher_repository.dart';
import '../../../theme/eco_colors.dart';
import '../../../ui/app_feedback.dart';

class SavedVouchersSheet extends StatelessWidget {
  const SavedVouchersSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Vui lòng đăng nhập'));
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF4F3F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: EcoColors.sheetHandle,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Quà của tôi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<SavedVoucher>>(
              stream: VoucherRepository().watchSavedVouchers(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final vouchers = snapshot.data ?? [];
                
                if (vouchers.isEmpty) {
                  return const Center(
                    child: Text('Bạn chưa có voucher nào.', style: TextStyle(color: EcoColors.bodyMuted)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: vouchers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final sv = vouchers[index];
                    return _SavedVoucherCard(savedVoucher: sv, uid: uid);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedVoucherCard extends StatelessWidget {
  const _SavedVoucherCard({required this.savedVoucher, required this.uid});

  final SavedVoucher savedVoucher;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final bool isActive = savedVoucher.status == 'active';
    
    // Check if expired
    bool isExpired = false;
    if (isActive && savedVoucher.expiresAt != null) {
      if (savedVoucher.expiresAt!.isBefore(DateTime.now())) {
        isExpired = true;
      }
    }

    final bool canUse = isActive && !isExpired;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: canUse ? EcoColors.primary.withOpacity(0.3) : Colors.grey.withOpacity(0.2)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: canUse ? EcoColors.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.card_giftcard_rounded,
              color: canUse ? EcoColors.primary : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  savedVoucher.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: canUse ? EcoColors.textBody : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  savedVoucher.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: EcoColors.bodyMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (canUse)
            FilledButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sử dụng voucher'),
                    content: const Text('Bạn có chắc muốn sử dụng voucher này không? Hành động này không thể hoàn tác.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                      FilledButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await VoucherRepository().markVoucherUsed(uid, savedVoucher.id);
                          if (context.mounted) {
                            showEcoSnackBar(context, 'Đã sử dụng voucher!', icon: Icons.check_circle_rounded);
                          }
                        },
                        child: const Text('Dùng ngay'),
                      ),
                    ],
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: EcoColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Dùng', style: TextStyle(fontWeight: FontWeight.w900)),
            )
          else
            Text(
              isExpired ? 'Hết hạn' : 'Đã dùng',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }
}
