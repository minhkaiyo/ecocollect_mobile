import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/eco_colors.dart';
import '../../../ui/app_feedback.dart';

class TreeExchangeSheet extends StatelessWidget {
  const TreeExchangeSheet({super.key});

  Future<void> _exchangeForTree(BuildContext context, _TreeModel tree) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      showEcoSnackBar(context, 'Vui lòng đăng nhập để đổi cây', icon: Icons.lock_outline);
      return;
    }

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final pointsCost = int.parse(tree.pointsValue.replaceAll(RegExp(r'[^0-9]'), ''));
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) return;
        
        final currentPoints = snapshot.data()?['greenPoints'] ?? 0;
        if (currentPoints < pointsCost) {
          throw Exception('Bạn không đủ điểm xanh để đổi cây này.');
        }

        transaction.update(userRef, {'greenPoints': currentPoints - pointsCost});
        
        // Ghi lại lịch sử giao dịch
        final txRef = FirebaseFirestore.instance.collection('point_transactions').doc();
        transaction.set(txRef, {
          'userId': uid,
          'amount': -pointsCost,
          'type': 'tree_purchase',
          'description': 'Dùng điểm đổi ${tree.name}',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Cập nhật số lượng cây trong vườn (giả sử có field treesOwned)
        // Nếu muốn quản lý chi tiết hơn có thể tạo collection riêng
      });

      if (context.mounted) {
        ecoSuccessTap();
        showEcoSnackBar(context, 'Chúc mừng! Bạn đã đổi thành công ${tree.name} cho vườn sinh thái!', icon: Icons.forest_rounded);
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        showEcoSnackBar(context, e.toString().replaceAll('Exception: ', ''), icon: Icons.error_outline);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trees = [
      _TreeModel('Cây Bàng Đài Loan', '650 điểm', 'assets/images/trees/bang_dai_loan.jpg', Colors.green),
      _TreeModel('Cây Bạch Đàn', '500 điểm', 'assets/images/trees/bach_dan.jpg', Colors.teal),
      _TreeModel('Cây Bằng Lăng', '550 điểm', 'assets/images/trees/bang_lang.jpg', Colors.lightGreen),
      _TreeModel('Cây Lộc Vừng', '800 điểm', 'assets/images/trees/loc_vung.jpg', Colors.green),
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(22, 16, 22, MediaQuery.of(context).padding.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: EcoColors.sheetHandle, borderRadius: BorderRadius.circular(999)))),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.forest_rounded, color: EcoColors.primary, size: 28),
              SizedBox(width: 10),
              Text('Đổi Điểm Lấy Cây', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Sử dụng Điểm xanh tích lũy từ nỗ lực thu gom rác để đổi lấy những mầm xanh cho vườn sinh thái của bạn!',
            textAlign: TextAlign.center,
            style: TextStyle(color: EcoColors.bodyMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: trees.length,
            itemBuilder: (context, index) {
              final tree = trees[index];
              return Container(
                decoration: BoxDecoration(
                  color: EcoColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: EcoColors.border.withOpacity(0.5)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: tree.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: AssetImage(tree.imagePath),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(tree.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(tree.pointsValue, style: TextStyle(color: tree.color, fontWeight: FontWeight.w900, fontSize: 15)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 32,
                      child: FilledButton(
                        onPressed: () => _exchangeForTree(context, tree),
                        style: FilledButton.styleFrom(
                          backgroundColor: tree.color,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('ĐỔI NGAY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _TreeModel {
  final String name;
  final String pointsValue;
  final String imagePath;
  final Color color;

  _TreeModel(this.name, this.pointsValue, this.imagePath, this.color);
}

// Add missing icon for cactus if not available in default material
extension on Icons {
  static const IconData cactus_rounded = Icons.grass_rounded; // Fallback
}
