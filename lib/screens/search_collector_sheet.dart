import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/user_profile.dart';
import '../repositories/collector_repository.dart';
import '../repositories/user_repository.dart';
import '../theme/eco_colors.dart';
import '../ui/app_feedback.dart';

class SearchCollectorSheet extends StatefulWidget {
  final String currentUid;
  final LatLng? currentLocation;

  const SearchCollectorSheet({
    super.key,
    required this.currentUid,
    this.currentLocation,
  });

  @override
  State<SearchCollectorSheet> createState() => _SearchCollectorSheetState();
}

class _SearchCollectorSheetState extends State<SearchCollectorSheet> {
  final _collectorRepo = CollectorRepository();
  final _userRepo = UserRepository();
  
  final _searchController = TextEditingController();
  List<UserProfile> _collectors = [];
  bool _isLoading = false;
  List<String> _savedPartners = [];

  @override
  void initState() {
    super.initState();
    _loadSavedPartners();
    if (widget.currentLocation != null) {
      _loadNearby();
    }
  }

  Future<void> _loadSavedPartners() async {
    _userRepo.watchProfile(widget.currentUid).listen((profile) {
      if (mounted) {
        setState(() {
          _savedPartners = profile.savedPartners;
        });
      }
    });
  }

  Future<void> _loadNearby() async {
    setState(() => _isLoading = true);
    try {
      final list = await _collectorRepo.findNearby(widget.currentLocation!);
      if (mounted) setState(() => _collectors = list);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _search() async {
    if (_searchController.text.isEmpty) {
      if (widget.currentLocation != null) _loadNearby();
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final text = _searchController.text.trim();
      List<UserProfile> list = [];
      
      // If looks like phone number
      if (text.replaceAll(RegExp(r'[^0-9]'), '').length >= 9) {
        final u = await _collectorRepo.findByPhone(text);
        if (u != null) list = [u];
      } else {
        list = await _collectorRepo.searchByName(text);
      }
      
      if (mounted) setState(() => _collectors = list);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSave(UserProfile collector) async {
    try {
      if (_savedPartners.contains(collector.uid)) {
        await _userRepo.removePartner(widget.currentUid, collector.uid);
        if (mounted) showEcoSnackBar(context, 'Đã bỏ lưu đối tác', icon: Icons.info_outline);
      } else {
        await _userRepo.savePartner(widget.currentUid, collector.uid);
        if (mounted) showEcoSnackBar(context, 'Đã lưu đối tác', icon: Icons.favorite_rounded);
      }
    } catch (e) {
      if (mounted) showEcoSnackBar(context, 'Lỗi: $e', icon: Icons.error_outline);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: EcoColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: EcoColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Tìm Người Thu Mua', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: EcoColors.textBody)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Nhập tên hoặc số điện thoại...',
                filled: true,
                fillColor: EcoColors.inputFill,
                prefixIcon: const Icon(Icons.search_rounded, color: EcoColors.iconMuted),
                suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward_rounded, color: EcoColors.primary), onPressed: _search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: EcoColors.primary))
                : _collectors.isEmpty
                    ? const Center(child: Text('Không tìm thấy người thu mua phù hợp.', style: TextStyle(color: EcoColors.bodyMuted)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemCount: _collectors.length,
                        itemBuilder: (context, index) {
                          final c = _collectors[index];
                          final isSaved = _savedPartners.contains(c.uid);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: EcoColors.border),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: EcoColors.mintBg,
                                  backgroundImage: c.photoUrl != null ? NetworkImage(c.photoUrl!) : null,
                                  child: c.photoUrl == null ? const Icon(Icons.person_rounded, color: EcoColors.primary) : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: EcoColors.textBody)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded, color: EcoColors.warmYellow, size: 16),
                                          const SizedBox(width: 4),
                                          Text('4.9 (${c.totalOrders} chuyến)', style: const TextStyle(fontSize: 13, color: EcoColors.bodyMuted)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    color: isSaved ? EcoColors.coral : EcoColors.iconMuted,
                                  ),
                                  onPressed: () => _toggleSave(c),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
