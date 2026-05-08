import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/order.dart';
import '../../../repositories/order_repository.dart';
import '../../../theme/eco_colors.dart';
import '../../../utils/formatters.dart';
import '../../../ui/app_feedback.dart';
import 'package:url_launcher/url_launcher.dart';

class CollectorDashboardSheet extends StatefulWidget {
  const CollectorDashboardSheet({super.key, this.onOrderFocus});
  final void Function(LatLng)? onOrderFocus;

  @override
  State<CollectorDashboardSheet> createState() => _CollectorDashboardSheetState();
}

class _CollectorDashboardSheetState extends State<CollectorDashboardSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _orderRepo = OrderRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        children: [
          Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: EcoColors.sheetHandle, borderRadius: BorderRadius.circular(999)))),
          const SizedBox(height: 12),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<num>(
                  stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots().map((s) => s.data()?['greenPoints'] ?? 0),
                  builder: (context, snap) {
                    final points = snap.data ?? 0;
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(color: EcoColors.mintBg, borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              const Icon(Icons.eco_rounded, color: EcoColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text('$points điểm', style: const TextStyle(color: EcoColors.primary, fontWeight: FontWeight.w900, fontSize: 14)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: () {
                            FirebaseFirestore.instance.collection('users').doc(uid).update({
                              'greenPoints': FieldValue.increment(1000),
                            });
                            ecoSuccessTap();
                          },
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: EcoColors.primary.withOpacity(0.1),
                            foregroundColor: EcoColors.primary,
                          ),
                        ),
                      ],
                    );
                  }
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            labelColor: EcoColors.primary,
            unselectedLabelColor: EcoColors.bodyMuted,
            indicatorColor: EcoColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            tabs: const [Tab(text: 'Yêu cầu mới'), Tab(text: 'Việc của tôi')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AvailableOrdersList(
                  orderRepo: _orderRepo,
                  currentUid: uid,
                  onOrderFocus: widget.onOrderFocus,
                ),
                _AcceptedOrdersList(
                  orderRepo: _orderRepo,
                  currentUid: uid,
                  onOrderFocus: widget.onOrderFocus,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailableOrdersList extends StatelessWidget {
  const _AvailableOrdersList({
    required this.orderRepo,
    required this.currentUid,
    this.onOrderFocus,
  });
  final OrderRepository orderRepo;
  final String currentUid;
  final void Function(LatLng)? onOrderFocus;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EcoOrder>>(
      stream: orderRepo.watchPendingOrders(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final orders = snapshot.data!;
        if (orders.isEmpty) return const _EmptyState(msg: 'Chưa có yêu cầu thu gom nào mới.');

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 20),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _OrderCard(
              order: order,
              onAccept: () => _acceptOrder(context, order),
              onTap: () {
                if (order.location != null) {
                  onOrderFocus?.call(LatLng(
                      order.location!.latitude, order.location!.longitude));
                }
              },
            );
          },
        );
      },
    );
  }

  Future<void> _acceptOrder(BuildContext context, EcoOrder order) async {
    try {
      await orderRepo.acceptOrder(
        orderId: order.id,
        collectorId: currentUid,
        collectorName: 'Collector $currentUid', // Mock name
      );
      if (context.mounted) showEcoSnackBar(context, 'Đã nhận đơn! Hãy đến địa chỉ người bán.', icon: Icons.local_shipping_rounded);
    } catch (e) {
      if (context.mounted) showEcoSnackBar(context, 'Lỗi: $e');
    }
  }
}

class _AcceptedOrdersList extends StatelessWidget {
  const _AcceptedOrdersList({
    required this.orderRepo,
    required this.currentUid,
    this.onOrderFocus,
  });
  final OrderRepository orderRepo;
  final String currentUid;
  final void Function(LatLng)? onOrderFocus;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EcoOrder>>(
      stream: orderRepo.watchCollectorOrders(currentUid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final orders = snapshot.data!;
        if (orders.isEmpty) return const _EmptyState(msg: 'Bạn chưa nhận đơn hàng nào.');

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 20),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final earnedPoints = order.estimatedPrice ~/ 100;
            return _OrderCard(
              order: order,
              isMyTask: true,
              onTap: () {
                if (order.location != null) {
                  onOrderFocus?.call(LatLng(
                      order.location!.latitude, order.location!.longitude));
                }
              },
              onComplete: () async {
                debugPrint('🚀 Starting completeOrder for ${order.id}');
                try {
                  await orderRepo.completeOrder(order.id,
                      earnedPoints: earnedPoints);
                  debugPrint('✅ completeOrder success');
                  if (context.mounted) {
                    ecoSuccessTap();
                    showEcoSnackBar(context,
                        'Đã thanh toán $earnedPoints điểm và hoàn tất đơn hàng!',
                        icon: Icons.check_circle_rounded);
                  }
                } catch (e, stack) {
                  debugPrint('❌ completeOrder failed: $e');
                  debugPrint('Stack: $stack');
                  if (context.mounted) {
                    showEcoSnackBar(context, 'Lỗi: $e',
                        icon: Icons.error_outline);
                  }
                }
              },
            );
          },
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    this.onAccept,
    this.onComplete,
    this.onTap,
    this.isMyTask = false,
  });
  final EcoOrder order;
  final VoidCallback? onAccept;
  final VoidCallback? onComplete;
  final VoidCallback? onTap;
  final bool isMyTask;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: EcoColors.mintBg.withOpacity(0.3),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: EcoColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: EcoColors.primary, borderRadius: BorderRadius.circular(8)),
                    child: Text(order.wasteType, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                  ),
                  Text(formatVnd(order.estimatedPrice), style: const TextStyle(fontWeight: FontWeight.w900, color: EcoColors.primary, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.scale_rounded, size: 16, color: EcoColors.bodyMuted),
                  const SizedBox(width: 6),
                  Text('${order.weight} kg', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time_rounded, size: 16, color: EcoColors.bodyMuted),
                  const SizedBox(width: 6),
                  Text(timeAgo(order.createdAt), style: const TextStyle(fontSize: 12, color: EcoColors.bodyMuted)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded, size: 16, color: EcoColors.coral),
                  const SizedBox(width: 6),
                  Expanded(child: Text(order.address ?? 'Địa chỉ chưa xác định', style: const TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w600))),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: isMyTask ? onComplete : onAccept,
                      style: FilledButton.styleFrom(
                        backgroundColor: isMyTask ? EcoColors.primary : EcoColors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        isMyTask ? 'HOÀN TẤT THU GOM' : 'NHẬN ĐƠN NÀY',
                        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
                  ),
                  if (order.location != null) ...[
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () async {
                        final lat = order.location!.latitude;
                        final lng = order.location!.longitude;
                        final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.directions_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: EcoColors.primary.withOpacity(0.1),
                        foregroundColor: EcoColors.primary,
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.msg});
  final String msg;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_rounded, size: 64, color: EcoColors.surfaceMuted),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: EcoColors.bodyMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  return '${diff.inDays} ngày trước';
}
