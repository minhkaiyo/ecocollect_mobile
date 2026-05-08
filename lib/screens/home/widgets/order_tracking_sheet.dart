import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/order.dart';
import '../../../repositories/order_repository.dart';
import '../../../theme/eco_colors.dart';
import '../../../utils/formatters.dart';
import '../../../ui/app_feedback.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderTrackingSheet extends StatefulWidget {
  const OrderTrackingSheet({super.key, this.onOrderFocus});
  final Function(LatLng)? onOrderFocus;

  @override
  State<OrderTrackingSheet> createState() => _OrderTrackingSheetState();
}

class _OrderTrackingSheetState extends State<OrderTrackingSheet> {
  final _orderRepo = OrderRepository();
  Position? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showEcoSnackBar(context, 'Lỗi định vị: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  double _calculateDistance(double lat, double lng) {
    if (_currentPosition == null) return 0;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: EcoColors.sheetHandle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: EcoColors.coral.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.track_changes_rounded, color: EcoColors.coral),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Truy vết đơn hàng',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Tìm đơn rác gần bạn nhất',
                      style: TextStyle(fontSize: 12, color: EcoColors.bodyMuted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: EcoColors.iconMuted),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: EcoColors.coral))
              : StreamBuilder<List<EcoOrder>>(
                  stream: _orderRepo.watchPendingOrders(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    
                    final orders = snapshot.data!;
                    if (orders.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.radar_rounded, size: 64, color: EcoColors.surfaceMuted),
                            SizedBox(height: 16),
                            Text('Không tìm thấy đơn hàng nào gần đây', style: TextStyle(color: EcoColors.bodyMuted, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      );
                    }

                    // Sort by distance
                    final sortedOrders = orders.toList();
                    sortedOrders.sort((a, b) {
                      final distA = _calculateDistance(a.location?.latitude ?? 0, a.location?.longitude ?? 0);
                      final distB = _calculateDistance(b.location?.latitude ?? 0, b.location?.longitude ?? 0);
                      return distA.compareTo(distB);
                    });

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: sortedOrders.length,
                      itemBuilder: (context, index) {
                        final order = sortedOrders[index];
                        final distance = _calculateDistance(order.location?.latitude ?? 0, order.location?.longitude ?? 0);
                        
                        return InkWell(
                          onTap: () {
                            if (order.location != null) {
                              final loc = LatLng(order.location!.latitude, order.location!.longitude);
                              Navigator.pop(context);
                              widget.onOrderFocus?.call(loc);
                            }
                          },
                          child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: EcoColors.coral.withOpacity(0.1)),
                            boxShadow: [
                              BoxShadow(
                                color: EcoColors.coral.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: EcoColors.coral.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.auto_delete_rounded, color: EcoColors.coral),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.wasteType,
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      order.address ?? 'Địa chỉ đang xác định',
                                      style: const TextStyle(fontSize: 12, color: EcoColors.bodyMuted, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.near_me_rounded, size: 12, color: EcoColors.coral),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${(distance / 1000).toStringAsFixed(2)} km',
                                          style: const TextStyle(color: EcoColors.coral, fontWeight: FontWeight.w900, fontSize: 12),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.scale_rounded, size: 12, color: EcoColors.bodyMuted),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${order.weight} kg',
                                          style: const TextStyle(color: EcoColors.bodyMuted, fontWeight: FontWeight.w700, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (order.location != null)
                                IconButton(
                                  onPressed: () async {
                                    final lat = order.location!.latitude;
                                    final lng = order.location!.longitude;
                                    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  icon: const Icon(Icons.directions_rounded, size: 22, color: EcoColors.coral),
                                  style: IconButton.styleFrom(
                                    backgroundColor: EcoColors.coral.withOpacity(0.05),
                                  ),
                                ),
                              const SizedBox(width: 4),
                              IconButton(
                                onPressed: () => _acceptOrder(context, order),
                                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: EcoColors.coral),
                                style: IconButton.styleFrom(
                                  backgroundColor: EcoColors.coral.withOpacity(0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptOrder(BuildContext context, EcoOrder order) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator(color: EcoColors.coral)),
      );

      await _orderRepo.acceptOrder(
        orderId: order.id,
        collectorId: uid,
        collectorName: 'Collector ${uid.substring(0, 5)}',
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Close sheet
        ecoSuccessTap();
        showEcoSnackBar(context, 'Đã nhận đơn! Hãy di chuyển đến địa chỉ người bán.', icon: Icons.local_shipping_rounded);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        showEcoSnackBar(context, 'Lỗi: $e');
      }
    }
  }
}
