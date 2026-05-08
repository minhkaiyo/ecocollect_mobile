import 'package:flutter/material.dart';
import '../../../theme/eco_colors.dart';
import '../widgets/common_home_widgets.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'Ví Xanh',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [EcoColors.blue, EcoColors.subtleBlue]),
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tổng Điểm Xanh', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text('2,450', style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900)),
              Text('≈ 245.000 VND', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const EcoSectionHeader(title: 'Đổi quà ưu đãi'),
        const SizedBox(height: 12),
        const _RewardTile(icon: Icons.shopping_bag_rounded, title: 'Voucher Co.op Mart 50k', points: '500'),
        const _RewardTile(icon: Icons.local_cafe_rounded, title: 'Highlands Coffee 20k', points: '200'),
        const _RewardTile(icon: Icons.phone_android_rounded, title: 'Thẻ nạp điện thoại 10k', points: '100'),
      ],
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({
    required this.icon,
    required this.title,
    required this.points,
  });

  final IconData icon;
  final String title;
  final String points;

  @override
  Widget build(BuildContext context) {
    return EcoTappablePanel(
      onTap: () {},
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          EcoIconTile(icon: icon, color: EcoColors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            points,
            style: const TextStyle(
              color: EcoColors.blue,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
