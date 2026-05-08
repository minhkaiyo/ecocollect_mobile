import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/waste_type.dart';
import '../../../theme/eco_colors.dart';
import '../../../utils/formatters.dart';
import 'location_picker_sheet.dart';

class OrderSheet extends StatefulWidget {
  const OrderSheet({
    super.key,
    required this.selectedWaste,
    required this.weight,
    required this.total,
    required this.onSubmitted,
  });

  final WasteType selectedWaste;
  final double weight;
  final int total;
  final Function(LatLng location, String address) onSubmitted;

  @override
  State<OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends State<OrderSheet> {
  bool _receiveGreenPoints = true;
  XFile? _wastePhoto;
  final _picker = ImagePicker();
  
  LatLng? _pickedLocation;
  String _address = 'Chưa chọn vị trí';

  bool get _showLegacyPhotoPicker => false;

  Future<void> _pickWastePhoto(ImageSource source) async {
    try {
      final photo = await _picker.pickImage(source: source, imageQuality: 75);
      if (!mounted || photo == null) return;
      setState(() => _wastePhoto = photo);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Khong the mo camera hoac chon anh.')),
      );
    }
  }

  Future<void> _choosePhotoSource() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: EcoColors.sheetHandle,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: EcoColors.primary),
                  title: const Text('Chup anh'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickWastePhoto(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: EcoColors.blue),
                  title: const Text('Chon tu thu vien'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickWastePhoto(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: .78,
      maxChildSize: .92,
      minChildSize: .45,
      builder: (context, controller) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: EcoColors.sheetHandle,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Xác nhận đơn thu gom',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ConfirmChip(
                    icon: widget.selectedWaste.icon,
                    label: widget.selectedWaste.name,
                  ),
                  _ConfirmChip(
                    icon: Icons.scale_rounded,
                    label: '${widget.weight.toStringAsFixed(0)} kg',
                  ),
                  _ConfirmChip(
                    icon: Icons.payments_rounded,
                    label: '${formatVnd(widget.total)} đ',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _WastePhotoPicker(
                photo: _wastePhoto,
                onPick: _choosePhotoSource,
                onClear: () => setState(() => _wastePhoto = null),
              ),
              if (_showLegacyPhotoPicker) const SizedBox.shrink(),
              if (_showLegacyPhotoPicker) Material(
                color: EcoColors.surfaceMuted,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mở camera chụp đống rác (demo). Ảnh sẽ đính kèm đơn khi tích hợp thiết bị.'),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 142,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: EcoColors.sheetHandle),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_rounded,
                          size: 44,
                          color: EcoColors.primary,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Chụp ảnh đống rác',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Chạm để thử luồng chụp (demo)',
                          style: TextStyle(color: EcoColors.bodyMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Địa điểm thu gom',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Material(
                color: EcoColors.mintBg,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => LocationPickerSheet(
                        initialLocation: _pickedLocation,
                        onLocationSelected: (loc, addr) {
                          setState(() {
                            _pickedLocation = loc;
                            _address = addr;
                          });
                        },
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: EcoColors.coral),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _address,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: EcoColors.primary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _pickedLocation == null
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        widget.onSubmitted(_pickedLocation!, _address);
                      },
                icon: const Icon(Icons.send_rounded),
                label: const Text('XÁC NHẬN & ĐĂNG ĐƠN HÀNG'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: EcoColors.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WastePhotoPicker extends StatelessWidget {
  const _WastePhotoPicker({
    required this.photo,
    required this.onPick,
    required this.onClear,
  });

  final XFile? photo;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: EcoColors.surfaceMuted,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 142,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: EcoColors.sheetHandle),
          ),
          child: photo == null ? _emptyState() : _preview(),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt_rounded, size: 44, color: EcoColors.primary),
        SizedBox(height: 8),
        Text('Chup anh dong rac', style: TextStyle(fontWeight: FontWeight.w900)),
        Text('Chup moi hoac chon anh co san', style: TextStyle(color: EcoColors.bodyMuted)),
      ],
    );
  }

  Widget _preview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: FutureBuilder<Uint8List>(
            future: photo!.readAsBytes(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: EcoColors.primary),
                );
              }
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, size: 40),
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton.filled(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded, size: 18),
            style: IconButton.styleFrom(backgroundColor: Colors.black54),
          ),
        ),
        const Positioned(
          left: 12,
          bottom: 10,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                'Cham de doi anh',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfirmChip extends StatelessWidget {
  const _ConfirmChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, color: EcoColors.primary),
      label: Text(label),
      labelStyle: const TextStyle(fontWeight: FontWeight.w800),
      backgroundColor: EcoColors.mintBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
