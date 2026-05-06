import 'package:latlong2/latlong.dart';
import '../repositories/geocoding_repository.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:geolocator/geolocator.dart';
import '../theme/eco_colors.dart';
import '../ui/app_feedback.dart';

class SchedulePickupSheet extends StatefulWidget {
  const SchedulePickupSheet({super.key});

  @override
  State<SchedulePickupSheet> createState() => _SchedulePickupSheetState();
}

class _SchedulePickupSheetState extends State<SchedulePickupSheet> {
  final List<String> wasteTypes = ['Nhựa', 'Giấy', 'Kim loại', 'Đồ điện tử', 'Cồng kềnh', 'Khác'];
  String? _selectedWasteType;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  XFile? _imageFile;
  bool _isLoading = false;
  LatLng? _location;

  @override
  void initState() {
    super.initState();
    _selectedWasteType = wasteTypes.first;
    if (!kIsWeb) _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;
      
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _location = LatLng(pos.latitude, pos.longitude);
      });
    } catch (_) {}
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: EcoColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      showEcoSnackBar(context, 'Vui lòng đăng nhập để đặt lịch.', icon: Icons.lock_outline);
      return;
    }

    final date = _dateController.text;
    final address = _addressController.text;
    final phone = _phoneController.text;

    if (date.isEmpty || address.isEmpty || phone.isEmpty) {
      showEcoSnackBar(context, 'Vui lòng điền đủ ngày, địa chỉ và SĐT.', icon: Icons.error_outline);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('pickup_schedules').add({
        'userId': uid,
        'wasteType': _selectedWasteType,
        'scheduledDate': date,
        'address': address,
        'phone': phone,
        'description': _descriptionController.text,
        'imageUrl': null,
        'location': _location != null ? GeoPoint(_location!.latitude, _location!.longitude) : null,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        showEcoSnackBar(context, 'Đã đặt lịch thu gom thành công!', icon: Icons.check_circle_rounded);
      }
    } catch (e) {
      if (mounted) {
        showEcoSnackBar(context, 'Lỗi đặt lịch: $e', icon: Icons.error_outline);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Đăng ký thu gom định kỳ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: EcoColors.textBody,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: EcoColors.iconMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDropdown(),
              const SizedBox(height: 16),
              _buildTextField('Ngày thu gom', 'VD: 25/12/2026', Icons.calendar_today_rounded, _dateController, readOnly: true, onTap: _selectDate),
              const SizedBox(height: 16),
              _buildTextField('Địa chỉ', 'Nhập địa chỉ của bạn', Icons.location_on_outlined, _addressController),
              const SizedBox(height: 16),
              _buildTextField('Số điện thoại', 'Nhập SĐT liên hệ', Icons.phone_outlined, _phoneController, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField('Ghi chú thêm', 'Mô tả thêm về rác...', Icons.description_outlined, _descriptionController, maxLines: 2),
              const SizedBox(height: 16),
              _buildImagePicker(),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: EcoColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('XÁC NHẬN ĐẶT LỊCH', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedWasteType,
      decoration: InputDecoration(
        labelText: 'Loại rác chính',
        filled: true,
        fillColor: EcoColors.inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        prefixIcon: const Icon(Icons.delete_outline_rounded, color: EcoColors.iconMuted),
      ),
      items: wasteTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: (val) => setState(() => _selectedWasteType = val),
    );
  }

  Widget _buildTextField(String label, String hint, IconData icon, TextEditingController controller, {bool readOnly = false, VoidCallback? onTap, TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: EcoColors.inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        prefixIcon: Icon(icon, color: EcoColors.iconMuted),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ảnh chụp (Không bắt buộc)', style: TextStyle(fontWeight: FontWeight.w600, color: EcoColors.bodyMuted)),
        const SizedBox(height: 8),
        if (_imageFile != null)
          Stack(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: EcoColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(_imageFile!.path, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 32))),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  onPressed: () => setState(() => _imageFile = null),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickImage(ImageSource.camera),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: EcoColors.inputFill,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: EcoColors.border),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, color: EcoColors.primary, size: 28),
                        SizedBox(height: 4),
                        Text('Chụp ảnh', style: TextStyle(color: EcoColors.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _pickImage(ImageSource.gallery),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: EcoColors.inputFill,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: EcoColors.border),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_outlined, color: EcoColors.blue, size: 28),
                        SizedBox(height: 4),
                        Text('Thư viện', style: TextStyle(color: EcoColors.blue, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
