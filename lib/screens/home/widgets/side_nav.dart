import 'package:flutter/material.dart';
import '../../../theme/eco_colors.dart';
import 'mini_logo.dart';

class HomeSideNav extends StatelessWidget {
  const HomeSideNav({super.key, required this.tab, required this.onChanged});
  final int tab;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Trang chủ'),
      (Icons.history_rounded, 'Lịch sử'),
      (Icons.map_rounded, 'Thu mua'),
      (Icons.account_balance_wallet_rounded, 'Ví Xanh'),
      (Icons.settings_rounded, 'Cài đặt'),
    ];
    return Container(
      width: 128,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: EcoColors.border)),
      ),
      child: Column(
        children: [
          const EcoMiniLogo(compact: true),
          const SizedBox(height: 24),
          ...List.generate(items.length, (index) {
            final item = items[index];
            final active = index == tab;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => onChanged(index),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: active ? EcoColors.mintBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        item.$1,
                        color: active
                            ? EcoColors.primary
                            : EcoColors.navInactive,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.$2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: active
                              ? EcoColors.primary
                              : EcoColors.navInactive,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
