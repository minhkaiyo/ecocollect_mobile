import 'package:flutter/material.dart';
import '../../../theme/eco_colors.dart';
import '../../../ui/app_feedback.dart';

class DonationSheet extends StatelessWidget {
  const DonationSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: EcoColors.sheetHandle, borderRadius: BorderRadius.circular(999)))),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.volunteer_activism_rounded, color: EcoColors.primary, size: 28),
              SizedBox(width: 10),
              Text('Gom Yêu Thương 1/6', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 140,
              color: EcoColors.mintBg,
              child: const Center(child: Icon(Icons.school_rounded, size: 64, color: EcoColors.primary)),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Quyên góp điểm xanh để giúp các em nhỏ tại vùng cao có thêm dụng cụ học tập và cây xanh trường học.',
            style: TextStyle(fontSize: 14, height: 1.5, color: EcoColors.textBody),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Text('Đã quyên góp: 85.867.276đ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
              Text('Mục tiêu: 133tr', style: TextStyle(color: EcoColors.bodyMuted, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(value: 0.64, minHeight: 10, color: EcoColors.primary, backgroundColor: EcoColors.progressTrack),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              _DonationOption(points: 10, label: 'Góp 10đ'),
              const SizedBox(width: 12),
              _DonationOption(points: 50, label: 'Góp 50đ', isPrimary: true),
              const SizedBox(width: 12),
              _DonationOption(points: 100, label: 'Góp 100đ'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonationOption extends StatelessWidget {
  const _DonationOption({required this.points, required this.label, this.isPrimary = false});
  final int points;
  final String label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          showEcoSnackBar(context, 'Cảm ơn bạn đã quyên góp $points điểm xanh!', icon: Icons.favorite_rounded);
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isPrimary ? EcoColors.primary : Colors.white,
            border: Border.all(color: EcoColors.primary, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isPrimary ? Colors.white : EcoColors.primary, fontWeight: FontWeight.w900, fontSize: 13)),
        ),
      ),
    );
  }
}
