import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../theme/eco_colors.dart';
import 'common_home_widgets.dart';

class RadarMap extends StatefulWidget {
  const RadarMap({super.key, required this.height});
  final double height;

  @override
  State<RadarMap> createState() => _RadarMapState();
}

class _RadarMapState extends State<RadarMap> {
  LatLng? _currentPosition;
  final MapController _mapController = MapController();
  List<LatLng> _collectors = [];
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _setDefaultLocation();
    _initLocationUpdates();
  }

  @override
  void dispose() {
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
          _generateMockCollectors();
        });
      }
    });
  }

  void _setDefaultLocation() {
    if (mounted) {
      setState(() {
        _currentPosition = const LatLng(21.0285, 105.8542); // Hanoi default
        _generateMockCollectors();
      });
    }
  }

  void _generateMockCollectors() {
    if (_currentPosition == null) return;
    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;
    _collectors = [
      LatLng(lat + 0.005, lng + 0.002),
      LatLng(lat - 0.003, lng - 0.004),
      LatLng(lat + 0.002, lng - 0.006),
      LatLng(lat - 0.007, lng + 0.003),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return EcoPanel(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: widget.height,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 14, 14, 8),
              child: Row(
                children: [
                  Text(
                    'Radar Tìm Người Thu Gom',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  Spacer(),
                  Icon(Icons.circle, size: 9, color: EcoColors.success),
                  SizedBox(width: 6),
                  Text(
                    'Live',
                    style: TextStyle(
                      color: EcoColors.bodyMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _currentPosition!,
                                width: 100,
                                height: 100,
                                child: const _UserPulseMarker(),
                              ),
                              ..._collectors.map(
                                (pos) => Marker(
                                  point: pos,
                                  width: 40,
                                  height: 40,
                                  child: const CollectorPinLive(),
                                ),
                              ),
                            ],
                          ),
                          const Positioned(
                            right: 16,
                            bottom: 16,
                            child: MapPill(
                              icon: Icons.place_rounded,
                              text: 'Trạm tập kết',
                              color: EcoColors.primary,
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
}

class _UserPulseMarker extends StatelessWidget {
  const _UserPulseMarker();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.5, end: 1),
        duration: const Duration(seconds: 2),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100 * value,
                height: 100 * value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EcoColors.primary.withOpacity(0.2 * (1 - value)),
                ),
              ),
              child!,
            ],
          );
        },
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: EcoColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CollectorPinLive extends StatelessWidget {
  const CollectorPinLive({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.12),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Icon(
        Icons.pedal_bike_rounded,
        color: EcoColors.primary,
        size: 24,
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
