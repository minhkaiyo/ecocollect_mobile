import 'package:flutter/material.dart';
import '../../../theme/eco_colors.dart';

class EcoMiniLogo extends StatelessWidget {
  const EcoMiniLogo({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 50 : 44,
          height: compact ? 50 : 44,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [EcoColors.logoGreenLight, EcoColors.logoGreenDark],
            ),
          ),
          child: const Icon(Icons.eco_rounded, color: Colors.white),
        ),
        if (!compact) ...[
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EcoCollect',
                style: TextStyle(
                  color: EcoColors.primaryDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Đồng nát Online',
                style: TextStyle(color: EcoColors.bodyMuted, height: 1),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class EcoIconBadge extends StatelessWidget {
  const EcoIconBadge({super.key, required this.icon, required this.badge});
  final IconData icon;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon),
        ),
        Positioned(
          right: -2,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: EcoColors.coral,
              shape: BoxShape.circle,
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
