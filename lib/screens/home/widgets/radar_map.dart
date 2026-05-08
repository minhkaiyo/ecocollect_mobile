import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/pickup_location.dart';
import '../../../models/user_profile.dart';
import '../../../models/order.dart';
import '../../../repositories/pickup_location_repository.dart';
import '../../../repositories/user_repository.dart';
import '../../../repositories/order_repository.dart';
import '../../../theme/eco_colors.dart';
import '../../../ui/app_feedback.dart';
import 'common_home_widgets.dart';
import 'manage_locations_sheet.dart';

class RadarMap extends StatefulWidget {
  const RadarMap({super.key, required this.height, this.focusNotifier});
  final double height;
  final ValueNotifier<LatLng?>? focusNotifier;

  @override
  State<RadarMap> createState() => _RadarMapState();
}

class _RadarMapState extends State<RadarMap> {
  LatLng? _currentPosition;
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStreamSubscription;
  UserProfile? _profile;
  String _filterType = 'all'; // 'all', 'pickup', 'collection'

  @override
  void initState() {
    super.initState();
    _setDefaultLocation();
    _initLocationUpdates();
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      UserRepository().getProfile(uid).then((p) {
        if (mounted && p != null && (p.isCollector || p.isAdmin)) {
          setState(() => _profile = p);
        }
      });
    }

    widget.focusNotifier?.addListener(_onFocusRequest);
  }

  void _onFocusRequest() {
    final loc = widget.focusNotifier?.value;
    if (loc != null && mounted) {
      _mapController.move(loc, 15.5);
    }
  }

  @override
  void dispose() {
    widget.focusNotifier?.removeListener(_onFocusRequest);
    _positionStreamSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initLocationUpdates() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _setDefaultLocation();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _setDefaultLocation();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _setDefaultLocation();
      return;
    }

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
      }
    });
  }

  void _setDefaultLocation() {
    if (mounted) {
      setState(() {
        _currentPosition = const LatLng(21.0285, 105.8542); // Hanoi default
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return EcoPanel(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: widget.height,
        child: Column(
          children: [
             Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: Row(
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Radar Thu Gom',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'Phạm vi 5km quanh bạn',
                        style: TextStyle(fontSize: 11, color: EcoColors.bodyMuted, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const Spacer(),
                  StreamBuilder<List<PickupLocation>>(
                    stream: PickupLocationRepository().watchAllLocations(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.length ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: EcoColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 8, color: EcoColors.success),
                            const SizedBox(width: 6),
                            Text(
                              '$count Online',
                              style: const TextStyle(
                                color: EcoColors.success,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Filter Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Tất cả',
                    isSelected: _filterType == 'all',
                    onTap: () => setState(() => _filterType = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Điểm thu mua',
                    icon: Icons.pedal_bike_rounded,
                    isSelected: _filterType == 'pickup',
                    onTap: () => setState(() => _filterType = 'pickup'),
                    color: EcoColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Điểm tập kết',
                    icon: Icons.warehouse_rounded,
                    isSelected: _filterType == 'collection',
                    onTap: () => setState(() => _filterType = 'collection'),
                    color: EcoColors.blue,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Row(
                children: [
                  const _LegendItem(color: EcoColors.primary, label: 'Bạn'),
                  const SizedBox(width: 16),
                  const _LegendItem(color: EcoColors.coral, label: 'Đơn hàng'),
                  const SizedBox(width: 16),
                  const _LegendItem(icon: Icons.pedal_bike_rounded, label: 'Thu mua'),
                  const SizedBox(width: 16),
                  _LegendItem(icon: Icons.warehouse_rounded, label: 'Tập kết', iconColor: EcoColors.blue),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(22),
                ),
                child: _currentPosition == null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: EcoColors.primary),
                            SizedBox(height: 16),
                            Text(
                              'Đang định vị vệ tinh...',
                              style: TextStyle(
                                color: EcoColors.bodyMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _currentPosition!,
                          initialZoom: 14.5,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.ecocollect.app',
                          ),
                          StreamBuilder<List<PickupLocation>>(
                            stream: PickupLocationRepository().watchAllLocations(),
                            builder: (context, snapshot) {
                              var locations = snapshot.data ?? [];
                              if (_filterType != 'all') {
                                locations = locations.where((l) => l.type == _filterType).toList();
                              }
                              
                              return StreamBuilder<List<EcoOrder>>(
                                stream: OrderRepository().watchPendingOrders(),
                                builder: (context, orderSnap) {
                                  final pendingOrders = orderSnap.data?.where((o) => o.location != null && o.location!.latitude != 0).toList() ?? [];
                                  
                                  return MarkerLayer(
                                    markers: [
                                      // User Position
                                      Marker(
                                        point: _currentPosition!,
                                        width: 80,
                                        height: 80,
                                        child: PulseMarker(color: EcoColors.primary),
                                      ),
                                      // Collection Points & Pickup Points
                                      ...locations.map(
                                        (loc) => Marker(
                                          point: LatLng(loc.geoPoint.latitude, loc.geoPoint.longitude),
                                          width: 50,
                                          height: 50,
                                          child: PulseMarker(
                                            color: loc.type == 'collection' ? EcoColors.blue : EcoColors.primary,
                                            child: CollectorPinLive(type: loc.type),
                                          ),
                                        ),
                                      ),
                                      // Pending Orders (RED DOTS)
                                      ...pendingOrders.map(
                                        (order) => Marker(
                                          point: LatLng(order.location?.latitude ?? 0, order.location?.longitude ?? 0),
                                          width: 50,
                                          height: 50,
                                          child: GestureDetector(
                                            onTap: () => _showOrderQuickView(order),
                                            child: const PulseMarker(
                                              color: EcoColors.coral,
                                              child: OrderMarkerIcon(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                              );
                            },
                          ),
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (_profile != null) ...[
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () {
                                        showModalBottomSheet<void>(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (_) => ManageLocationsSheet(profile: _profile!),
                                        );
                                      },
                                      child: const MapPill(
                                        icon: Icons.add_location_alt_rounded,
                                        text: 'Quản lý vị trí',
                                        color: EcoColors.orange,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () {
                                      if (_currentPosition != null) {
                                        _mapController.move(_currentPosition!, 15.0);
                                      }
                                    },
                                    child: const MapPill(
                                      icon: Icons.my_location_rounded,
                                      text: 'Vị trí của tôi',
                                      color: EcoColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderQuickView(EcoOrder order) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: EcoColors.coral.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('ĐƠN HÀNG RÁC', style: TextStyle(color: EcoColors.coral, fontWeight: FontWeight.w900, fontSize: 11)),
                ),
                Text(timeAgo(order.createdAt), style: const TextStyle(color: EcoColors.bodyMuted, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            Text(order.wasteType, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.scale_rounded, size: 18, color: EcoColors.bodyMuted),
                const SizedBox(width: 8),
                Text('${order.weight} kg', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_rounded, size: 18, color: EcoColors.coral),
                const SizedBox(width: 8),
                Expanded(child: Text(order.address ?? 'Địa chỉ đang tải...', style: const TextStyle(fontWeight: FontWeight.w600, color: EcoColors.textBody))),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _acceptOrder(order);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: EcoColors.coral,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('NHẬN ĐƠN NGAY', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptOrder(EcoOrder order) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator(color: EcoColors.coral)),
      );

      await OrderRepository().acceptOrder(
        orderId: order.id,
        collectorId: uid,
        collectorName: 'Collector ${uid.substring(0, 5)}',
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
        ecoSuccessTap();
        showEcoSnackBar(context, 'Đã nhận đơn thành công!', icon: Icons.check_circle_rounded);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        showEcoSnackBar(context, 'Lỗi: $e');
      }
    }
  }
}

class PulseMarker extends StatefulWidget {
  const PulseMarker({super.key, required this.color, this.child, this.pulseSize = 50.0});
  final Color color;
  final Widget? child;
  final double pulseSize;

  @override
  State<PulseMarker> createState() => _PulseMarkerState();
}

class _PulseMarkerState extends State<PulseMarker> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _floatController]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse
            Container(
              width: widget.pulseSize * _pulseController.value,
              height: widget.pulseSize * _pulseController.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(0.3 * (1 - _pulseController.value)),
              ),
            ),
            // Middle pulse
            Container(
              width: (widget.pulseSize * 0.7) * _pulseController.value,
              height: (widget.pulseSize * 0.7) * _pulseController.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(0.15 * (1 - _pulseController.value)),
              ),
            ),
            // Floating Child
            Transform.translate(
              offset: Offset(0, -4 * _floatController.value),
              child: widget.child ?? Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class OrderMarkerIcon extends StatelessWidget {
  const OrderMarkerIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: EcoColors.coral,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(Icons.auto_delete_rounded, color: Colors.white, size: 14),
    );
  }
}

String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  return '${diff.inDays} ngày trước';
}

class CollectorPinLive extends StatelessWidget {
  const CollectorPinLive({super.key, this.type = 'pickup'});
  final String type;

  @override
  Widget build(BuildContext context) {
    final isCollection = type == 'collection';
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isCollection ? EcoColors.blue : EcoColors.primary).withOpacity(.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isCollection ? EcoColors.blue : EcoColors.primary,
          width: 2,
        ),
      ),
      child: Icon(
        isCollection ? Icons.warehouse_rounded : Icons.pedal_bike_rounded,
        color: isCollection ? EcoColors.blue : EcoColors.primary,
        size: 20,
      ),
    );
  }
}

class MapPill extends StatelessWidget {
  const MapPill({super.key, required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({this.icon, this.color, required this.label, this.iconColor});
  final IconData? icon;
  final Color? color;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) Icon(icon, size: 14, color: iconColor ?? EcoColors.primary)
        else Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: EcoColors.bodyMuted, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
    this.color,
  });
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? EcoColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : EcoColors.border,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: activeColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : EcoColors.iconMuted),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: isSelected ? Colors.white : EcoColors.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
