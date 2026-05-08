import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/order.dart';
import '../../../models/waste_type.dart';
import '../../../repositories/order_repository.dart';
import '../../../theme/eco_colors.dart';
import '../../../ui/loading_widgets.dart';
import '../../../utils/formatters.dart';

void _showHistorySheet(
  BuildContext context, {
  required String title,
  required String body,
  required IconData icon,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icon, color: EcoColors.primary, size: 42),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.45, color: EcoColors.bodyMuted)),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(backgroundColor: EcoColors.primary),
              child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    ),
  );
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({
    super.key,
    required this.wasteTypes,
    required this.onOrderTap,
  });

  final List<WasteType> wasteTypes;
  final Function(EcoOrder, WasteType) onOrderTap;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Vui lòng đăng nhập'));
    }

    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEAF8F1),
              Color(0xFFF6FCF8),
              Color(0xFFFFFFFF),
            ],
            stops: [0, .45, 1],
          ),
        ),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Column(
                children: [
                  const _HistorySearchBar(),
                  const SizedBox(height: 18),
                  const _SegmentTabs(),
                  const SizedBox(height: 14),
                  const _ExpenseSummaryCard(),
                  const SizedBox(height: 14),
                  const _TodayNotice(),
                  const SizedBox(height: 14),
                  const _CategoryTabs(),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
      child: Container(
        color: const Color(0xFFF1FAF5),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: const Row(
          children: [
          Expanded(
            child: Text(
            'Tháng 5/2026',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        Text(
          'Thống kê',
            style: TextStyle(
            fontSize: 13,
            color: EcoColors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(width: 4),
        Icon(Icons.chevron_right_rounded, color: EcoColors.primary),
      ],
    ),
  ),
),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 112),
            sliver: EcoStreamSliver(
              uid: uid,
              wasteTypes: wasteTypes,
              onOrderTap: onOrderTap,
            ),
          ),
        ],
      ),
    );
  }
}

class EcoStreamSliver extends StatelessWidget {
  const EcoStreamSliver({
    super.key,
    required this.uid,
    required this.wasteTypes,
    required this.onOrderTap,
  });

  final String uid;
  final List<WasteType> wasteTypes;
  final Function(EcoOrder, WasteType) onOrderTap;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: EcoStreamBuilder<List<EcoOrder>>(
        stream: OrderRepository().watchUserOrders(uid),
        loadingWidget: const Center(child: Padding(
          padding: EdgeInsets.all(28),
          child: CircularProgressIndicator(),
        )),
        builder: (context, orders) {
          final list = orders.isEmpty ? _mockOrders() : orders;
          return Column(
            children: List.generate(list.length, (index) {
              final order = list[index];
              final type = wasteTypes.firstWhere(
                (item) => item.name == order.wasteType,
                orElse: () => wasteTypes.first,
              );
              return _HistoryTransactionTile(
                order: order,
                type: type,
                onTap: () => onOrderTap(order, type),
                dimmed: orders.isEmpty && index == 1,
              );
            }),
          );
        },
      ),
    );
  }

  List<EcoOrder> _mockOrders() {
    return [
      EcoOrder(
        id: 'demo-1',
        userId: uid,
        wasteType: wasteTypes.first.name,
        weight: 8,
        estimatedPrice: 36000,
        status: 'completed',
        createdAt: DateTime(2026, 5, 7, 1, 32),
        earnedPoints: 216,
      ),
      EcoOrder(
        id: 'demo-2',
        userId: uid,
        wasteType: wasteTypes.length > 1 ? wasteTypes[1].name : wasteTypes.first.name,
        weight: 5,
        estimatedPrice: 25000,
        status: 'completed',
        createdAt: DateTime(2026, 5, 6, 1, 35),
        earnedPoints: 176,
      ),
      EcoOrder(
        id: 'demo-3',
        userId: uid,
        wasteType: wasteTypes.length > 2 ? wasteTypes[2].name : wasteTypes.first.name,
        weight: 3,
        estimatedPrice: 42000,
        status: 'pending',
        createdAt: DateTime(2026, 5, 5, 1, 33),
        earnedPoints: 0,
      ),
    ];
  }
}

class _HistorySearchBar extends StatelessWidget {
  const _HistorySearchBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _showHistorySheet(
              context,
              title: 'Tìm kiếm giao dịch',
              body: 'Nhập loại rác, trạng thái, ngày hoặc giá trị giao dịch để lọc lịch sử thu gom.',
              icon: Icons.search_rounded,
            ),
            child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.search_rounded, size: 28, color: EcoColors.bodyMuted),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tìm kiếm giao dịch',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: EcoColors.bodyMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _CircleButton(
          icon: Icons.filter_alt_outlined,
          onTap: () => _showHistorySheet(
            context,
            title: 'Bộ lọc',
            body: 'Lọc theo tháng, trạng thái đơn, loại rác, điểm xanh và giá trị thu gom.',
            icon: Icons.filter_alt_rounded,
          ),
        ),
        const SizedBox(width: 8),
        _CircleButton(
          icon: Icons.grid_view_rounded,
          onTap: () => _showHistorySheet(
            context,
            title: 'Chế độ xem',
            body: 'Chuyển giữa danh sách giao dịch, thống kê tháng và biểu đồ điểm xanh.',
            icon: Icons.grid_view_rounded,
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, color: EcoColors.textBody),
      ),
    );
  }
}

class _SegmentTabs extends StatelessWidget {
  const _SegmentTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: BoxDecoration(color: Colors.white.withOpacity(.76), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 74,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(18), bottomLeft: Radius.circular(18), bottomRight: Radius.circular(24)),
              ),
              child: GestureDetector(
                onTap: () => _showHistorySheet(
                  context,
                  title: 'Hoạt động',
                  body: 'Danh sách các đơn thu gom, đổi voucher và giao dịch điểm xanh gần đây.',
                  icon: Icons.history_toggle_off_rounded,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_toggle_off_rounded, color: EcoColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Hoạt động',
                      style: TextStyle(
                        fontSize: 17,
                        color: EcoColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _showHistorySheet(
                context,
                title: 'Thống kê',
                body: 'Tổng hợp khối lượng tái chế, điểm xanh nhận được và giá trị thu gom theo tháng.',
                icon: Icons.account_balance_wallet_outlined,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, color: EcoColors.sky),
                  SizedBox(width: 8),
                  Text(
                    'Thống kê',
                    style: TextStyle(
                      fontSize: 17,
                      color: EcoColors.textBody,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseSummaryCard extends StatelessWidget {
  const _ExpenseSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EcoColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, color: EcoColors.sky),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Quản lý điểm xanh', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(color: Color(0xFFFFECF5), shape: BoxShape.circle),
                child: const Icon(Icons.chevron_right_rounded, color: EcoColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8F1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const CustomPaint(painter: _MiniBarChartPainter()),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'Tháng 5 bạn đã tái chế\n',
                    style: TextStyle(fontSize: 17, height: 1.45, color: EcoColors.textBody),
                    children: [
                      TextSpan(text: '25.0kg', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayNotice extends StatelessWidget {
  const _TodayNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EcoColors.mintBorder),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: EcoColors.primary,
            child: Text(
              '1',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
          SizedBox(width: 10),
          Expanded(child: Text('Giao dịch dự kiến vào hôm nay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
          Text('Xem chi tiết', style: TextStyle(fontSize: 16, color: EcoColors.primary, fontWeight: FontWeight.w900)),
          Icon(Icons.chevron_right_rounded, color: EcoColors.primary),
        ],
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs();

  @override
  Widget build(BuildContext context) {
    const tabs = ['Tất cả', 'Lợi nhuận', 'Thu gom', 'Voucher', 'Nạp điểm'];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final selected = index == 0;
          return GestureDetector(
            onTap: () => _showHistorySheet(
              context,
              title: tabs[index],
              body: 'Lọc lịch sử theo nhóm ${tabs[index].toLowerCase()}.',
              icon: selected ? Icons.done_rounded : Icons.filter_list_rounded,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: 16,
                    color: selected ? EcoColors.primary : EcoColors.textBody,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: selected ? 70 : 0,
                  height: 3,
                  decoration: BoxDecoration(color: EcoColors.primary, borderRadius: BorderRadius.circular(999)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HistoryTransactionTile extends StatelessWidget {
  const _HistoryTransactionTile({
    required this.order,
    required this.type,
    required this.onTap,
    this.dimmed = false,
  });

  final EcoOrder order;
  final WasteType type;
  final VoidCallback onTap;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final positive = order.status == 'completed';
    final points = positive ? '+${order.earnedPoints == 0 ? 216 : order.earnedPoints}đ' : 'Đang xử lý';
    final date = '${order.createdAt.day.toString().padLeft(2, '0')}/${order.createdAt.month.toString().padLeft(2, '0')}/${order.createdAt.year}';

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: dimmed ? .55 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: EcoColors.border)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: type.color.withOpacity(.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: EcoColors.border),
                ),
                child: Icon(type.icon, color: type.color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thu gom ${order.wasteType}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')} - $date',
                      style: const TextStyle(fontSize: 11, color: EcoColors.bodyMuted, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: EcoColors.mintBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        positive ? 'Lợi nhuận xanh' : 'Đang thu gom',
                        style: const TextStyle(fontSize: 11, color: EcoColors.primary, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    points,
                    style: TextStyle(
                      color: positive ? EcoColors.success : EcoColors.orange,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${formatVnd(order.estimatedPrice)}đ',
                    style: const TextStyle(color: EcoColors.bodyMuted, fontSize: 12, fontWeight: FontWeight.w600),
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

class _MiniBarChartPainter extends CustomPainter {
  const _MiniBarChartPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = const Color(0xFF9AA8A3)
      ..strokeWidth = 1.4;
    final barPaint = Paint()
      ..color = const Color(0xFFCBE2FF)
      ..style = PaintingStyle.fill;
    final activePaint = Paint()
      ..color = EcoColors.blue
      ..style = PaintingStyle.fill;

    final baseY = size.height - 22;
    canvas.drawLine(Offset(18, baseY), Offset(size.width - 18, baseY), axisPaint);

    final widths = [32.0, 32.0, 44.0];
    final heights = [36.0, 62.0, 7.0];
    final xs = [42.0, size.width / 2 - 16, size.width - 82];

    for (var i = 0; i < 3; i++) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(xs[i], baseY - heights[i], widths[i], heights[i]),
        const Radius.circular(5),
      );
      canvas.drawRRect(rect, i == 2 ? activePaint : barPaint);
    }

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final entry in {'T3': 52.0, 'T4': size.width / 2 - 6, 'T5': size.width - 72}.entries) {
      textPainter.text = TextSpan(
        text: entry.key,
        style: TextStyle(
          color: entry.key == 'T5' ? EcoColors.blue : EcoColors.bodyMuted,
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(entry.value, baseY + 5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
