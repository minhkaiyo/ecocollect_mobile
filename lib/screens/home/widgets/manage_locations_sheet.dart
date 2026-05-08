import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/subscription_sheet.dart';

import '../../../models/pickup_location.dart';
import '../../../models/user_profile.dart';
import '../../../repositories/geocoding_repository.dart';
import '../../../repositories/pickup_location_repository.dart';
import '../../../theme/eco_colors.dart';
import '../../../ui/app_feedback.dart';

class ManageLocationsSheet extends StatefulWidget {
  const ManageLocationsSheet({super.key, required this.profile});
  final UserProfile profile;

  @override
  State<ManageLocationsSheet> createState() => _ManageLocationsSheetState();
}

class _ManageLocationsSheetState extends State<ManageLocationsSheet> {
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: _isAdding ? _buildAddForm() : _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Text(
              widget.profile.isAdmin ? 'Quản lý toàn bộ vị trí' : 'Vị trí của bạn',
              style: const TextStyle(
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
        const SizedBox(height: 8),
        if (!widget.profile.isAdmin)
          StreamBuilder<List<PickupLocation>>(
            stream: PickupLocationRepository().watchOwnerLocations(widget.profile.uid),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return Text(
                'Đã dùng $count / ${widget.profile.maxPickupLocations} vị trí',
                style: const TextStyle(color: EcoColors.bodyMuted, fontWeight: FontWeight.w600),
              );
            },
          ),
        const SizedBox(height: 12),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: EcoColors.inputFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: EcoColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: EcoColors.bodyMuted,
            labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            tabs: const [
              Tab(text: 'THU GOM'),
              Tab(text: 'TẬP KẾT'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Flexible(
          child: SizedBox(
            height: 350,
            child: TabBarView(
              children: [
                _LocationList(profile: widget.profile, type: 'pickup'),
                _LocationList(profile: widget.profile, type: 'collection'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => setState(() => _isAdding = true),
          icon: const Icon(Icons.add_location_alt_rounded),
          label: const Text('THÊM VỊ TRÍ MỚI', style: TextStyle(fontWeight: FontWeight.w800)),
          style: FilledButton.styleFrom(
            backgroundColor: EcoColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildAddForm() {
    return _AddLocationForm(
      profile: widget.profile,
      onCancel: () => setState(() => _isAdding = false),
      onAdded: () => setState(() => _isAdding = false),
    );
  }
}

class _LocationList extends StatelessWidget {
  const _LocationList({required this.profile, required this.type});
  final UserProfile profile;
  final String type;

  @override
  Widget build(BuildContext context) {
    final repo = PickupLocationRepository();
    final stream = profile.isAdmin 
        ? repo.watchAllLocationsByType(type)
        : repo.watchOwnerLocations(profile.uid).map((list) => list.where((l) => l.type == type).toList());

    return StreamBuilder<List<PickupLocation>>(
      stream: stream,
      builder: (context, snapshot) {
        final locs = snapshot.data ?? [];
        if (locs.isEmpty) {
          return Center(
            child: Text(
              'Chưa có điểm ${type == 'pickup' ? 'thu gom' : 'tập kết'} nào.',
              style: const TextStyle(color: EcoColors.bodyMuted),
            ),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: locs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final loc = locs[index];
            final canDelete = profile.isAdmin || loc.ownerId == profile.uid;
            
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: loc.type == 'collection' ? EcoColors.blue.withOpacity(0.1) : EcoColors.mintBg,
                child: Icon(
                  loc.type == 'collection' ? Icons.warehouse_rounded : Icons.location_on_rounded, 
                  color: loc.type == 'collection' ? EcoColors.blue : EcoColors.primary,
                ),
              ),
              title: Text(loc.label, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (profile.isAdmin)
                    Text('Chủ: ${loc.ownerName ?? 'Ẩn danh'}', style: const TextStyle(fontSize: 10, color: EcoColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              trailing: canDelete ? IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: EcoColors.orange),
                onPressed: () => _confirmDelete(context, loc),
              ) : null,
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, PickupLocation loc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Bạn có chắc muốn xóa điểm "${loc.label}" ${profile.isAdmin ? "của ${loc.ownerName}" : ""}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('HỦY')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await PickupLocationRepository().db.collection('pickup_locations').doc(loc.id).delete();
                if (context.mounted) showEcoSnackBar(context, 'Đã xóa vị trí thành công.');
              } catch (e) {
                if (context.mounted) showEcoSnackBar(context, 'Lỗi xóa vị trí: $e');
              }
            },
            child: const Text('XÓA', style: TextStyle(color: EcoColors.orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _AddLocationForm extends StatefulWidget {
  const _AddLocationForm({required this.profile, required this.onCancel, required this.onAdded});
  final UserProfile profile;
  final VoidCallback onCancel;
  final VoidCallback onAdded;

  @override
  State<_AddLocationForm> createState() => _AddLocationFormState();
}

class _AddLocationFormState extends State<_AddLocationForm> {
  final _labelController = TextEditingController(text: 'Điểm thu mua');
  final _searchController = TextEditingController();
  final _mapController = MapController();
  
  List<GeocodingSuggestion> _suggestions = [];
  bool _isSearching = false;
  Timer? _debounce;
   LatLng _selectedPos = const LatLng(21.0285, 105.8542);
  bool _isLoading = false;
  String _selectedType = 'pickup'; // 'pickup' hoặc 'collection'

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      setState(() => _isSearching = true);
      final res = await GeocodingRepository().searchVietnam(query);
      if (mounted) {
        setState(() {
          _suggestions = res;
          _isSearching = false;
        });
      }
    });
  }

  void _selectSuggestion(GeocodingSuggestion s) {
    setState(() {
      _selectedPos = s.latLng;
      _searchController.text = s.address;
      _suggestions = [];
      _mapController.move(s.latLng, 16);
    });
  }

  Future<void> _submit() async {
    final address = _searchController.text.trim();
    final label = _labelController.text.trim();
    if (address.isEmpty || label.isEmpty) {
      showEcoSnackBar(context, 'Vui lòng điền đủ thông tin.', icon: Icons.error_outline);
      return;
    }

    setState(() => _isLoading = true);
    try {
       await PickupLocationRepository().addLocation(
        ownerId: widget.profile.uid,
        ownerName: widget.profile.displayName,
        label: label,
        address: address,
        lat: _selectedPos.latitude,
        lng: _selectedPos.longitude,
        maxLocations: widget.profile.isAdmin ? 9999 : widget.profile.maxPickupLocations,
        type: _selectedType,
      );
      if (mounted) widget.onAdded();
    } catch (e) {
      if (mounted) showEcoSnackBar(context, e.toString().replaceAll('Exception: ', ''), icon: Icons.error_outline);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _labelController.dispose();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thêm Vị Trí Mới',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: EcoColors.iconMuted),
                onPressed: widget.onCancel,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _labelController,
            decoration: InputDecoration(
              labelText: 'Tên gợi nhớ (VD: Kho chính)',
              filled: true,
              fillColor: EcoColors.inputFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          if (widget.profile.isAdmin) ...[
            const SizedBox(height: 16),
            const Text('Loại địa điểm:', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedType = 'pickup'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedType == 'pickup' ? EcoColors.primary : EcoColors.inputFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.location_on_rounded, color: _selectedType == 'pickup' ? Colors.white : EcoColors.iconMuted),
                          const SizedBox(height: 4),
                          Text('ĐIỂM THU MUA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _selectedType == 'pickup' ? Colors.white : EcoColors.bodyMuted)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedType = 'collection'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedType == 'collection' ? EcoColors.blue : EcoColors.inputFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.warehouse_rounded, color: _selectedType == 'collection' ? Colors.white : EcoColors.iconMuted),
                          const SizedBox(height: 4),
                          Text('ĐIỂM TẬP KẾT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _selectedType == 'collection' ? Colors.white : EcoColors.bodyMuted)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              labelText: 'Tìm kiếm địa chỉ',
              filled: true,
              fillColor: EcoColors.inputFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.search_rounded, color: EcoColors.iconMuted),
              suffixIcon: _isSearching ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)) : null,
            ),
          ),
          if (_suggestions.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: EcoColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final s = _suggestions[i];
                  return ListTile(
                    dense: true,
                    title: Text(s.address, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () => _selectSuggestion(s),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          const Text('Hoặc ghim trên bản đồ:', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          // Hiển thị tọa độ đang chọn
          Text(
            'Đã chọn: ${_selectedPos.latitude.toStringAsFixed(5)}, ${_selectedPos.longitude.toStringAsFixed(5)}',
            style: const TextStyle(fontSize: 12, color: EcoColors.bodyMuted),
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: EcoColors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selectedPos,
                      initialZoom: 15,
                      onPositionChanged: (pos, hasGesture) {
                        // Update luôn khi map di chuyển (dù có gesture hay không)
                        setState(() => _selectedPos = pos.center);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.ecocollect.app',
                      ),
                    ],
                  ),
                  const Center(
                    child: Icon(Icons.location_on, size: 40, color: EcoColors.orange),
                  ),
                  // Nút "Đặt địa chỉ tại đây" nằm trong map
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        GeocodingRepository()
                            .reverseVietnam(LatLng(_selectedPos.latitude, _selectedPos.longitude))
                            .then((address) {
                          if (address != null && mounted) {
                            setState(() {
                              _searchController.text = address;
                            });
                          }
                        });
                      },
                      icon: const Icon(Icons.location_pin, size: 16),
                      label: const Text(
                        'Đặt địa chỉ tại đây',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: EcoColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isLoading ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: EcoColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('LƯU VỊ TRÍ', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
