import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/waste_type.dart';
import '../models/user_profile.dart';
import '../models/voucher.dart';
import '../repositories/market_price_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/paper_bank_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/voucher_repository.dart';
import '../theme/eco_colors.dart';
import '../ui/app_feedback.dart';
import '../utils/formatters.dart';
import 'home/pages/history_page.dart';
import 'home/pages/profile_page.dart';
import 'home/widgets/order_sheet.dart';
import 'home/widgets/radar_map.dart';
import 'home/widgets/saved_vouchers_sheet.dart';
import 'schedule_pickup_sheet.dart';
import 'home/widgets/location_picker_sheet.dart';
import 'scan_screen.dart';
import 'home/widgets/price_detail_sheet.dart';
import 'home/widgets/chat_list_sheet.dart';
import 'home/widgets/notifications_sheet.dart';
import 'home/widgets/search_sheet.dart';
import 'home/widgets/apply_code_sheet.dart';
import 'home/widgets/donation_sheet.dart';
import 'home/widgets/ai_assistant_sheet.dart';
import 'home/widgets/add_voucher_sheet.dart';
import 'home/widgets/tree_exchange_sheet.dart';
import 'home/widgets/collector_dashboard_sheet.dart';
import 'home/widgets/order_tracking_sheet.dart';
import 'home/widgets/market_fluctuation_card.dart';
import 'home/widgets/green_points_dashboard_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  int _selectedWaste = 0;
  double _weight = 8;
  List<WasteType> _wasteTypes = [];
  double _paperBankProgress = 0;

  final _orderRepo = OrderRepository();
  final _marketPriceRepo = MarketPriceRepository();
  final _paperBankRepo = PaperBankRepository();
  
  // Notifier to move map to specific location
  final ValueNotifier<LatLng?> _mapFocusNotifier = ValueNotifier<LatLng?>(null);

  @override
  void initState() {
    super.initState();
    _marketPriceRepo.watchPrices().listen((list) {
      if (mounted) setState(() => _wasteTypes = list);
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _paperBankRepo.watchUserProgress(uid).listen((progress) {
        if (mounted) setState(() => _paperBankProgress = progress);
      });

      // Notify seller when order is accepted
      _orderRepo.watchActiveOrder(uid).listen((order) {
        if (order != null && order.status == 'accepted' && mounted) {
          _showToast(
              'Người thu mua ${order.collectorName ?? "đã nhận đơn"} đang đến!',
              icon: Icons.local_shipping_rounded);
        }
      });
    }

    // Notify collector (buyer) when there are new pending orders
    _orderRepo.watchPendingOrders().listen((orders) {
      if (orders.isNotEmpty && mounted) {
        _showToast('Có ${orders.length} yêu cầu thu gom mới gần bạn!',
            icon: Icons.notification_important_rounded);
      }
    });
  }

  void _setTab(int value) {
    if (value == 2) {
      _openAiScan();
      return;
    }
    ecoLightTap();
    setState(() => _tab = value);
  }

  void _showToast(String message, {IconData? icon}) {
    showEcoSnackBar(context, message, icon: icon);
  }

  void _openAiScan() {
    ecoLightTap();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ScanScreen()),
    );
  }

  void _showSchedulePickupSheet() {
    ecoLightTap();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SchedulePickupSheet(),
    );
  }

  void _openMap() {
    ecoLightTap();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const _MapScreen()),
    );
  }


  void _showSavedVouchersSheet() {
    ecoLightTap();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SafeArea(child: SavedVouchersSheet()),
    );
  }

  void _showFeatureSheet({
    required String title,
    required String body,
    required IconData icon,
    VoidCallback? action,
    String actionLabel = 'Thuc hien',
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: EcoColors.sheetHandle,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Icon(icon, color: EcoColors.primary, size: 42),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15, height: 1.45, color: EcoColors.bodyMuted),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    action?.call();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: EcoColors.primary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(actionLabel,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCustomOrderSheet() {
    ecoLightTap();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomMaterialSheet(
        onSubmitted: (name, price, weight, loc, addr) async {
          try {
            await _orderRepo.createOrder({
              'wasteType': name,
              'weight': weight,
              'totalPrice': (price * weight).round(),
              'status': 'pending',
              'userId': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
              'location': GeoPoint(loc.latitude, loc.longitude),
              'address': addr,
            });
            if (mounted) {
              _showToast('Đã đăng đơn hàng mới thành công!',
                  icon: Icons.done_all_rounded);
            }
          } catch (e) {
            if (mounted) {
              _showToast('Lỗi: $e', icon: Icons.error_outline_rounded);
            }
          }
        },
      ),
    );
  }

  void _showOrderSheet() {
    if (_wasteTypes.isEmpty) return;
    if (_selectedWaste >= _wasteTypes.length) {
      _showCustomOrderSheet();
      return;
    }
    ecoLightTap();
    final waste = _wasteTypes[_selectedWaste];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderSheet(
        selectedWaste: waste,
        weight: _weight,
        total: (waste.price * _weight).round(),
        onSubmitted: (loc, addr) async {
          try {
            final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
            await _orderRepo.createOrder({
              'wasteType': waste.name,
              'weight': _weight,
              'totalPrice': (waste.price * _weight).round(),
              'status': 'pending',
              'userId': uid,
              'location': GeoPoint(loc.latitude, loc.longitude),
              'address': addr,
            });

            if (mounted) {
              _showToast('Đăng đơn hàng thành công!',
                  icon: Icons.done_all_rounded);
            }
          } catch (e) {
            if (mounted) {
              _showToast('Lỗi: $e', icon: Icons.error_outline_rounded);
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_wasteTypes.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<UserProfile>(
      stream: uid != null
          ? UserRepository().watchProfile(uid)
          : Stream.value(UserProfile(
              uid: 'guest',
              displayName: 'Khách',
              phone: '',
              address: '',
              greenPoints: 0,
              totalKgRecycled: 0,
              totalOrders: 0,
              createdAt: DateTime.now(),
              role: 'seller',
              maxPickupLocations: 3)),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final currentPoints = profile?.greenPoints ?? 0;

        final pages = [
          _EccHomePage(
            wasteTypes: _wasteTypes,
            selectedWaste: _selectedWaste,
            weight: _weight,
            paperBankProgress: _paperBankProgress,
            onWasteChanged: (value) => setState(() => _selectedWaste = value),
            onWeightChanged: (value) => setState(() => _weight = value),
            onCreateOrder: _showOrderSheet,
            onOpenScan: _openAiScan,
            onOpenSchedule: _showSchedulePickupSheet,
            onOpenOffers: () => _setTab(1),
            onOpenSavedVouchers: _showSavedVouchersSheet,
            onOpenMap: _openMap,
            onOpenCollectors: _openMap,
            onShowFeature: _showFeatureSheet,
            currentPoints: currentPoints,
            mapFocusNotifier: _mapFocusNotifier,
          ),
          _OffersPage(
            onOpenSavedVouchers: _showSavedVouchersSheet,
            onOpenScan: _openAiScan,
            onShowFeature: _showFeatureSheet,
            currentPoints: currentPoints,
          ),
          HistoryPage(
            wasteTypes: _wasteTypes,
            onOrderTap: (order, type) => _showFeatureSheet(
              title: 'Chi tiết giao dịch',
              body:
                  'Loại rác: ${order.wasteType}\nKhối lượng: ${order.weight}kg\nGiá trị: ${formatVnd(order.estimatedPrice)}đ\nTrạng thái: ${order.status}',
              icon: type.icon,
              actionLabel: 'Đã hiểu',
            ),
          ),
          ProfilePage(
            onFieldTap: (i) => _showFeatureSheet(
              title: 'Tính năng tài khoản',
              body:
                  'Mục này giúp quản lý bảo mật, cài đặt và thông tin cá nhân của tài khoản EcoCollect.',
              icon: Icons.manage_accounts_rounded,
              actionLabel: 'Đóng',
            ),
          ),
        ];

        return Scaffold(
          backgroundColor: const Color(0xFFFFF3E2),
          body: SafeArea(
            bottom: false,
            child: IndexedStack(
                index: _tab > 2 ? _tab - 1 : _tab, children: pages),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: Transform.translate(
            offset: const Offset(0, -10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (profile != null && (profile.isCollector || profile.isStation || profile.isAdmin))
                  FloatingActionButton.small(
                    heroTag: 'collector_fab',
                    onPressed: () {
                      ecoLightTap();
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => CollectorDashboardSheet(
                          onOrderFocus: (loc) {
                            _setTab(0);
                            _mapFocusNotifier.value = loc;
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                    backgroundColor: EcoColors.orange,
                    elevation: 4,
                    child: const Icon(Icons.local_shipping_rounded,
                        color: Colors.white, size: 20),
                  ),
                if (profile != null && (profile.isCollector || profile.isStation || profile.isAdmin))
                  const SizedBox(width: 54),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (profile != null && (profile.isCollector || profile.isAdmin)) ...[
                      FloatingActionButton.small(
                        heroTag: 'tracking_fab',
                        onPressed: () {
                          ecoLightTap();
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => OrderTrackingSheet(
                            onOrderFocus: (loc) {
                              _setTab(0); // Ensure we are on home tab
                              _mapFocusNotifier.value = loc;
                            },
                          ),
                          );
                        },
                        backgroundColor: EcoColors.coral,
                        elevation: 6,
                        child: const Icon(Icons.track_changes_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(height: 12),
                    ],
                    FloatingActionButton.small(
                      heroTag: 'ai_fab',
                      onPressed: () {
                        ecoLightTap();
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const AiAssistantSheet(),
                        );
                      },
                      backgroundColor: EcoColors.primary,
                      elevation: 4,
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
          bottomNavigationBar: _MomoLikeNavBar(
            selectedIndex: _tab,
            onSelected: _setTab,
          ),
        );
      },
    );
  }
}

class _EccHomePage extends StatelessWidget {
  const _EccHomePage({
    required this.wasteTypes,
    required this.selectedWaste,
    required this.weight,
    required this.paperBankProgress,
    required this.onWasteChanged,
    required this.onWeightChanged,
    required this.onCreateOrder,
    required this.onOpenScan,
    required this.onOpenSchedule,
    required this.onOpenOffers,
    required this.onOpenSavedVouchers,
    required this.onOpenMap,
    required this.onOpenCollectors,
    required this.onShowFeature,
    required this.currentPoints,
    required this.mapFocusNotifier,
  });

  final List<WasteType> wasteTypes;
  final int selectedWaste;
  final double weight;
  final double paperBankProgress;
  final ValueChanged<int> onWasteChanged;
  final ValueChanged<double> onWeightChanged;
  final VoidCallback onCreateOrder;
  final VoidCallback onOpenScan;
  final VoidCallback onOpenSchedule;
  final VoidCallback onOpenOffers;
  final VoidCallback onOpenSavedVouchers;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenCollectors;
  final int currentPoints;
  final void Function({
    required String title,
    required String body,
    required IconData icon,
    VoidCallback? action,
    required String actionLabel,
  }) onShowFeature;
  final ValueNotifier<LatLng?> mapFocusNotifier;

  @override
  Widget build(BuildContext context) {
    final isCustom = selectedWaste >= wasteTypes.length;
    final waste = isCustom ? null : wasteTypes[selectedWaste];
    final estimate = waste != null ? (waste.price * weight).round() : 0;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Column(
              children: [
                _TopSearchBar(
                  onSearchTap: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => SearchSheet(
                        onItemTap: (title, icon) {
                          if (title.contains('Gom yêu thương')) {
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const DonationSheet(),
                            );
                          } else {
                            onShowFeature(
                                title: title.replaceAll('\n', ' '),
                                body: 'Thông tin tính năng...',
                                icon: icon,
                                actionLabel: 'Đóng');
                          }
                        },
                      ),
                    );
                  },
                  onNotifyTap: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const NotificationsSheet(),
                    );
                  },
                  onChatTap: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const ChatListSheet(),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _HeroDeal(onTap: onOpenOffers),
                const SizedBox(height: 12),
                _StatusStrip(
                  points: currentPoints,
                  progress: paperBankProgress,
                  onTrees: () {
                    ecoLightTap();
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const TreeExchangeSheet(),
                    );
                  },
                  onCode: () => onShowFeature(
                    title: 'Nhập mã ưu đãi',
                    body:
                        'Nhập mã giới thiệu hoặc mã voucher để nhận thêm điểm xanh.',
                    icon: Icons.confirmation_number_rounded,
                    actionLabel: 'Đóng',
                  ),
                  onPoints: () {
                    ecoLightTap();
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const GreenPointsDashboardSheet(),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _QuickServiceRow(
                  onOpenScan: onOpenScan,
                  onOpenSchedule: onOpenSchedule,
                  onOpenOffers: onOpenOffers,
                  onOpenMap: onOpenMap,
                  onOpenCollectors: onOpenCollectors,
                  onShowFeature: onShowFeature,
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
            child: Column(
              children: [
                _CompactOrderCard(
                  wasteTypes: wasteTypes,
                  selectedWaste: selectedWaste,
                  weight: weight,
                  estimate: estimate,
                  onWasteChanged: onWasteChanged,
                  onWeightChanged: onWeightChanged,
                  onCreateOrder: onCreateOrder,
                ),
                const SizedBox(height: 12),
                RadarMap(height: 320, focusNotifier: mapFocusNotifier),
                const MarketFluctuationCard(),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _SectionHeader(
                  title: 'Giá thu gom hôm nay',
                  action: 'Xem thêm',
                  onTap: () => onShowFeature(
                        title: 'Bang gia thu gom',
                        body:
                            'Bang gia cap nhat theo Firestore. Cham tung loai rac de xem cach phan loai va uoc tinh gia.',
                        icon: Icons.trending_up_rounded,
                        actionLabel: 'Dong',
                      )),
              _MarketScroller(
                wasteTypes: wasteTypes,
                onItemTap: (item) {
                  ecoLightTap();
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => PriceDetailSheet(wasteType: item),
                  );
                },
              ),
              const SizedBox(height: 20),
              _SectionHeader(
                  title: 'Gợi ý xanh',
                  action: 'Tất cả',
                  onTap: () => onShowFeature(
                        title: 'Cam nang phan loai',
                        body:
                            'Cac goi y giup rac sach hon, dinh gia tot hon va tang diem xanh khi hoan thanh don.',
                        icon: Icons.tips_and_updates_rounded,
                        actionLabel: 'Dong',
                      )),
              const SizedBox(height: 10),
              _EcoTipCard(
                icon: Icons.inventory_2_rounded,
                title: 'Ép phẳng giấy carton',
                subtitle: 'Tăng điểm và giữ rác gọn trước khi thu gom.',
                color: EcoColors.orange,
                onTap: () => onShowFeature(
                  title: 'Ep phang giay carton',
                  body:
                      'Go bo bang keo lon, ep phang va buoc gon. Giay kho sach se co gia thu gom tot hon.',
                  icon: Icons.inventory_2_rounded,
                  action: onCreateOrder,
                  actionLabel: 'Goi thu gom',
                ),
              ),
              const SizedBox(height: 10),
              _EcoTipCard(
                icon: Icons.local_drink_rounded,
                title: 'Làm sạch chai PET',
                subtitle:
                    'Tháo nắp, xả nhanh nước còn lại để được định giá tốt hơn.',
                color: EcoColors.blue,
                onTap: () => onShowFeature(
                  title: 'Lam sach chai PET',
                  body:
                      'Do het nuoc con lai, thao nap neu khac loai nhua va gom rieng chai trong.',
                  icon: Icons.local_drink_rounded,
                  action: onOpenScan,
                  actionLabel: 'Scan kiem tra',
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _OffersPage extends StatefulWidget {
  const _OffersPage({
    required this.onOpenSavedVouchers,
    required this.onOpenScan,
    required this.onShowFeature,
    required this.currentPoints,
  });

  final VoidCallback onOpenSavedVouchers;
  final VoidCallback onOpenScan;
  final int currentPoints;
  final void Function({
    required String title,
    required String body,
    required IconData icon,
    VoidCallback? action,
    required String actionLabel,
  }) onShowFeature;

  @override
  State<_OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<_OffersPage> {
  String? _selectedCategory;
  final _voucherRepo = VoucherRepository();

  Future<void> _redeemVoucher(Voucher voucher) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      showEcoSnackBar(context, 'Vui lòng đăng nhập để đổi voucher.');
      return;
    }

    if (widget.currentPoints < voucher.pointsCost) {
      showEcoSnackBar(context, 'Bạn không đủ điểm xanh để đổi voucher này.', 
        icon: Icons.warning_amber_rounded);
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: EcoColors.primary)),
    );

    try {
      await _voucherRepo.redeemVoucher(uid, voucher);
      if (mounted) {
        Navigator.pop(context); // Close loading
        ecoSuccessTap();
        showEcoSnackBar(context, 'Đổi voucher thành công! Đã lưu vào kho ưu đãi.', 
          icon: Icons.check_circle_rounded);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        showEcoSnackBar(context, 'Lỗi: $e', icon: Icons.error_outline);
      }
    }
  }

  Future<void> _confirmDeleteVoucher(Voucher voucher) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Bạn có chắc muốn xóa vĩnh viễn voucher "${voucher.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('HỦY')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('XÓA', style: TextStyle(color: EcoColors.orange, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _voucherRepo.deleteVoucher(voucher.id);
        if (mounted) showEcoSnackBar(context, 'Đã xóa voucher vĩnh viễn.');
      } catch (e) {
        if (mounted) showEcoSnackBar(context, 'Lỗi: $e');
      }
    }
  }

  String? _getCategoryIdFromLabel(String label) {
    switch (label) {
      case 'Điểm xanh':
        return 'points';
      case 'Ăn uống':
        return 'food';
      case 'Mua sắm':
        return 'shopping';
      case 'Di chuyển':
        return 'transport';
      case 'Tái chế':
        return 'recycle';
      default:
        return null;
    }
  }

  String _getLabelFromCategoryId(String category) {
    switch (category) {
      case 'points':
        return 'Điểm xanh';
      case 'food':
        return 'Ăn uống';
      case 'shopping':
        return 'Mua sắm';
      case 'transport':
        return 'Di chuyển';
      case 'recycle':
        return 'Tái chế';
      default:
        return '';
    }
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'food':
        return Icons.local_cafe_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'transport':
        return Icons.directions_bus_rounded;
      case 'points':
        return Icons.eco_rounded;
      case 'recycle':
        return Icons.recycling_rounded;
      default:
        return Icons.card_giftcard_rounded;
    }
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'food':
        return const Color(0xFFFFE9C7);
      case 'shopping':
        return const Color(0xFFEAF8D8);
      case 'transport':
        return const Color(0xFFFFDDE9);
      case 'points':
        return const Color(0xFFE9F7FF);
      case 'recycle':
        return const Color(0xFFEAF8F1);
      default:
        return const Color(0xFFF0F0F0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Column(
              children: [
                _TopSearchBar(
                  hint: 'voucher xanh, đổi điểm',
                  onSearchTap: () => widget.onShowFeature(
                    title: 'Tim uu dai',
                    body:
                        'Tim voucher theo diem xanh, loai rac hoac doi tac tai che.',
                    icon: Icons.search_rounded,
                    actionLabel: 'Dong',
                  ),
                  onNotifyTap: () => widget.onShowFeature(
                    title: 'Thong bao uu dai',
                    body:
                        'Voucher sap het han, qua moi va lich su thu thap se hien thi tai day.',
                    icon: Icons.notifications_rounded,
                    actionLabel: 'Dong',
                  ),
                  onChatTap: () => widget.onShowFeature(
                    title: 'Ho tro voucher',
                    body:
                        'Lien he EcoCollect khi voucher khong ap dung duoc hoac can doi qua.',
                    icon: Icons.chat_bubble_rounded,
                    actionLabel: 'Dong',
                  ),
                ),
                const SizedBox(height: 18),
                const _OfferHero(),
                const SizedBox(height: 12),
                _StatusStrip(
                  points: widget.currentPoints,
                  progress: 0.42, // TODO: Update to real
                  secondaryLabel: 'Voucher của tôi',
                  secondarySubtitle: 'Kho ưu đãi',
                  secondaryIcon: Icons.confirmation_number_outlined,
                  onTrees: widget.onOpenSavedVouchers,
                  onCode: () {
                    ecoLightTap();
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const ApplyCodeSheet(),
                    );
                  },
                  onPoints: () {
                    ecoLightTap();
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const GreenPointsDashboardSheet(),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _CategoryScroller(onTap: (label) {
                  setState(() {
                    final catId = _getCategoryIdFromLabel(label);
                    if (_selectedCategory == catId) {
                      _selectedCategory = null;
                    } else {
                      _selectedCategory = catId;
                    }
                  });
                }),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 20, 0, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 18.0),
                  child: uid == null
                      ? _SectionHeader(
                          title: _selectedCategory == null
                              ? 'Đổi điểm lấy voucher'
                              : 'Ưu đãi ${_getLabelFromCategoryId(_selectedCategory!)}',
                          action: 'Bộ lọc',
                          onTap: () => widget.onShowFeature(
                                title: 'Bo loc voucher',
                                body:
                                    'Loc theo so diem, han su dung, doi tac va loai uu dai.',
                                icon: Icons.filter_alt_rounded,
                                actionLabel: 'Dong',
                              ))
                      : StreamBuilder<UserProfile>(
                          stream: UserRepository().watchProfile(uid),
                          builder: (context, snapshot) {
                            final isCollector =
                                snapshot.data?.isCollector ?? false;
                            return Row(
                              children: [
                                Expanded(
                                  child: _SectionHeader(
                                      title: _selectedCategory == null
                                          ? 'Đổi điểm lấy voucher'
                                          : 'Ưu đãi ${_getLabelFromCategoryId(_selectedCategory!)}',
                                      action: 'Bộ lọc',
                                      onTap: () => widget.onShowFeature(
                                            title: 'Bo loc voucher',
                                            body:
                                                'Loc theo so diem, han su dung, doi tac va loai uu dai.',
                                            icon: Icons.filter_alt_rounded,
                                            actionLabel: 'Dong',
                                          )),
                                ),
                                if (isCollector) ...[
                                  const SizedBox(width: 8),
                                  FilledButton.icon(
                                    onPressed: () {
                                      ecoLightTap();
                                      showModalBottomSheet<void>(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => const AddVoucherSheet(),
                                      );
                                    },
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Đăng voucher',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: EcoColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      minimumSize: const Size(0, 36),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  ),
                                ]
                              ],
                            );
                          },
                        ),
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.0),
                  child: Text('Thương hiệu nổi bật: 1000M Tea & Coffee',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: EcoColors.bodyMuted,
                          letterSpacing: 0.5)),
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<Voucher>>(
                  stream: _voucherRepo.watchVouchersByCategory(_selectedCategory == null ? null : _getLabelFromCategoryId(_selectedCategory!)),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(height: 235, child: Center(child: CircularProgressIndicator()));
                    }
                    final allVouchers = snapshot.data ?? [];
                    // ONLY show branch vouchers
                    final branchKeywords = ['1000m', 'winmart', 'highlands', 'coffee', 'circle k', 'the_coffee_house', 'starbucks', 'ecocollect'];
                    final featuredVouchers = allVouchers.where((v) {
                      final title = v.title.toLowerCase();
                      final img = (v.imageUrl ?? '').toLowerCase();
                      return branchKeywords.any((k) => title.contains(k) || img.contains(k));
                    }).toList();
                    
                    if (featuredVouchers.isEmpty) {
                      return const SizedBox(height: 100, child: Center(child: Text('Chưa có ưu đãi đối tác nào.')));
                    }

                    return StreamBuilder<UserProfile>(
                      stream: UserRepository().watchProfile(uid ?? ''),
                      builder: (context, userSnap) {
                        final isAdmin = userSnap.data?.isAdmin ?? false;
                        return SizedBox(
                          height: 235,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(left: 18),
                            itemCount: featuredVouchers.length,
                            itemBuilder: (context, index) {
                              final v = featuredVouchers[index];
                              return _VoucherCard(
                                icon: _getIconForCategory(v.category),
                                imageUrl: v.imageUrl,
                                title: v.title,
                                discount: v.description,
                                condition: 'Đổi với ${v.pointsCost} điểm',
                                color: _getColorForCategory(v.category),
                                onCollect: () => _redeemVoucher(v),
                                isAdmin: isAdmin,
                                onDelete: () => _confirmDeleteVoucher(v),
                              );
                            },
                          ),
                        );
                      }
                    );
                  }
                ),
                const SizedBox(height: 40),
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.verified_user_rounded, color: EcoColors.primary, size: 32),
                      SizedBox(height: 8),
                      Text('Ưu đãi được xác thực bởi EcoCollect', 
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: EcoColors.bodyMuted)),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: const SizedBox(height: 110)),
      ],
    );
  }
}

class _TopSearchBar extends StatelessWidget {
  const _TopSearchBar({
    this.hint = 'tìm loại rác, lịch thu gom',
    required this.onSearchTap,
    required this.onNotifyTap,
    required this.onChatTap,
  });

  final String hint;
  final VoidCallback onSearchTap;
  final VoidCallback onNotifyTap;
  final VoidCallback onChatTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onSearchTap,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 12,
                      offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      size: 26, color: EcoColors.bodyMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: EcoColors.bodyMuted,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _RoundIconButton(
            icon: Icons.notifications_none_rounded,
            badge: '9+',
            onTap: onNotifyTap),
        const SizedBox(width: 8),
        _RoundIconButton(
            icon: Icons.chat_bubble_outline_rounded, onTap: onChatTap),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, this.badge, required this.onTap});

  final IconData icon;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                    color: Color(0x16000000),
                    blurRadius: 10,
                    offset: Offset(0, 4)),
              ],
            ),
            child: Icon(icon, color: EcoColors.textBody),
          ),
          if (badge != null)
            Positioned(
              right: -2,
              top: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: EcoColors.coral,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroDeal extends StatelessWidget {
  const _HeroDeal({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF4D8), Color(0xFFDFF6FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Giảm thêm 10%',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  SizedBox(height: 1),
                  Text('tối đa 100K',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                  Text('Áp dụng đơn thu gom đầu tiên',
                      style: TextStyle(
                          fontSize: 12,
                          color: EcoColors.bodyMuted,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Container(
              width: 86,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.72),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.recycling_rounded,
                  size: 48, color: EcoColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferHero extends StatelessWidget {
  const _OfferHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE7BC), Color(0xFFE4F5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Combo vi vu & sống xanh',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                SizedBox(height: 2),
                Text('Deal hời vào Thứ 5',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Icon(Icons.card_giftcard_rounded, size: 54, color: EcoColors.coral),
        ],
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({
    required this.points,
    required this.progress,
    required this.onTrees,
    required this.onCode,
    required this.onPoints,
    this.secondaryLabel = 'Đổi cây',
    this.secondarySubtitle = 'Vườn sinh thái',
    this.secondaryIcon = Icons.forest_rounded,
  });

  final int points;
  final double progress;
  final VoidCallback onTrees;
  final VoidCallback onCode;
  final VoidCallback onPoints;
  final String secondaryLabel;
  final String secondarySubtitle;
  final IconData secondaryIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1C000000), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onCode,
              child: _StatusItem(
                  icon: Icons.confirmation_number_rounded,
                  title: 'Nhập mã',
                  subtitle: 'Ưu đãi'),
            ),
          ),
          const _StripDivider(),
          Expanded(
            child: GestureDetector(
              onTap: onPoints,
              child: _StatusItem(
                  icon: Icons.eco_rounded,
                  title: '$points',
                  subtitle: 'Điểm xanh'),
            ),
          ),
          const _StripDivider(),
          Expanded(
            child: GestureDetector(
              onTap: onTrees,
              child: _StatusItem(
                icon: secondaryIcon,
                title: secondaryLabel,
                subtitle: secondarySubtitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StripDivider extends StatelessWidget {
  const _StripDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: EcoColors.border);
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 23, color: EcoColors.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900)),
              Text(subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: EcoColors.bodyMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickServiceRow extends StatelessWidget {
  const _QuickServiceRow({
    required this.onOpenScan,
    required this.onOpenSchedule,
    required this.onOpenOffers,
    required this.onOpenMap,
    required this.onOpenCollectors,
    required this.onShowFeature,
  });

  final VoidCallback onOpenScan;
  final VoidCallback onOpenSchedule;
  final VoidCallback onOpenOffers;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenCollectors;
  final void Function({
    required String title,
    required String body,
    required IconData icon,
    VoidCallback? action,
    required String actionLabel,
  }) onShowFeature;

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickItem(Icons.document_scanner_rounded, 'AI scan', EcoColors.primary,
          onOpenScan),
      _QuickItem(Icons.calendar_month_rounded, 'Đặt lịch', EcoColors.blue,
          onOpenSchedule),
      _QuickItem(Icons.storefront_rounded, 'Trạm gần', EcoColors.orange, () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => SearchSheet(
            onItemTap: (title, icon) {
              if (title.contains('Gom yêu thương')) {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const DonationSheet(),
                );
              } else {
                onShowFeature(
                    title: title.replaceAll('\n', ' '),
                    body: 'Thông tin tính năng...',
                    icon: icon,
                    actionLabel: 'Đóng');
              }
            },
          ),
        );
      }),
      _QuickItem(
          Icons.notifications_active_rounded, 'Thông báo', EcoColors.coral, () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const NotificationsSheet(),
        );
      }),
      _QuickItem(Icons.chat_bubble_rounded, 'Tin nhắn', EcoColors.purple, () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const ChatListSheet(),
        );
      }),
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: item.onTap,
            child: SizedBox(
              width: 66,
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(item.icon, color: item.color, size: 28),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickItem {
  const _QuickItem(this.icon, this.label, this.color, this.onTap);

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _CompactOrderCard extends StatelessWidget {
  const _CompactOrderCard({
    required this.wasteTypes,
    required this.selectedWaste,
    required this.weight,
    required this.estimate,
    required this.onWasteChanged,
    required this.onWeightChanged,
    required this.onCreateOrder,
  });

  final List<WasteType> wasteTypes;
  final int selectedWaste;
  final double weight;
  final int estimate;
  final ValueChanged<int> onWasteChanged;
  final ValueChanged<double> onWeightChanged;
  final VoidCallback onCreateOrder;

  @override
  Widget build(BuildContext context) {
    final isCustom = selectedWaste >= wasteTypes.length;
    final currentIcon =
        isCustom ? Icons.add_task_rounded : wasteTypes[selectedWaste].icon;
    final currentColor =
        isCustom ? EcoColors.primary : wasteTypes[selectedWaste].color;
    final currentName =
        isCustom ? 'Vật liệu tùy chỉnh' : wasteTypes[selectedWaste].name;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: currentColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(currentIcon, color: currentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gọi thu gom nhanh',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900)),
                    Text(
                        selectedWaste < wasteTypes.length
                            ? '$currentName - ${weight.toStringAsFixed(0)}kg'
                            : 'Nhấn để thiết lập vật liệu',
                        style: const TextStyle(
                            fontSize: 13, color: EcoColors.bodyMuted)),
                  ],
                ),
              ),
              Text(
                  selectedWaste < wasteTypes.length
                      ? formatVnd(estimate)
                      : '--- đ',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: EcoColors.primary)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...List.generate(wasteTypes.length, (index) {
                final item = wasteTypes[index];
                final selected = index == selectedWaste;
                return ChoiceChip(
                  selected: selected,
                  label: Text(item.name),
                  onSelected: (_) => onWasteChanged(index),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : EcoColors.textBody,
                  ),
                  selectedColor: EcoColors.primary,
                  backgroundColor: EcoColors.surfaceMuted,
                  side: BorderSide.none,
                );
              }),
              ChoiceChip(
                selected: selectedWaste >= wasteTypes.length,
                label: const Text('Tùy chỉnh +'),
                onSelected: (_) => onWasteChanged(wasteTypes.length),
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: selectedWaste >= wasteTypes.length
                      ? Colors.white
                      : EcoColors.primary,
                ),
                selectedColor: EcoColors.primary,
                backgroundColor: EcoColors.primary.withOpacity(0.1),
                side: BorderSide.none,
              ),
            ],
          ),
          Slider(
            value: weight,
            min: 1,
            max: 50,
            divisions: 49,
            activeColor: EcoColors.primary,
            onChanged: onWeightChanged,
          ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: onCreateOrder,
              icon: const Icon(Icons.radar_rounded),
              label: const Text('Đăng đơn hàng mới'),
              style: FilledButton.styleFrom(
                backgroundColor: EcoColors.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketScroller extends StatelessWidget {
  const _MarketScroller({required this.wasteTypes, required this.onItemTap});

  final List<WasteType> wasteTypes;
  final ValueChanged<WasteType> onItemTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 106,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: wasteTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = wasteTypes[index];
          return GestureDetector(
            onTap: () => onItemTap(item),
            child: Container(
              width: 150,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.icon, color: item.color, size: 26),
                  const Spacer(),
                  Text(item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  Text('${formatVnd(item.price)}/kg',
                      style: const TextStyle(
                          fontSize: 12, color: EcoColors.bodyMuted)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MapEntryCard extends StatelessWidget {
  const _MapEntryCard({
    required this.onOpenMap,
    required this.onOpenCollectors,
  });

  final VoidCallback onOpenMap;
  final VoidCallback onOpenCollectors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onOpenMap,
            child: Container(
              width: 86,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.map_rounded, color: EcoColors.primary, size: 44),
                  Positioned(
                    right: 16,
                    top: 14,
                    child: Icon(Icons.location_on_rounded,
                        color: EcoColors.coral, size: 20),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onOpenMap,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bản đồ thu gom',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  SizedBox(height: 4),
                  Text('Xem trạm gần bạn, radar người thu gom và điểm tập kết.',
                      style: TextStyle(
                          fontSize: 13,
                          color: EcoColors.bodyMuted,
                          height: 1.3)),
                ],
              ),
            ),
          ),
          IconButton.filled(
            onPressed: onOpenCollectors,
            style: IconButton.styleFrom(backgroundColor: EcoColors.primary),
            icon: const Icon(Icons.people_alt_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action, this.onTap});

  final String title;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w900))),
        GestureDetector(
          onTap: onTap,
          child: Text(action,
              style: const TextStyle(
                  fontSize: 13,
                  color: EcoColors.primary,
                  fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

class _EcoTipCard extends StatelessWidget {
  const _EcoTipCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w900)),
                  Text(subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: EcoColors.bodyMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: EcoColors.iconMuted),
          ],
        ),
      ),
    );
  }
}

class _CategoryScroller extends StatelessWidget {
  const _CategoryScroller({required this.onTap});

  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.eco_rounded, 'Điểm xanh', EcoColors.primary),
      (Icons.local_cafe_rounded, 'Ăn uống', EcoColors.orange),
      (Icons.shopping_bag_rounded, 'Mua sắm', EcoColors.blue),
      (Icons.train_rounded, 'Di chuyển', EcoColors.coral),
      (Icons.recycling_rounded, 'Tái chế', EcoColors.purple),
    ];

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () => onTap(item.$2),
            child: SizedBox(
              width: 62,
              child: Column(
                children: [
                  Icon(item.$1, color: item.$3, size: 28),
                  const SizedBox(height: 5),
                  Text(item.$2,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({
    required this.icon,
    this.imageUrl,
    required this.title,
    required this.discount,
    required this.condition,
    required this.color,
    required this.onCollect,
    this.onDelete,
    this.isAdmin = false,
  });

  final IconData icon;
  final String? imageUrl;
  final String title;
  final String discount;
  final String condition;
  final Color color;
  final VoidCallback onCollect;
  final VoidCallback? onDelete;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 96,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  image: imageUrl != null
                      ? DecorationImage(
                          image: imageUrl!.startsWith('http')
                              ? NetworkImage(imageUrl!) as ImageProvider
                              : AssetImage(imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageUrl == null
                    ? Center(child: Icon(icon, size: 32, color: Colors.white))
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      discount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: EcoColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        condition,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          color: EcoColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onCollect,
                        style: FilledButton.styleFrom(
                          backgroundColor: EcoColors.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('ĐỔI NGAY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isAdmin && onDelete != null)
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.delete_outline_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WideOfferCard extends StatelessWidget {
  const _WideOfferCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(icon, color: EcoColors.primary, size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12,
                          color: EcoColors.bodyMuted,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapScreen extends StatelessWidget {
  const _MapScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F6),
      appBar: AppBar(
        title: const Text('Bản đồ thu gom',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: EcoColors.textBody,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const RadarMap(height: 460),
          const SizedBox(height: 16),
          _WideOfferCard(
            title: 'Trạm tái chế gần bạn',
            subtitle:
                'Mở radar để xem vị trí của bạn, người thu gom mô phỏng và các điểm tập kết.',
            icon: Icons.storefront_rounded,
            color: Colors.white,
            onTap: () => showEcoSnackBar(
              context,
              'Ban do dang hien thi tram va nguoi thu gom gan ban.',
              icon: Icons.map_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _MomoLikeNavBar extends StatelessWidget {
  const _MomoLikeNavBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x18000000), blurRadius: 18, offset: Offset(0, -6)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
              child: _NavItem(
                  index: 0,
                  selectedIndex: selectedIndex,
                  icon: Icons.grid_view_rounded,
                  label: 'ECC',
                  onTap: onSelected)),
          Expanded(
              child: _NavItem(
                  index: 1,
                  selectedIndex: selectedIndex,
                  icon: Icons.card_giftcard_rounded,
                  label: 'Ưu đãi',
                  onTap: onSelected,
                  hasDot: true)),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -24),
              child: GestureDetector(
                onTap: () => onSelected(2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: EcoColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 8),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x28000000),
                              blurRadius: 18,
                              offset: Offset(0, 8)),
                        ],
                      ),
                      child: const Icon(Icons.recycling_rounded,
                          color: Colors.white, size: 34),
                    ),
                    const Text('Scan rác',
                        style: TextStyle(
                            fontSize: 12,
                            color: EcoColors.navInactive,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
              child: _NavItem(
                  index: 3,
                  selectedIndex: selectedIndex,
                  icon: Icons.history_rounded,
                  label: 'Lịch sử',
                  onTap: onSelected)),
          Expanded(
              child: _NavItem(
                  index: 4,
                  selectedIndex: selectedIndex,
                  icon: Icons.person_outline_rounded,
                  label: 'Tôi',
                  onTap: onSelected,
                  hasDot: true)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.selectedIndex,
    required this.icon,
    required this.label,
    required this.onTap,
    this.hasDot = false,
  });

  final int index;
  final int selectedIndex;
  final IconData icon;
  final String label;
  final ValueChanged<int> onTap;
  final bool hasDot;

  @override
  Widget build(BuildContext context) {
    final selected = selectedIndex == index;
    final color = selected ? EcoColors.primary : EcoColors.navInactive;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: color, size: 30),
              if (hasDot)
                Positioned(
                  right: -3,
                  top: -3,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

String? _getLocalImageForVoucher(String title) {
  final t = title.toLowerCase();
  if (t.contains('1000m') || t.contains('tea') || t.contains('coffee')) {
    // Randomly pick one of the 3 images if not specified
    final list = ['1000m_1.jpg', '1000m_2.jpg', '1000m_3.jpg'];
    return 'assets/images/vouchers/${list[title.length % 3]}';
  } else if (t.contains('circle') || t.contains('k')) {
    return 'assets/images/vouchers/circle_k.jpg';
  } else if (t.contains('highland')) {
    return 'assets/images/vouchers/highlands.jpg';
  } else if (t.contains('winmart') || t.contains('win')) {
    return 'assets/images/vouchers/winmart.jpg';
  }
  return 'assets/images/vouchers/eco_default.jpg';
}

class _CustomMaterialSheet extends StatefulWidget {
  const _CustomMaterialSheet({required this.onSubmitted});
  final Function(String name, int price, double weight, LatLng location, String address) onSubmitted;

  @override
  State<_CustomMaterialSheet> createState() => _CustomMaterialSheetState();
}

class _CustomMaterialSheetState extends State<_CustomMaterialSheet> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  double _weight = 5.0;
  LatLng? _pickedLocation;
  String _address = 'Chưa chọn vị trí';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          22, 16, 22, MediaQuery.of(context).viewInsets.bottom + 32),
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
              child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                      color: EcoColors.sheetHandle,
                      borderRadius: BorderRadius.circular(999)))),
          const SizedBox(height: 20),
          const Text('Thêm vật liệu & Giá tùy chỉnh',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Tên vật liệu mới',
              hintText: 'VD: Sắt vụn, Linh kiện cũ...',
              filled: true,
              fillColor: EcoColors.inputFill,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Giá mong muốn (đ/kg)',
              hintText: 'VD: 15000',
              filled: true,
              fillColor: EcoColors.inputFill,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                  child: Text('Khối lượng dự kiến',
                      style: TextStyle(fontWeight: FontWeight.w700))),
              Text('${_weight.toStringAsFixed(0)} kg',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, color: EcoColors.primary)),
            ],
          ),
          Slider(
            value: _weight,
            min: 1,
            max: 100,
            divisions: 99,
            activeColor: EcoColors.primary,
            onChanged: (v) => setState(() => _weight = v),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 18),
          const Text('Địa điểm thu gom',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
          FilledButton(
            onPressed: () {
              final name = _nameController.text.trim();
              final price = int.tryParse(_priceController.text.trim()) ?? 0;
              if (name.isEmpty || price <= 0 || _pickedLocation == null) return;
              Navigator.pop(context);
              widget.onSubmitted(name, price, _weight, _pickedLocation!, _address);
            },
            style: FilledButton.styleFrom(
                backgroundColor: EcoColors.primary,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
            child: const Text('XÁC NHẬN & ĐĂNG ĐƠN HÀNG',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
