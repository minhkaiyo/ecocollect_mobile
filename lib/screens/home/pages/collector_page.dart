import 'package:flutter/material.dart';
import '../../../theme/eco_colors.dart';
import '../widgets/common_home_widgets.dart';

class CollectorPage extends StatelessWidget {
  const CollectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'Dành cho Người thu gom',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        const EcoPanel(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(label: 'Đơn hôm nay', value: '12'),
                  _StatItem(label: 'Thu nhập', value: '450k'),
                  _StatItem(label: 'Đánh giá', value: '4.9'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const EcoSectionHeader(title: 'Bản đồ nhiệt khu vực', live: true),
        const SizedBox(height: 10),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: EcoColors.surfaceMuted,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: EcoColors.border),
          ),
          child: const Center(
            child: Text(
              'Heatmap: khu vực Đống Đa đang có nhu cầu cao',
              style: TextStyle(color: EcoColors.bodyMuted, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const EcoSectionHeader(title: 'Đơn chờ gần bạn'),
        const SizedBox(height: 10),
        const _CollectorOrderCard(
          title: 'Nhựa & Giấy (12kg)',
          address: '12 Chùa Bộc',
          distance: '0.8km',
        ),
        const _CollectorOrderCard(
          title: 'Kim loại (25kg)',
          address: '45 Thái Hà',
          distance: '1.2km',
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: EcoColors.primary),
        ),
        Text(
          label,
          style: const TextStyle(color: EcoColors.bodyMuted, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _CollectorOrderCard extends StatelessWidget {
  const _CollectorOrderCard({
    required this.title,
    required this.address,
    required this.distance,
  });

  final String title;
  final String address;
  final String distance;

  @override
  Widget build(BuildContext context) {
    return EcoPanel(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const EcoIconTile(
            icon: Icons.inventory_rounded,
            color: EcoColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  '$address - $distance',
                  style: const TextStyle(color: EcoColors.bodyMuted),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.navigation_rounded, size: 18),
            label: const Text('Nhận'),
          ),
        ],
      ),
    );
  }
}
