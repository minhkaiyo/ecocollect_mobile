import 'package:flutter/material.dart';
import '../../../theme/eco_colors.dart';
import '../../../constants/app_constants.dart';
import '../../../repositories/user_repository.dart';
import '../../../ui/app_feedback.dart';

class SubscriptionSheet extends StatefulWidget {
  const SubscriptionSheet({super.key, required this.currentTier, required this.uid});
  final String currentTier;
  final String uid;

  @override
  State<SubscriptionSheet> createState() => _SubscriptionSheetState();
}

class _SubscriptionSheetState extends State<SubscriptionSheet> {
  bool _isLoading = false;

  Future<void> _upgrade(String tier) async {
    if (tier == widget.currentTier) return;

    setState(() => _isLoading = true);
    try {
      // Giả lập thanh toán tiền mặt thành công
      await UserRepository().upgradeTier(widget.uid, tier);
      if (mounted) {
        ecoSuccessTap();
        Navigator.pop(context);
        showEcoSnackBar(
          context, 
          'Nâng cấp lên gói ${AppConstants.subTiers[tier]!['label']} thành công!',
          icon: Icons.auto_awesome_rounded,
        );
      }
    } catch (e) {
      if (mounted) showEcoSnackBar(context, 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: EcoColors.sheetHandle,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nâng cấp Tài khoản',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Mở rộng giới hạn điểm thu mua và tập kết để tối ưu hóa việc kinh doanh của bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(color: EcoColors.bodyMuted, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 28),
          
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _TierCard(
                    tierKey: 'pro',
                    name: 'GÓI PRO',
                    limit: 10,
                    price: '100.000đ',
                    color: EcoColors.primary,
                    icon: Icons.star_rounded,
                    isCurrent: widget.currentTier == 'pro',
                    onTap: () => _upgrade('pro'),
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                  _TierCard(
                    tierKey: 'plus',
                    name: 'GÓI PLUS',
                    limit: 20,
                    price: '400.000đ',
                    color: EcoColors.orange,
                    icon: Icons.stars_rounded,
                    isCurrent: widget.currentTier == 'plus',
                    onTap: () => _upgrade('plus'),
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                  _TierCard(
                    tierKey: 'ultra',
                    name: 'GÓI ULTRA',
                    limit: 50,
                    price: '1.000.000đ',
                    color: EcoColors.blue,
                    icon: Icons.auto_awesome_rounded,
                    isCurrent: widget.currentTier == 'ultra',
                    onTap: () => _upgrade('ultra'),
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          const Text(
            '* Thanh toán định kỳ mỗi tháng bằng tiền mặt cho đại diện EcoCollect hoặc chuyển khoản ngân hàng.',
            style: TextStyle(fontSize: 11, color: EcoColors.bodyMuted, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.tierKey,
    required this.name,
    required this.limit,
    required this.price,
    required this.color,
    required this.icon,
    required this.isCurrent,
    required this.onTap,
    required this.isLoading,
  });

  final String tierKey;
  final String name;
  final int limit;
  final String price;
  final Color color;
  final IconData icon;
  final bool isCurrent;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isCurrent ? color.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCurrent ? color : EcoColors.border,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: isCurrent || isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.w900, 
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tối đa $limit điểm vị trí',
                      style: const TextStyle(
                        fontSize: 13, 
                        fontWeight: FontWeight.w600,
                        color: EcoColors.textBody,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 15, 
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    '/ tháng',
                    style: TextStyle(
                      fontSize: 11, 
                      color: EcoColors.bodyMuted,
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ĐANG DÙNG',
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 8, 
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
