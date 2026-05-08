// green_points_dashboard_sheet.dart — Dashboard Điểm xanh với biểu đồ cột
// 2026-05-07
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme/eco_colors.dart';
import '../../../ui/app_feedback.dart';
import '../../../models/user_profile.dart';
import '../../../repositories/user_repository.dart';

class GreenPointsDashboardSheet extends StatefulWidget {
  const GreenPointsDashboardSheet({super.key});

  @override
  State<GreenPointsDashboardSheet> createState() =>
      _GreenPointsDashboardSheetState();
}

class _GreenPointsDashboardSheetState extends State<GreenPointsDashboardSheet> {
  final _db = FirebaseFirestore.instance;
  final _uid = FirebaseAuth.instance.currentUser?.uid;
  bool _loading = true;
  UserProfile? _profile;

  // Dữ liệu biểu đồ: key = tháng (1-12), value = {sell: X, buy: Y}
  final Map<int, _MonthData> _monthlyData = {};
  List<Map<String, dynamic>> _todayTransactions = [];
  int _totalEarned = 0;
  int _totalSpent = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_uid == null) return;

    try {
      // 1. Load user profile
      final userDoc = await _db.collection('users').doc(_uid).get();
      if (userDoc.exists) {
        _profile = UserProfile.fromFirestore(userDoc);
      }

      // 2. Load point transactions cho năm hiện tại
      final now = DateTime.now();
      final startOfYear = DateTime(now.year, 1, 1);
      final txSnap = await _db
          .collection('point_transactions')
          .where('userId', isEqualTo: _uid)
          .get(); 

      // Reset stats trước khi tính
      _totalEarned = 0;
      _totalSpent = 0;
      _monthlyData.clear();

      // Xử lý dữ liệu theo tháng
      for (final doc in txSnap.docs) {
        final data = doc.data();
        final ts = (data['timestamp'] as Timestamp?)?.toDate();
        if (ts == null) continue;
        
        // Chỉ lấy dữ liệu từ đầu năm nay
        if (ts.isBefore(startOfYear)) continue;

        final month = ts.month;
        final amount = (data['amount'] as num?)?.toInt() ?? 0;

        _monthlyData.putIfAbsent(month, () => _MonthData());

        if (amount > 0) {
          _monthlyData[month]!.earned += amount;
          _totalEarned += amount;
        } else {
          _monthlyData[month]!.spent += amount.abs();
          _totalSpent += amount.abs();
        }
      }

      // 3. Load giao dịch dự kiến
      final ordersSnap = await _db
          .collection('orders')
          .where('userId', isEqualTo: _uid)
          .where('status', whereIn: ['pending', 'accepted', 'collecting'])
          .get();

      _todayTransactions = ordersSnap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'wasteType': data['wasteType'] ?? '',
          'estimatedPrice': (data['totalPrice'] ?? data['estimatedPrice'] ?? 0) as num,
          'status': data['status'] ?? 'pending',
          'weight': (data['weight'] ?? 0).toDouble(),
        };
      }).toList();

      if (_profile?.isCollector == true) {
        final collectorOrders = await _db
            .collection('orders')
            .where('collectorId', isEqualTo: _uid)
            .where('status', isEqualTo: 'accepted')
            .get();

        for (final d in collectorOrders.docs) {
          final data = d.data();
          if (!_todayTransactions.any((t) => t['id'] == d.id)) {
            _todayTransactions.add({
              'id': d.id,
              'wasteType': data['wasteType'] ?? '',
              'estimatedPrice': (data['totalPrice'] ?? data['estimatedPrice'] ?? 0) as num,
              'status': 'collecting',
              'weight': (data['weight'] ?? 0).toDouble(),
              'isCollectorOrder': true,
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Dashboard Error: $e');
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: EcoColors.sheetHandle,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Icon(Icons.eco_rounded, color: EcoColors.primary, size: 28),
                SizedBox(width: 10),
                Text('Quản lý Điểm xanh',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_loading)
            const Expanded(
                child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                children: [
                  // ── Tổng quan điểm ──
                  _PointsSummaryCard(
                    currentPoints: _profile?.greenPoints ?? 0,
                    totalEarned: _totalEarned,
                    totalSpent: _totalSpent,
                  ),
                  const SizedBox(height: 20),

                  // ── Biểu đồ cột hàng tháng ──
                  _buildChartSection(),
                  const SizedBox(height: 20),

                  // ── Giao dịch dự kiến hôm nay ──
                  _buildTodaySection(),
                  const SizedBox(height: 20),

                  // ── Thống kê nhanh ──
                  _buildStatsSection(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    final now = DateTime.now();
    // Hiển thị 6 tháng gần nhất
    final months = List.generate(6, (i) {
      final m = now.month - 5 + i;
      return m <= 0 ? m + 12 : m;
    });

    final hasSpentData = _monthlyData.values.any((d) => d.spent > 0);
    final maxVal = _monthlyData.values.fold<int>(0, (prev, d) {
      final m = d.earned > d.spent ? d.earned : d.spent;
      return m > prev ? m : prev;
    });
    final chartMax = maxVal == 0 ? 100 : (maxVal * 1.2).toInt();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EcoColors.mintBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EcoColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  color: EcoColors.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Biểu đồ điểm theo tháng',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              ),
              // Legend
              _LegendDot(color: EcoColors.primary, label: 'Tích lũy'),
              if (hasSpentData) ...[
                const SizedBox(width: 12),
                _LegendDot(color: EcoColors.coral, label: 'Đã dùng'),
              ],
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: months.map((m) {
                final data = _monthlyData[m] ?? _MonthData();
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Earned bar
                        if (data.earned > 0)
                          Text('${data.earned}',
                              style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: EcoColors.primary)),
                        Flexible(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Earned column
                              Container(
                                width: hasSpentData ? 12 : 20,
                                height: chartMax > 0
                                    ? (data.earned / chartMax * 120)
                                        .clamp(2, 120)
                                        .toDouble()
                                    : 2,
                                decoration: BoxDecoration(
                                  color: EcoColors.primary,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4)),
                                ),
                              ),
                              if (hasSpentData) ...[
                                const SizedBox(width: 2),
                                // Spent column
                                Container(
                                  width: 12,
                                  height: chartMax > 0
                                      ? (data.spent / chartMax * 120)
                                          .clamp(2, 120)
                                          .toDouble()
                                      : 2,
                                  decoration: BoxDecoration(
                                    color: EcoColors.coral,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('T$m',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: EcoColors.bodyMuted)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EcoColors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.today_rounded, color: EcoColors.orange, size: 20),
              SizedBox(width: 8),
              Text('Giao dịch đang chờ',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 14),
          if (_todayTransactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: EcoColors.success, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Không có giao dịch đang chờ xử lý.',
                        style: TextStyle(
                            color: EcoColors.bodyMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                ],
              ),
            )
          else
            ...(_todayTransactions.map((tx) {
              final isCollectorOrder = tx['isCollectorOrder'] == true;
              final status = tx['status'] as String;
              final price = (tx['estimatedPrice'] as num).toInt();
              final expectedPoints = price ~/ 100;
              final statusLabel = switch (status) {
                'pending' => 'Chờ nhận',
                'accepted' => 'Đang thu gom',
                'collecting' => isCollectorOrder ? 'Bạn đang thu gom' : 'Đang thu gom',
                _ => status,
              };
              final statusColor = switch (status) {
                'pending' => EcoColors.orange,
                'accepted' => EcoColors.blue,
                'collecting' => EcoColors.primary,
                _ => EcoColors.bodyMuted,
              };

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isCollectorOrder
                            ? Icons.local_shipping_rounded
                            : Icons.recycling_rounded,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tx['wasteType'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(
                              '${tx['weight']}kg • +$expectedPoints điểm dự kiến',
                              style: const TextStyle(
                                  fontSize: 12, color: EcoColors.bodyMuted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(statusLabel,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              );
            })),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final completedOrders = _profile?.totalOrders ?? 0;
    final kgRecycled = _profile?.totalKgRecycled ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EcoColors.blue.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights_rounded, color: EcoColors.blue, size: 20),
              SizedBox(width: 8),
              Text('Thống kê hoạt động',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.shopping_cart_rounded,
                  label: 'Đơn hoàn tất',
                  value: '$completedOrders',
                  color: EcoColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.scale_rounded,
                  label: 'Kg tái chế',
                  value: kgRecycled.toStringAsFixed(1),
                  color: EcoColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Điểm tích lũy',
                  value: '$_totalEarned',
                  color: EcoColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Điểm đã dùng',
                  value: '$_totalSpent',
                  color: EcoColors.coral,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ──

class _PointsSummaryCard extends StatelessWidget {
  const _PointsSummaryCard({
    required this.currentPoints,
    required this.totalEarned,
    required this.totalSpent,
  });
  final int currentPoints;
  final int totalEarned;
  final int totalSpent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('Số dư hiện tại',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.eco_rounded, color: Colors.white, size: 30),
              const SizedBox(width: 10),
              Text('$currentPoints',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900)),
              const SizedBox(width: 6),
              const Text('điểm',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniStat(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Đã nhận',
                  value: '+$totalEarned'),
              Container(width: 1, height: 28, color: Colors.white24),
              _MiniStat(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Đã dùng',
                  value: '-$totalSpent'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: EcoColors.bodyMuted)),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: EcoColors.bodyMuted,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthData {
  int earned = 0;
  int spent = 0;
}
