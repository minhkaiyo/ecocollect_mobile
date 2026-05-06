import 'package:flutter/material.dart';
import '../theme/eco_colors.dart';
import '../constants/app_constants.dart';

/// Reusable panel widget with consistent styling
class EcoPanel extends StatelessWidget {
  const EcoPanel({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? AppConstants.paddingXl,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radius3xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Icon tile widget
class EcoIconTile extends StatelessWidget {
  const EcoIconTile({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40.0,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.5,
      ),
    );
  }
}

/// Section header with optional live indicator
class EcoSectionHeader extends StatelessWidget {
  const EcoSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.live = false,
    this.action,
  });

  final String title;
  final String? subtitle;
  final bool live;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: AppConstants.fontSize3xl,
                        fontWeight: FontWeight.w900,
                        color: EcoColors.headline,
                      ),
                    ),
                  ),
                  if (live) ...[
                    const SizedBox(width: AppConstants.spacingS),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: EcoColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingXs),
                    const Text(
                      'Live',
                      style: TextStyle(
                        color: EcoColors.bodyMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: AppConstants.fontSizeS,
                      ),
                    ),
                  ],
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppConstants.spacingXs),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: EcoColors.bodyMuted,
                    fontSize: AppConstants.fontSizeM,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: AppConstants.spacingM),
          action!,
        ],
      ],
    );
  }
}

/// Info line widget with icon and text
class EcoInfoLine extends StatelessWidget {
  const EcoInfoLine({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor,
  });

  final IconData icon;
  final String text;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: AppConstants.iconSizeM,
            color: iconColor ?? EcoColors.primary,
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: EcoColors.textBody,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon badge widget (for notifications)
class EcoIconBadge extends StatelessWidget {
  const EcoIconBadge({
    super.key,
    required this.icon,
    this.badge,
    this.iconColor,
    this.badgeColor,
  });

  final IconData icon;
  final String? badge;
  final Color? iconColor;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          icon,
          size: AppConstants.iconSizeL,
          color: iconColor ?? EcoColors.headline,
        ),
        if (badge != null && badge!.isNotEmpty)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: badgeColor ?? EcoColors.coral,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Center(
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Mini logo widget
class EcoMiniLogo extends StatelessWidget {
  const EcoMiniLogo({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 36 : 44,
          height: compact ? 36 : 44,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [EcoColors.logoGreenLight, EcoColors.logoGreenDark],
            ),
          ),
          child: Icon(
            Icons.eco_rounded,
            size: compact ? 20 : 24,
            color: Colors.white,
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: AppConstants.spacingM),
          const Text(
            'EcoCollect',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: EcoColors.primaryDark,
            ),
          ),
        ],
      ],
    );
  }
}

/// Map pill widget (for map overlays)
class EcoMapPill extends StatelessWidget {
  const EcoMapPill({
    super.key,
    required this.icon,
    required this.text,
    this.color,
  });

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
        vertical: AppConstants.spacingS,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppConstants.iconSizeS,
            color: color ?? EcoColors.primary,
          ),
          const SizedBox(width: AppConstants.spacingS),
          Text(
            text,
            style: TextStyle(
              color: color ?? EcoColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: AppConstants.fontSizeS,
            ),
          ),
        ],
      ),
    );
  }
}

/// Live pulse indicator
class EcoLivePulse extends StatefulWidget {
  const EcoLivePulse({
    super.key,
    this.active = true,
    this.size = 12.0,
  });

  final bool active;
  final double size;

  @override
  State<EcoLivePulse> createState() => _EcoLivePulseState();
}

class _EcoLivePulseState extends State<EcoLivePulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: const BoxDecoration(
          color: EcoColors.iconMuted,
          shape: BoxShape.circle,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse
            Container(
              width: widget.size * (1 + _controller.value),
              height: widget.size * (1 + _controller.value),
              decoration: BoxDecoration(
                color: EcoColors.success.withOpacity(0.3 * (1 - _controller.value)),
                shape: BoxShape.circle,
              ),
            ),
            // Inner dot
            Container(
              width: widget.size,
              height: widget.size,
              decoration: const BoxDecoration(
                color: EcoColors.success,
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      },
    );
  }
}
