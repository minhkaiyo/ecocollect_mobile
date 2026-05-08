import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../models/waste_type.dart';
import '../../../models/order.dart';
import '../../../models/user_profile.dart';
import '../../../models/pickup_location.dart';
import '../../../repositories/order_repository.dart';
import '../../../repositories/stats_repository.dart';
import '../../../repositories/collector_repository.dart';
import '../../../repositories/pickup_location_repository.dart';
import '../../../theme/eco_colors.dart';
import '../../../utils/formatters.dart';
import 'common_home_widgets.dart';

class MarketCard extends StatelessWidget {
  const MarketCard({super.key, required this.wasteTypes, required this.onItemTap});
  final List<WasteType> wasteTypes;
  final ValueChanged<int> onItemTap;

  @override
  Widget build(BuildContext context) {
    return EcoPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EcoSectionHeader(title: 'Giá thị trường hôm nay', live: true),
          const SizedBox(height: 10),
          ...List.generate(4.clamp(0, wasteTypes.length), (index) {
            final item = wasteTypes[index];
            return Column(
              children: [
                if (index > 0) const Divider(height: 14),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onItemTap(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          EcoIconTile(icon: item.icon, color: item.color),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                                Text('${item.range} VND/kg', style: const TextStyle(color: EcoColors.bodyMuted)),
                              ],
                            ),
                          ),
                          Icon(
                            index == 0 ? Icons.trending_up : Icons.trending_flat,
                            color: index == 0 ? EcoColors.success : EcoColors.coral,
                          ),
                          const Icon(Icons.chevron_right_rounded, color: EcoColors.iconMuted, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class ActiveOrderBanner extends StatefulWidget {
  const ActiveOrderBanner({super.key});

  @override
  State<ActiveOrderBanner> createState() => _ActiveOrderBannerState();
}

class _ActiveOrderBannerState extends State<ActiveOrderBanner> {
  Stream<EcoOrder?>? _orderStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _orderStream = OrderRepository().watchActiveOrder(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_orderStream == null) return const SizedBox();

    return StreamBuilder<EcoOrder?>(
      stream: _orderStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) return const SizedBox();
        final order = snapshot.data!;
        return EcoTappablePanel(
          onTap: () {/* Theo dõi chi tiết */},
          padding: EdgeInsets.zero,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(colors: [EcoColors.headline, EcoColors.primaryDark]),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const LivePulse(active: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Đang xử lý tín hiệu thu gom', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                        Text('Loại: ${order.wasteType} (${order.weight} kg) - Đang tìm người thu gom...', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class LivePulse extends StatelessWidget {
  const LivePulse({super.key, required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: .2, end: 1),
            duration: const Duration(seconds: 2),
            curve: Curves.easeOut,
            builder: (context, value, _) {
              return Container(
                width: 52 * value,
                height: 52 * value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(.18 * (1 - value)),
                ),
              );
            },
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: active ? EcoColors.success : EcoColors.iconMuted,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.radar_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class QuickActionsBar extends StatelessWidget {
  const QuickActionsBar({super.key, required this.onAction});
  final ValueChanged<int> onAction;

  @override
  Widget build(BuildContext context) {
    const actions = [
      (Icons.document_scanner_rounded, 'AI scan', 'Nhận diện rác'),
      (Icons.event_available_rounded, 'Đặt lịch', 'Gom định kỳ'),
      (Icons.storefront_rounded, 'Trạm gần', 'Tự mang ra'),
      (Icons.card_giftcard_rounded, 'Đổi điểm', 'Voucher xanh'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(actions.length, (index) {
            final action = actions[index];
            return SizedBox(
              width: compact ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4,
              child: EcoTappablePanel(
                onTap: () => onAction(index),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    EcoIconTile(icon: action.$1, color: EcoColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(action.$2, style: const TextStyle(fontWeight: FontWeight.w900)),
                          Text(action.$3, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: EcoColors.bodyMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: EcoColors.iconMuted),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class ImpactStrip extends StatelessWidget {
  const ImpactStrip({super.key, required this.onTap});
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: StatsRepository().watchGlobalStats(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};
        final kg = (data['totalKgRecycled'] as num?)?.toDouble() ?? 0.0;
        final buyers = data['totalRegisteredBuyers'] ?? 0;
        final stations = data['totalRecyclingStations'] ?? 0;
        final trees = (kg * 0.03).toInt();

        return Row(
          children: [
            Expanded(child: _ImpactCard(icon: Icons.recycling_rounded, value: '${kg.toStringAsFixed(0)}kg', label: 'Đã thu hồi', color: EcoColors.primary, onTap: () => onTap(0))),
            const SizedBox(width: 12),
            Expanded(child: _ImpactCard(icon: Icons.people_alt_rounded, value: '$buyers', label: 'Người thu gom', color: EcoColors.blue, onTap: () => onTap(1))),
            const SizedBox(width: 12),
            Expanded(child: _ImpactCard(icon: Icons.store_rounded, value: '$stations', label: 'Trạm tái chế', color: EcoColors.orange, onTap: () => onTap(2))),
            const SizedBox(width: 12),
            Expanded(child: _ImpactCard(icon: Icons.park_rounded, value: '$trees', label: 'Quỹ xanh', color: EcoColors.primary, onTap: () => onTap(3))),
          ],
        );
      }
    );
  }
}

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({required this.icon, required this.value, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return EcoTappablePanel(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: EcoColors.bodyMuted, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class PaperBankCard extends StatelessWidget {
  const PaperBankCard({super.key, required this.progress, required this.onTap});
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [EcoColors.primaryDark, EcoColors.mintLight])),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Stack(
              children: [
                Positioned(right: 4, bottom: 10, child: Icon(Icons.library_books_rounded, size: 92, color: Colors.white.withOpacity(.34))),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ngân hàng giấy', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    const Text('Gom giấy định kỳ cho lớp, văn phòng và kí túc xá.', style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (progress / 50).clamp(0, 1),
                        minHeight: 12,
                        backgroundColor: Colors.white.withOpacity(.55),
                        color: EcoColors.warmYellow,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Tiến độ tuần này: ${progress.toStringAsFixed(0)} / 50kg', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AiScanCard extends StatelessWidget {
  const AiScanCard({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return EcoTappablePanel(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EcoSectionHeader(title: 'Quét & Phân Loại AI'),
          const SizedBox(height: 12),
          Container(
            height: 92,
            decoration: BoxDecoration(color: EcoColors.mintBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: EcoColors.mintBorder)),
            child: const Center(child: Icon(Icons.add_a_photo_rounded, color: EcoColors.primary, size: 42)),
          ),
          const SizedBox(height: 12),
          const DetectionRow(icon: Icons.local_drink_rounded, title: 'Vỏ lon bia', subtitle: 'Nhôm', score: '90%'),
          const SizedBox(height: 8),
          const DetectionRow(icon: Icons.inventory_2_rounded, title: 'Thùng carton', subtitle: 'Giấy bìa', score: '86%'),
        ],
      ),
    );
  }
}

class DetectionRow extends StatelessWidget {
  const DetectionRow({super.key, required this.icon, required this.title, required this.subtitle, required this.score});
  final IconData icon;
  final String title;
  final String subtitle;
  final String score;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        EcoIconTile(icon: icon, color: EcoColors.coral),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(subtitle, style: const TextStyle(color: EcoColors.bodyMuted)),
            ],
          ),
        ),
        Text(score, style: const TextStyle(color: EcoColors.primary, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class SortingGuideCard extends StatelessWidget {
  const SortingGuideCard({super.key, required this.onRowTap});
  final ValueChanged<int> onRowTap;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Thẻ xanh', 'Giấy bìa ép phẳng, buộc gọn'),
      ('Thẻ vàng', 'Nhựa PET làm sạch bên trong'),
      ('Thẻ đỏ', 'Kim loại tách riêng theo nhóm'),
      ('Thẻ tím', 'Linh kiện điện tử giữ nguyên khối'),
    ];
    return EcoPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EcoSectionHeader(title: 'Cẩm nang phân loại'),
          const SizedBox(height: 10),
          ...List.generate(rows.length, (index) {
            final row = rows[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: EcoColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => onRowTap(index),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: EcoColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text.rich(TextSpan(text: '${row.$1}: ', style: const TextStyle(fontWeight: FontWeight.w900), children: [TextSpan(text: row.$2, style: const TextStyle(fontWeight: FontWeight.w500, color: EcoColors.bodySecondary))]))),
                        const Icon(Icons.chevron_right_rounded, color: EcoColors.iconMuted, size: 20),
                      ],
                    ),
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

class StationFinderCard extends StatelessWidget {
  const StationFinderCard({super.key, required this.onTap});
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PickupLocation>>(
      future: Geolocator.getCurrentPosition().then((pos) => PickupLocationRepository().findNearestN(LatLng(pos.latitude, pos.longitude), count: 3)).catchError((_) => <PickupLocation>[]),
      builder: (context, snapshot) {
        final stations = snapshot.data ?? [];
        return EcoPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EcoSectionHeader(title: 'Trạm tái chế gần nhất'),
              const SizedBox(height: 12),
              if (stations.isEmpty) const Text('Đang tìm trạm gần nhất...', style: TextStyle(color: EcoColors.bodyMuted))
              else ...stations.asMap().entries.map((entry) {
                final s = entry.value;
                return InkWell(
                  onTap: () => onTap(entry.key),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        EcoIconTile(icon: Icons.storefront_rounded, color: EcoColors.primary),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.label, style: const TextStyle(fontWeight: FontWeight.w900)), Text(s.address, style: const TextStyle(color: EcoColors.bodyMuted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)])),
                        const Icon(Icons.chevron_right_rounded, color: EcoColors.iconMuted),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }
    );
  }
}

class EcoReportCard extends StatelessWidget {
  const EcoReportCard({super.key, required this.onCardTap});
  final VoidCallback onCardTap;

  @override
  Widget build(BuildContext context) {
    return EcoTappablePanel(
      onTap: onCardTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EcoSectionHeader(title: 'Báo cáo tháng 5'),
          const SizedBox(height: 14),
          const Text('Tỷ lệ phân loại đúng', style: TextStyle(color: EcoColors.bodyMuted)),
          const SizedBox(height: 6),
          const ClipRRect(borderRadius: BorderRadius.all(Radius.circular(999)), child: LinearProgressIndicator(value: .86, minHeight: 12, backgroundColor: EcoColors.progressTrack, color: EcoColors.primary)),
          const SizedBox(height: 14),
          const Text('86%', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
          const Text('Bạn đã giảm 18.6kg CO2e so với xử lý rác lẫn.', style: TextStyle(color: EcoColors.bodyMuted)),
        ],
      ),
    );
  }
}

class CollectorMatchCard extends StatelessWidget {
  const CollectorMatchCard({super.key, required this.onRowTap});
  final ValueChanged<int> onRowTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserProfile>>(
      future: Geolocator.getCurrentPosition().then((pos) => CollectorRepository().findNearby(LatLng(pos.latitude, pos.longitude), radiusKm: 10.0)).catchError((_) => <UserProfile>[]),
      builder: (context, snapshot) {
        final collectors = snapshot.data ?? [];
        if (collectors.isEmpty) return const SizedBox.shrink();
        return EcoPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EcoSectionHeader(title: 'Người thu gom phù hợp', live: true),
              const SizedBox(height: 12),
              ...collectors.take(3).toList().asMap().entries.map((entry) {
                final c = entry.value;
                return InkWell(
                  onTap: () => onRowTap(entry.key),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 20, backgroundColor: EcoColors.mintBg, backgroundImage: c.photoUrl != null ? NetworkImage(c.photoUrl!) : null, child: c.photoUrl == null ? const Icon(Icons.person) : null),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c.displayName, style: const TextStyle(fontWeight: FontWeight.w900)), Text('4.9 - ${c.totalOrders ?? 0} chuyến', style: const TextStyle(color: EcoColors.bodyMuted, fontSize: 12))])),
                        const Icon(Icons.chevron_right_rounded, color: EcoColors.iconMuted),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }
    );
  }
}

class SchedulePickupCard extends StatelessWidget {
  const SchedulePickupCard({super.key, required this.onOpenDetail});
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return EcoTappablePanel(
      onTap: onOpenDetail,
      child: const Row(
        children: [
          EcoIconTile(icon: Icons.calendar_month_rounded, color: EcoColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Thứ 7 hằng tuần', style: TextStyle(fontWeight: FontWeight.w900)), Text('Nhắc trước 2 giờ — chạm xem chi tiết', style: TextStyle(color: EcoColors.bodyMuted))])),
          Icon(Icons.chevron_right_rounded, color: EcoColors.iconMuted),
        ],
      ),
    );
  }
}
