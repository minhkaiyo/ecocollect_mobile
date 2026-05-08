import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../theme/eco_colors.dart';
import '../../../ui/app_feedback.dart';

class LocationPickerSheet extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng, String) onLocationSelected;

  const LocationPickerSheet({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  LatLng? _pickedLocation;
  final MapController _mapController = MapController();
  bool _isLocating = true;
  String _addressDisplay = 'Đang xác định vị trí...';

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation;
    if (_pickedLocation == null) {
      _determinePosition();
    } else {
      _isLocating = false;
      _addressDisplay = 'Vị trí đã chọn trên bản đồ';
    }
  }

  Future<void> _determinePosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _pickedLocation = LatLng(pos.latitude, pos.longitude);
          _isLocating = false;
          _addressDisplay = 'Vị trí hiện tại của bạn';
        });
        _mapController.move(_pickedLocation!, 16);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pickedLocation = const LatLng(21.0285, 105.8542); // Hanoi default
          _isLocating = false;
          _addressDisplay = 'Không thể lấy vị trí, vui lòng chọn thủ công';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: EcoColors.mintBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.map_rounded, color: EcoColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chọn địa điểm thu gom',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: EcoColors.textBody,
                        ),
                      ),
                      Text(
                        _addressDisplay,
                        style: const TextStyle(
                          fontSize: 14,
                          color: EcoColors.bodyMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _pickedLocation ?? const LatLng(21.0285, 105.8542),
                      initialZoom: 16,
                      onTap: (_, latLng) {
                        setState(() {
                          _pickedLocation = latLng;
                          _addressDisplay = 'Vị trí đã ghim';
                        });
                        ecoLightTap();
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      if (_pickedLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _pickedLocation!,
                              width: 60,
                              height: 60,
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: EcoColors.coral,
                                size: 48,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (_isLocating)
                    Container(
                      color: Colors.white60,
                      child: const Center(
                        child: CircularProgressIndicator(color: EcoColors.primary),
                      ),
                    ),
                  Positioned(
                    bottom: 24,
                    right: 24,
                    child: FloatingActionButton(
                      onPressed: _determinePosition,
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.my_location_rounded, color: EcoColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: FilledButton(
                onPressed: _pickedLocation == null
                    ? null
                    : () {
                        widget.onLocationSelected(_pickedLocation!, _addressDisplay);
                        Navigator.pop(context);
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: EcoColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: const Text(
                  'XÁC NHẬN VỊ TRÍ NÀY',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
