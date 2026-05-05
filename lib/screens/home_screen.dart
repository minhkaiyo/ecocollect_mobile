import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../models/waste_type.dart';
import '../theme/eco_colors.dart';
import '../ui/app_feedback.dart';
import '../repositories/order_repository.dart';
import '../repositories/user_repository.dart';
import '../models/user_profile.dart';
import '../models/order.dart';
import '../repositories/points_repository.dart';
import '../models/point_transaction.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  int _selectedWaste = 0;
  double _weight = 12;
  bool _hasActiveOrder = false;
  final _orderRepo = OrderRepository();

  final List<WasteType> _wasteTypes = const [
    WasteType(
      'Giấy',
      '4.500 - 6.000',
      5200,
      Icons.article_rounded,
      EcoColors.primary,
      'Ép phẳng, buộc gọn',
    ),
    WasteType(
      'Nhựa',
      '7.000 - 9.500',
      8200,
      Icons.water_drop_rounded,
      EcoColors.blue,
      'LĂ m sạch, tháo nhãn',
    ),
    WasteType(
      'Kim loại',
      '12.000 - 15.000',
      13500,
      Icons.view_in_ar_rounded,
      EcoColors.steel,
      'Tách theo nhóm kim loại',
    ),
    WasteType(
      'Điện tử',
      'Theo món',
      25000,
      Icons.memory_rounded,
      EcoColors.purple,
      'Bảo quản nguyên khối',
    ),
    WasteType(
      'Cồng kềnh',
      'Hẹn giá',
      0,
      Icons.chair_rounded,
      EcoColors.orange,
      'Chụp ảnh trước khi gửi',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1200;

        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                if (isWide) _SideNav(tab: _tab, onChanged: _setTab),
                Expanded(
                  child: IndexedStack(
                    index: _tab,
                    children: [
                      _HomeDashboard(
                        wasteTypes: _wasteTypes,
                        selectedWaste: _selectedWaste,
                        weight: _weight,
                        hasActiveOrder: _hasActiveOrder,
                        onWasteChanged: (value) => setState(() => _selectedWaste = value),
                        onWeightChanged: (value) => setState(() => _weight = value),
                        onCreateOrder: _showOrderSheet,
                        onQuickAction: _handleQuickAction,
                        onSearch: _handleSearch,
                        onNotificationsTap: _openNotificationsSheet,
                        onPointsTap: _openWalletTab,
                        onPaperBankTap: _openPaperBankSheet,
                        onMarketItemTap: _openMarketDetail,
                        onAiScanTap: () => _handleQuickAction(0),
                        onSortingGuideTap: _openSortingTip,
                        onStationCardTap: _openStationFromCard,
                        onEcoReportTap: _openEcoReportPreview,
                        onCollectorMatchTap: _openCollectorInvite,
                        onImpactStatTap: _openImpactDetail,
                        onActiveOrderTap: _openOrderTracking,
                        onMobileSearchOpen: _showMobileSearch,
                        onScheduleDetailTap: _openScheduleFromCard,
                      ),
                      _HistoryPage(
                        wasteTypes: _wasteTypes,
                        onRowTap: _openHistoryDetail,
                      ),
                      _CollectorPage(
                        onStatTap: _openCollectorStatDetail,
                        onHeatZoneTap: _openHeatZoneDetail,
                      ),
                      _WalletPage(onBalanceTap: _openPointsLedger),
                      _ProfilePage(onFieldTap: _openProfileFieldDemo),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: isWide
              ? null
              : NavigationBar(
                  selectedIndex: _tab,
                  onDestinationSelected: _setTab,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: 'Trang chủ',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.history_rounded),
                      label: 'Lịch sử',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.map_outlined),
                      selectedIcon: Icon(Icons.map_rounded),
                      label: 'Thu mua',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                      label: 'Ví Xanh',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings_rounded),
                      label: 'Cài đặt',
                    ),
                  ],
                ),
        );
      },
    );
  }

  void _setTab(int value) {
    ecoLightTap();
    setState(() => _tab = value);
  }

  void _showOrderSheet() {
    ecoLightTap();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrderSheet(
        selectedWaste: _wasteTypes[_selectedWaste],
        weight: _weight,
        total: (_wasteTypes[_selectedWaste].price * _weight).round(),
        onSubmitted: () async {
          setState(() => _hasActiveOrder = true);
          
          try {
            await _orderRepo.createOrder({
              'wasteType': _wasteTypes[_selectedWaste].name,
              'weight': _weight,
              'totalPrice': (_wasteTypes[_selectedWaste].price * _weight).round(),
              'status': 'pending',
              'userId': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
            });
            
            if (mounted) {
              _showToast('Đã phát tín hiệu lên Firebase. Hệ thống đang ghép người thu gom.');
            }
          } catch (e) {
            setState(() => _hasActiveOrder = false);
            if (mounted) {
              _showToast('Lỗi gửi đơn: $e', icon: Icons.error_outline_rounded);
            }
          }
        },
      ),
    );
  }

  void _handleSearch(String query) {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      showEcoSnackBar(
        context,
        'Nhập từ khóa để tìm giá, trạm hoặc cẩm nang phân loại.',
        icon: Icons.search_off_rounded,
      );
      return;
    }
    _showFeatureSheet(
      title: 'Kết quả tìm kiếm',
      icon: Icons.search_rounded,
      children: [
        const _InfoLine(
          icon: Icons.price_change_rounded,
          text: 'Giấy bìa: 4.500 - 6.000 VND/kg',
        ),
        const _InfoLine(
          icon: Icons.storefront_rounded,
          text: 'Trạm Cầu Giấy cách 1.8km, đang mở cửa',
        ),
        const _InfoLine(
          icon: Icons.menu_book_rounded,
          text: 'Cẩm nang: làm sạch, phân nhóm trước khi gọi',
        ),
      ],
    );
  }

  void _openScheduleFromCard() => _handleQuickAction(1);

  void _handleQuickAction(int index) {
    switch (index) {
      case 0:
        _showFeatureSheet(
          title: 'AI scan phế liệu',
          icon: Icons.document_scanner_rounded,
          children: const [
            _ScanPreviewCard(),
            _InfoLine(
              icon: Icons.check_circle_rounded,
              text: 'Vỏ lon bia: 90% - Nhôm',
            ),
            _InfoLine(
              icon: Icons.check_circle_rounded,
              text: 'Thùng carton: 86% - Giấy bìa',
            ),
            _InfoLine(
              icon: Icons.tips_and_updates_rounded,
              text:
                  'Gợi ý: chụp nền rõ nét, tránh trộn nhiều nhóm rác',
            ),
          ],
        );
        break;
      case 1:
        _showFeatureSheet(
          title: 'Đặt lịch gom định kỳ',
          icon: Icons.event_available_rounded,
          children: [
            const _InfoLine(
              icon: Icons.calendar_month_rounded,
              text: 'Thứ 7 hằng tuần - 09:00 đến 11:00',
            ),
            const _InfoLine(
              icon: Icons.notifications_active_rounded,
              text: 'Nhắc trước 2 giờ qua thông báo app',
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _showToast(
                  'Đã tạo lịch gom định kỳ vào sáng thứ 7.',
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo lịch demo'),
            ),
          ],
        );
        break;
      case 2:
        _showFeatureSheet(
          title: 'Trạm tập kết gần bạn',
          icon: Icons.storefront_rounded,
          children: const [
            _StationRow(
              name: 'Trạm Cầu Giấy',
              distance: '1.8km',
              note: 'Giấy, nhựa, kim loại',
            ),
            _StationRow(
              name: 'Kho Xanh Đống Đa',
              distance: '2.4km',
              note: 'Có cân điện tử',
            ),
            _StationRow(
              name: 'Hub Bách Khoa',
              distance: '3.1km',
              note: 'Pin, linh kiện điện tử',
            ),
          ],
        );
        break;
      case 3:
        _openWalletTab();
        break;
    }
  }

  void _openWalletTab() {
    setState(() => _tab = 3);
    _showToast(
      'Đã mở Ví Điểm Xanh.',
      icon: Icons.account_balance_wallet_rounded,
    );
  }

  Future<void> _openNotificationsSheet() {
    return showEcoInfoSheet(
      context,
      title: 'Thông báo của bạn',
      icon: Icons.notifications_active_rounded,
      body: [
        const _InfoLine(
          icon: Icons.local_shipping_rounded,
          text:
              'Đơn gom: người thu gom đang trên đường tới (demo).',
        ),
        const _InfoLine(
          icon: Icons.savings_rounded,
          text: '+12 điểm đã về ví sau phiên gom sáng nay.',
        ),
        const _InfoLine(
          icon: Icons.campaign_rounded,
          text:
              'Tuần lễ tái chế: ưu đãi đổi quà cho nhóm Giấy & Nhựa.',
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ),
      ],
    );
  }

  Future<void> _openPaperBankSheet() {
    return showEcoInfoSheet(
      context,
      title: 'Ngân hàng giấy',
      icon: Icons.library_books_rounded,
      body: const [
        _InfoLine(
          icon: Icons.groups_rounded,
          text:
              'Đăng ký tập thể: lớp học, CLB, văn phòng — gom giấy theo mốc 50kg.',
        ),
        _InfoLine(
          icon: Icons.emoji_events_rounded,
          text:
              'Thưởng điểm xanh khi đạt mốc tuần; báo cáo minh bạch cho ban quản lý.',
        ),
        _InfoLine(
          icon: Icons.schedule_rounded,
          text:
              'Có thể gắn với lịch gom định kỳ (thứ 7 sáng).',
        ),
      ],
    );
  }

  Future<void> _openMarketDetail(int index) {
    final w = _wasteTypes[index.clamp(0, _wasteTypes.length - 1)];
    return showEcoInfoSheet(
      context,
      title: w.name,
      icon: w.icon,
      body: [
        _InfoLine(
          icon: Icons.payments_rounded,
          text: 'Biên độ giá hôm nay: ${w.range} VND/kg (tham khảo).',
        ),
        _InfoLine(
          icon: Icons.balance_rounded,
          text:
              'Ước tính nhanh: ${formatVnd(w.price)} đ/kg × khối lượng thực tế khi cân.',
        ),
        _InfoLine(icon: Icons.lightbulb_outline_rounded, text: w.guide),
      ],
    );
  }

  Future<void> _openSortingTip(int index) {
    const tips = [
      'Thẻ xanh — Giấy: ép phẳng, buộc gọn, tránh ẩm mốc để được giá tốt.',
      'Thẻ vàng — Nhựa PET: xả nước, bỏ nắp riêng nếu khác loại nhựa.',
      'Thẻ đỏ — Kim loại: tách sắt / nhôm / đồng để không bị trừ giá khi cân.',
      'Thẻ tím — Điện tử: giữ nguyên khối, không tháo pin lẻ khi chưa có hướng dẫn.',
    ];
    final i = index.clamp(0, tips.length - 1);
    return showEcoInfoSheet(
      context,
      title: 'Cẩm nang phân loại',
      icon: Icons.menu_book_rounded,
      body: [
        _InfoLine(icon: Icons.check_circle_rounded, text: tips[i]),
        const SizedBox(height: 8),
        Text(
          'Mẹo: chụp ảnh rõ từng nhóm trước khi gọi thu gom để được tư vấn nhanh.',
          style: TextStyle(color: EcoColors.bodyMuted, height: 1.4),
        ),
      ],
    );
  }

  Future<void> _openStationFromCard(int index) {
    const stations = [
      (
        'Trạm Cầu Giấy',
        '1.8km',
        'Nhận giấy, nhựa, kim loại — 8:00–20:00',
      ),
      (
        'Kho Xanh Đống Đa',
        '2.4km',
        'Có cân điện tử; nhận cồng kềnh theo lịch.',
      ),
      (
        'Hub Tái Chế Bách Khoa',
        '3.1km',
        'Pin và linh kiện điện tử — mang CMND khi giao pin.',
      ),
    ];
    final i = index.clamp(0, stations.length - 1);
    final s = stations[i];
    return showEcoInfoSheet(
      context,
      title: s.$1,
      icon: Icons.storefront_rounded,
      body: [
        _InfoLine(
          icon: Icons.pin_drop_rounded,
          text: 'Khoảng cách ước tính: ${s.$2}',
        ),
        _InfoLine(icon: Icons.info_outline_rounded, text: s.$3),
        const _InfoLine(
          icon: Icons.phone_in_talk_rounded,
          text:
              'Hotline trạm (demo): gọi từ màn Chi tiết đơn sau khi ghép người thu gom.',
        ),
      ],
    );
  }

  Future<void> _openEcoReportPreview() {
    return showEcoInfoSheet(
      context,
      title: 'Báo cáo tác động tháng 5',
      icon: Icons.insights_rounded,
      body: [
        const _InfoLine(
          icon: Icons.recycling_rounded,
          text:
              '86% phân loại đúng — giảm 18,6 kg CO₂e so với vứt lẫn.',
        ),
        const _InfoLine(
          icon: Icons.park_rounded,
          text:
              'Quỹ xanh: tương đương 38 cây non được tài trợ (demo).',
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            _showToast(
              'Đã xuất file PDF demo (bản xem trước).',
              icon: Icons.file_download_done_rounded,
            );
          },
          icon: const Icon(Icons.file_download_rounded),
          label: const Text('Xuất PDF demo'),
        ),
      ],
    );
  }

  void _openCollectorInvite(int index) {
    const names = ['Cô Lan', 'Chú Hùng', 'Anh Nam'];
    final i = index.clamp(0, names.length - 1);
    _showToast(
      'Đã gửi lời mời ghép đơn tới ${names[i]} (demo). Họ sẽ phản hồi trong vài phút.',
      icon: Icons.send_rounded,
    );
  }

  Future<void> _openImpactDetail(int index) {
    const copy = [
      (
        'Đã thu hồi',
        '1.284 kg phế liệu được đưa vào tái chế có chứng từ trong hệ thống demo.',
      ),
      (
        'Người thu gom',
        '46 đối tác đang hoạt động tại khu vực Hà Nội (dữ liệu minh họa).',
      ),
      (
        'Trạm tái chế',
        '12 trạm liên thông — bạn có thể tự mang hoặc gọi thu gom tận nơi.',
      ),
      (
        'Quỹ xanh',
        '38 cây tương đương lượng CO₂ được giảm nhờ phân loại đúng (ước tính demo).',
      ),
    ];
    final i = index.clamp(0, copy.length - 1);
    final item = copy[i];
    return showEcoInfoSheet(
      context,
      title: item.$1,
      icon: Icons.eco_rounded,
      body: [
        Text(
          item.$2,
          style: const TextStyle(
            color: EcoColors.bodyMuted,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _openOrderTracking() {
    if (!_hasActiveOrder) {
      _showToast(
        'Chưa có đơn đang chạy. Hãy phát tín hiệu thu gom từ trang chủ.',
        icon: Icons.radar_rounded,
      );
      return;
    }
    showEcoInfoSheet(
      context,
      title: 'Theo dõi đơn',
      icon: Icons.route_rounded,
      body: const [
        _InfoLine(
          icon: Icons.hourglass_top_rounded,
          text:
              'Trạng thái: đang chờ người thu gom xác nhận (demo).',
        ),
        _InfoLine(
          icon: Icons.timer_rounded,
          text:
              'Dự kiến: 8–12 phút tới điểm hẹn trong bán kính Đống Đa.',
        ),
        _InfoLine(
          icon: Icons.chat_rounded,
          text:
              'Chat trong app sẽ mở khi đơn được ghép — hiện là luồng demo.',
        ),
      ],
    );
  }

  Future<void> _openHistoryDetail(
    String date,
    WasteType type,
    String weightLabel,
    String pointsLabel,
  ) {
    return showEcoInfoSheet(
      context,
      title: 'Chi tiết phiên gom',
      icon: type.icon,
      body: [
        _InfoLine(icon: Icons.calendar_today_rounded, text: date),
        _InfoLine(icon: Icons.category_rounded, text: 'Loại: ${type.name}'),
        _InfoLine(
          icon: Icons.scale_rounded,
          text: 'Khối lượng: $weightLabel',
        ),
        _InfoLine(icon: Icons.token_rounded, text: 'Điểm: $pointsLabel'),
        const _InfoLine(
          icon: Icons.receipt_long_rounded,
          text:
              'Biên nhận điện tử sẽ khả dụng khi tích hợp backend.',
        ),
      ],
    );
  }

  Future<void> _openCollectorStatDetail(int index) {
    const lines = [
      (
        'Tuyến tối ưu',
        '6,4 km — thuận chiều một chiều, tránh đoạn ùn ở giờ cao điểm (demo).',
      ),
      (
        'Đơn có thể ghép',
        '5 đơn trong bán kính 800m — gợi ý gom gộp để tăng hiệu suất.',
      ),
      (
        'Doanh thu dự kiến',
        '186.000 đ — sau khi trừ phí nền tảng và nhiên liệu ước tính.',
      ),
    ];
    final i = index.clamp(0, lines.length - 1);
    final x = lines[i];
    return showEcoInfoSheet(
      context,
      title: x.$1,
      icon: Icons.analytics_rounded,
      body: [
        Text(
          x.$2,
          style: const TextStyle(
            color: EcoColors.bodyMuted,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _openHeatZoneDetail(int index) {
    const zones = [
      (
        'KTX - Trường học',
        'Nhu cầu cao 92%: nhiều đơn nhỏ, nên ưu tiên khung 10h–15h.',
      ),
      (
        'Văn phòng Cầu Giấy',
        '74%: chủ yếu giấy và nhựa — phù hợp xe tải nhỏ.',
      ),
      (
        'Chợ dân sinh',
        '58%: hỗn hợp, cần kiểm tra ảnh trước khi nhận đơn.',
      ),
    ];
    final i = index.clamp(0, zones.length - 1);
    final z = zones[i];
    return showEcoInfoSheet(
      context,
      title: z.$1,
      icon: Icons.whatshot_rounded,
      body: [
        Text(
          z.$2,
          style: const TextStyle(
            color: EcoColors.bodyMuted,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _openPointsLedger() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Future.value();

    return showEcoInfoSheet(
      context,
      title: 'Lịch sử điểm',
      icon: Icons.history_rounded,
      body: [
        StreamBuilder<List<PointTransaction>>(
          stream: PointsRepository().watchHistory(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Text('Lỗi tải lịch sử điểm');
            }
            
            final txs = snapshot.data ?? [];
            if (txs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Chưa có giao dịch điểm nào.'),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...txs.map((tx) {
                  final dateStr = '${tx.createdAt.day.toString().padLeft(2, '0')}/${tx.createdAt.month.toString().padLeft(2, '0')}';
                  final isAdd = tx.amount > 0;
                  final sign = isAdd ? '+' : '';
                  final icon = isAdd ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded;
                  
                  return _InfoLine(
                    icon: icon,
                    text: '$sign${tx.amount} điểm — ${tx.description} $dateStr',
                  );
                }),
                const SizedBox(height: 12),
                StreamBuilder<UserProfile>(
                  stream: UserRepository().watchProfile(uid),
                  builder: (context, userSnap) {
                    final points = userSnap.data?.greenPoints ?? 0;
                    return _InfoLine(
                      icon: Icons.info_outline_rounded,
                      text: 'Số dư hiện tại: $points điểm',
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _openProfileFieldDemo(int index) {
    const fields = [
      ('Họ tên', 'Phạm Văn Minh'),
      ('Điện thoại', '0988 000 000'),
      ('Địa chỉ', 'Số 12 Chùa Bộc, Đống Đa, Hà Nội'),
      ('Xác thực', 'Đã xác thực số điện thoại'),
    ];
    final i = index.clamp(0, fields.length - 1);
    final f = fields[i];
    ecoLightTap();
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Chỉnh ${f.$1}'),
        content: Text(
          'Trường "${f.$1}" hiện là "${f.$2}". Form chỉnh sửa thật sẽ gắn sau khi có tài khoản & API.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showToast(
                'Đã lưu thay đổi (demo).',
                icon: Icons.save_rounded,
              );
            },
            child: const Text('Lưu demo'),
          ),
        ],
      ),
    );
  }

  void _showMobileSearch() {
    ecoLightTap();
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Giá, trạm, cẩm nang phân loại…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: EcoColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (q) {
                  Navigator.pop(ctx);
                  _handleSearch(q);
                },
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  final q = controller.text;
                  Navigator.pop(ctx);
                  _handleSearch(q);
                },
                child: const Text('Tìm kiếm'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeatureSheet({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    ecoLightTap();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Row(
                children: [
                  _IconTile(icon: icon, color: EcoColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  void _showToast(String message, {IconData? icon}) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final navOffset = MediaQuery.sizeOf(context).width >= 1200 ? 24.0 : 72.0;
    showEcoSnackBar(
      context,
      message,
      icon: icon,
      bottomMargin: bottomInset + navOffset,
    );
  }
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard({
    required this.wasteTypes,
    required this.selectedWaste,
    required this.weight,
    required this.hasActiveOrder,
    required this.onWasteChanged,
    required this.onWeightChanged,
    required this.onCreateOrder,
    required this.onQuickAction,
    required this.onSearch,
    required this.onNotificationsTap,
    required this.onPointsTap,
    required this.onPaperBankTap,
    required this.onMarketItemTap,
    required this.onAiScanTap,
    required this.onSortingGuideTap,
    required this.onStationCardTap,
    required this.onEcoReportTap,
    required this.onCollectorMatchTap,
    required this.onImpactStatTap,
    required this.onActiveOrderTap,
    required this.onMobileSearchOpen,
    required this.onScheduleDetailTap,
  });

  final List<WasteType> wasteTypes;
  final int selectedWaste;
  final double weight;
  final bool hasActiveOrder;
  final ValueChanged<int> onWasteChanged;
  final ValueChanged<double> onWeightChanged;
  final VoidCallback onCreateOrder;
  final ValueChanged<int> onQuickAction;
  final ValueChanged<String> onSearch;
  final VoidCallback onNotificationsTap;
  final VoidCallback onPointsTap;
  final VoidCallback onPaperBankTap;
  final ValueChanged<int> onMarketItemTap;
  final VoidCallback onAiScanTap;
  final ValueChanged<int> onSortingGuideTap;
  final ValueChanged<int> onStationCardTap;
  final VoidCallback onEcoReportTap;
  final ValueChanged<int> onCollectorMatchTap;
  final ValueChanged<int> onImpactStatTap;
  final VoidCallback onActiveOrderTap;
  final VoidCallback onMobileSearchOpen;
  final VoidCallback onScheduleDetailTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1200;
        final selected = wasteTypes[selectedWaste];
        final estimate = (selected.price * weight).round();

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _TopBar(
                isWide: isWide,
                onSearch: onSearch,
                onMobileSearchOpen: onMobileSearchOpen,
                onNotificationsTap: onNotificationsTap,
                onPointsTap: onPointsTap,
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isWide ? 28 : 16,
                8,
                isWide ? 28 : 16,
                24,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 8,
                          child: _CallPanel(
                            wasteTypes: wasteTypes,
                            selectedWaste: selectedWaste,
                            weight: weight,
                            estimate: estimate,
                            onWasteChanged: onWasteChanged,
                            onWeightChanged: onWeightChanged,
                            onCreateOrder: onCreateOrder,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Expanded(flex: 9, child: _RadarMap(height: 410)),
                      ],
                    )
                  else ...[
                    _CallPanel(
                      wasteTypes: wasteTypes,
                      selectedWaste: selectedWaste,
                      weight: weight,
                      estimate: estimate,
                      onWasteChanged: onWasteChanged,
                      onWeightChanged: onWeightChanged,
                      onCreateOrder: onCreateOrder,
                    ),
                    const SizedBox(height: 16),
                    const _RadarMap(height: 260),
                  ],
                  const SizedBox(height: 18),
                  const _ActiveOrderBanner(),
                  const SizedBox(height: 18),
                  _QuickActionsBar(onAction: onQuickAction),
                  const SizedBox(height: 18),
                  _ImpactStrip(onItemTap: onImpactStatTap),
                  const SizedBox(height: 18),
                  _PaperBankCard(progress: weight, onTap: onPaperBankTap),
                  const SizedBox(height: 16),
                  _MarketCard(
                    wasteTypes: wasteTypes,
                    onItemTap: onMarketItemTap,
                  ),
                  const SizedBox(height: 16),
                  _AiScanCard(onTap: onAiScanTap),
                  const SizedBox(height: 16),
                  _SortingGuideCard(onRowTap: onSortingGuideTap),
                  const SizedBox(height: 16),
                  _StationFinderCard(onRowTap: onStationCardTap),
                  const SizedBox(height: 16),
                  _EcoReportCard(onCardTap: onEcoReportTap),
                  const SizedBox(height: 16),
                  _CollectorMatchCard(onRowTap: onCollectorMatchTap),
                  const SizedBox(height: 16),
                  _SchedulePickupCard(onOpenDetail: onScheduleDetailTap),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.isWide,
    required this.onSearch,
    required this.onMobileSearchOpen,
    required this.onNotificationsTap,
    required this.onPointsTap,
  });

  final bool isWide;
  final ValueChanged<String> onSearch;
  final VoidCallback onMobileSearchOpen;
  final VoidCallback onNotificationsTap;
  final VoidCallback onPointsTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isWide ? 28 : 16, 16, isWide ? 28 : 16, 10),
      child: Row(
        children: [
          _MiniLogo(compact: !isWide),
          if (isWide) ...[
            const SizedBox(width: 28),
            Expanded(
              child: TextField(
                onSubmitted: onSearch,
                decoration: InputDecoration(
                  hintText:
                      'Giá thị trường, trạm tập kết, cẩm nang phân loại',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ] else ...[
            const Spacer(),
            IconButton.filledTonal(
              onPressed: onMobileSearchOpen,
              icon: const Icon(Icons.search_rounded),
              style: IconButton.styleFrom(
                backgroundColor: EcoColors.mintBg,
                foregroundColor: EcoColors.primary,
              ),
            ),
          ],
          const SizedBox(width: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onNotificationsTap,
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: _IconBadge(
                  icon: Icons.notifications_none_rounded,
                  badge: '1',
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: EcoColors.subtleBlue,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: onPointsTap,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(
                  children: [
                    const Icon(Icons.token_rounded, color: EcoColors.blue),
                    const SizedBox(width: 8),
                    StreamBuilder<UserProfile>(
                      stream: FirebaseAuth.instance.currentUser != null
                          ? UserRepository().watchProfile(FirebaseAuth.instance.currentUser!.uid)
                          : null,
                      builder: (context, snapshot) {
                        final points = snapshot.data?.greenPoints ?? 0;
                        return Text(
                          '$points Điểm',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CallPanel extends StatelessWidget {
  const _CallPanel({
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
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dọn rác thông minh - Tích lũy sống xanh',
            style: TextStyle(
              fontSize: 30,
              height: 1.12,
              fontWeight: FontWeight.w900,
              color: EcoColors.headline,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Nhập địa chỉ, chọn nhóm phế liệu và phát tín hiệu để hệ thống ghép người thu gom hoặc trạm tập kết gần nhất.',
            style: TextStyle(
              color: EcoColors.bodyMuted,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Địa chỉ',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'Ví dụ: Số 12 Chùa Bộc, Hà Nội',
              prefixIcon: const Icon(Icons.location_on_outlined),
              filled: true,
              fillColor: EcoColors.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loại phế liệu',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(wasteTypes.length, (index) {
              final waste = wasteTypes[index];
              final active = selectedWaste == index;
              return ChoiceChip(
                selected: active,
                avatar: Icon(
                  waste.icon,
                  size: 18,
                  color: active ? Colors.white : waste.color,
                ),
                label: Text(waste.name),
                onSelected: (_) => onWasteChanged(index),
                selectedColor: waste.color,
                labelStyle: TextStyle(
                  color: active ? Colors.white : EcoColors.chipText,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text(
                'Trọng lượng ước tính',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '${weight.toStringAsFixed(0)} kg',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          Slider(
            value: weight,
            min: 1,
            max: 50,
            divisions: 49,
            label: '${weight.toStringAsFixed(0)} kg',
            onChanged: onWeightChanged,
          ),
          Row(
            children: [
              const Text(
                'Tạm tính',
                style: TextStyle(color: EcoColors.bodyMuted),
              ),
              const Spacer(),
              Text(
                '${formatVnd(estimate)} đ',
                style: const TextStyle(
                  color: EcoColors.primaryDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: EcoColors.mintBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: EcoColors.mintBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: EcoColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${wasteTypes[selectedWaste].guide}. Giá tự động đối chiếu khi cân thực tế.',
                    style: const TextStyle(
                      color: EcoColors.onMint,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
              child: FilledButton.icon(
              onPressed: onCreateOrder,
              icon: const Icon(Icons.radar_rounded),
              label: const Text('PHÁT TÍN HIỆU THU GOM'),
              style: FilledButton.styleFrom(
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarMap extends StatefulWidget {
  const _RadarMap({required this.height});
  final double height;

  @override
  State<_RadarMap> createState() => _RadarMapState();
}

class _RadarMapState extends State<_RadarMap> {
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

    // Lắng nghe cập nhật vị trí liên tục
    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5, // Cập nhật sau mỗi 5 mét di chuyển
          ),
        ).listen((Position position) {
          if (mounted) {
            setState(() {
              _currentPosition = LatLng(position.latitude, position.longitude);
              // Chỉ sinh ra người thu gom ảo một lần đầu tiên khi có tọa độ
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
    return _Panel(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: widget.height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 8),
              child: Row(
                children: [
                  const Text(
                    'Radar Tìm Người Thu Gom',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: EcoColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
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
                            flags:
                                InteractiveFlag.all & ~InteractiveFlag.rotate,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.ecocollect.app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _currentPosition!,
                                width: 100,
                                height: 100,
                                child: Center(
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
                                              color: EcoColors.primary
                                                  .withOpacity(
                                                    0.2 * (1 - value),
                                                  ),
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
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              ..._collectors.map(
                                (pos) => Marker(
                                  point: pos,
                                  width: 40,
                                  height: 40,
                                  child: const _CollectorPinLive(),
                                ),
                              ),
                            ],
                          ),
                          const Positioned(
                            right: 16,
                            bottom: 16,
                            child: _MapPill(
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

class _CollectorPinLive extends StatelessWidget {
  const _CollectorPinLive();

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


class _MarketCard extends StatelessWidget {
  const _MarketCard({required this.wasteTypes, required this.onItemTap});

  final List<WasteType> wasteTypes;
  final ValueChanged<int> onItemTap;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Giá thị trường hôm nay',
            live: true,
          ),
          const SizedBox(height: 10),
          ...List.generate(4, (index) {
            final item = wasteTypes[index];
            return Column(
              children: [
                if (index > 0) const Divider(height: 14),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onItemTap(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          _IconTile(icon: item.icon, color: item.color),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  '${item.range} VND/kg',
                                  style: const TextStyle(
                                    color: EcoColors.bodyMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            index == 0
                                ? Icons.trending_up
                                : Icons.trending_flat,
                            color: index == 0
                                ? EcoColors.success
                                : EcoColors.coral,
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: EcoColors.iconMuted,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _ActiveOrderBanner extends StatefulWidget {
  const _ActiveOrderBanner();

  @override
  State<_ActiveOrderBanner> createState() => _ActiveOrderBannerState();
}

class _ActiveOrderBannerState extends State<_ActiveOrderBanner> {
  Stream<EcoOrder?>? _orderStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _orderStream = OrderRepository().watchActiveOrder(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_orderStream == null) return const SizedBox();

    return StreamBuilder<EcoOrder?>(
      stream: _orderStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox();
        }
        
        final order = snapshot.data!;
        final active = true; // Luôn true khi có order đang chạy

        void handleTap() {
          ecoLightTap();
          showEcoInfoSheet(
            context,
            title: 'Theo dõi đơn',
            icon: Icons.route_rounded,
            body: [
              _InfoLine(
                icon: Icons.hourglass_top_rounded,
                text: 'Trạng thái: ${order.status}',
              ),
              _InfoLine(
                icon: Icons.scale_rounded,
                text: 'Loại: ${order.wasteType} - ${order.weight} kg',
              ),
              const _InfoLine(
                icon: Icons.chat_rounded,
                text: 'Chat trong app sẽ mở khi đơn được ghép.',
              ),
              const SizedBox(height: 12),
              if (order.status == 'pending')
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      await OrderRepository().cancelOrder(order.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Hủy đơn', style: TextStyle(color: Colors.red)),
                  ),
                ),
            ],
          );
        }

        return Material(
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          elevation: 0,
          color: Colors.transparent,
          child: InkWell(
            onTap: handleTap,
            splashColor: Colors.white24,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [EcoColors.headline, EcoColors.primaryDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: EcoColors.primary.withOpacity(0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 620;
                    final content = [
                      _LivePulse(active: active),
                      const SizedBox(width: 12, height: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Đang xử lý tín hiệu thu gom',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Loại: ${order.wasteType} (${order.weight} kg) - Đang tìm người thu gom...',
                              style: const TextStyle(
                                color: Colors.white70,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12, height: 12),
                      OutlinedButton.icon(
                        onPressed: handleTap,
                        icon: const Icon(Icons.route_rounded, size: 18),
                        label: const Text('Theo dõi'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                      ),
                    ];
                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: content.take(3).toList()),
                          const SizedBox(height: 12),
                          content.last,
                        ],
                      );
                    }
                    return Row(children: content);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LivePulse extends StatelessWidget {
  const _LivePulse({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: .2, end: 1),
            duration: const Duration(seconds: 2),
            curve: Curves.easeOut,
            builder: (context, value, _) {
              return Container(
                width: 52 * value,
                height: 52 * value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(.18 * (1 - value)),
                ),
              );
            },
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: active ? EcoColors.success : EcoColors.iconMuted,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.radar_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ImpactStrip extends StatelessWidget {
  const _ImpactStrip({required this.onItemTap});

  final ValueChanged<int> onItemTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.recycling_rounded, '1.284 kg', 'đã thu hồi'),
      (Icons.groups_rounded, '46', 'người thu gom'),
      (Icons.storefront_rounded, '12', 'trạm tái chế'),
      (Icons.forest_rounded, '38 cây', 'quỹ xanh'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(items.length, (index) {
            final item = items[index];
            return SizedBox(
              width: compact
                  ? (constraints.maxWidth - 12) / 2
                  : (constraints.maxWidth - 36) / 4,
              child: _TappablePanel(
                onTap: () => onItemTap(index),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _IconTile(icon: item.$1, color: EcoColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$2,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            item.$3,
                            style: const TextStyle(
                              color: EcoColors.bodyMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: EcoColors.iconMuted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _QuickActionsBar extends StatelessWidget {
  const _QuickActionsBar({required this.onAction});
  final ValueChanged<int> onAction;

  @override
  Widget build(BuildContext context) {
    const actions = [
      (Icons.document_scanner_rounded, 'AI scan', 'Nhận diện rác'),
      (Icons.event_available_rounded, 'Đặt lịch', 'Gom định kỳ'),
      (Icons.storefront_rounded, 'Trạm gần', 'Tự mang ra'),
      (Icons.card_giftcard_rounded, 'Đổi điểm', 'Voucher xanh'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(actions.length, (index) {
            final action = actions[index];
            return SizedBox(
              width: compact
                  ? (constraints.maxWidth - 12) / 2
                  : (constraints.maxWidth - 36) / 4,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  onTap: () => onAction(index),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: EcoColors.border),
                    ),
                    child: Row(
                      children: [
                        _IconTile(icon: action.$1, color: EcoColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                action.$2,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                action.$3,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: EcoColors.bodyMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: EcoColors.iconMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _PaperBankCard extends StatelessWidget {
  const _PaperBankCard({required this.progress, required this.onTap});
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white30,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [EcoColors.primaryDark, EcoColors.mintLight],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Stack(
              children: [
                Positioned(
                  right: 4,
                  bottom: 10,
                  child: Icon(
                    Icons.library_books_rounded,
                    size: 92,
                    color: Colors.white.withOpacity(.34),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ngân hàng giấy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gom giấy định kỳ cho lớp, văn phòng và kí túc xá.',
                      style: TextStyle(color: Colors.white, height: 1.35),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (progress / 50).clamp(0, 1),
                        minHeight: 12,
                        backgroundColor: Colors.white.withOpacity(.55),
                        color: EcoColors.warmYellow,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tiến độ tuần này: ${progress.toStringAsFixed(0)} / 50kg',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AiScanCard extends StatelessWidget {
  const _AiScanCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _TappablePanel(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Quét & Phân Loại AI'),
          const SizedBox(height: 12),
          Container(
            height: 92,
            decoration: BoxDecoration(
              color: EcoColors.mintBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: EcoColors.mintBorder),
            ),
            child: const Center(
              child: Icon(
                Icons.add_a_photo_rounded,
                color: EcoColors.primary,
                size: 42,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const _DetectionRow(
            icon: Icons.local_drink_rounded,
            title: 'Vỏ lon bia',
            subtitle: 'Nhôm',
            score: '90%',
          ),
          const SizedBox(height: 8),
          const _DetectionRow(
            icon: Icons.inventory_2_rounded,
            title: 'Thùng carton',
            subtitle: 'Giấy bìa',
            score: '86%',
          ),
        ],
      ),
    );
  }
}

class _SortingGuideCard extends StatelessWidget {
  const _SortingGuideCard({required this.onRowTap});

  final ValueChanged<int> onRowTap;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Thẻ xanh', 'Giấy bìa ép phẳng, buộc gọn'),
      ('Thẻ vàng', 'Nhựa PET làm sạch bên trong'),
      ('Thẻ đỏ', 'Kim loại tách riêng theo nhóm'),
      ('Thẻ tím', 'Linh kiện điện tử giữ nguyên khối'),
    ];
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Cẩm nang phân loại'),
          const SizedBox(height: 10),
          ...List.generate(rows.length, (index) {
            final row = rows[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: EcoColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => onRowTap(index),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: EcoColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: '${row.$1}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                              children: [
                                TextSpan(
                                  text: row.$2,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: EcoColors.bodySecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: EcoColors.iconMuted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StationFinderCard extends StatelessWidget {
  const _StationFinderCard({required this.onRowTap});

  final ValueChanged<int> onRowTap;

  @override
  Widget build(BuildContext context) {
    const stations = [
      ('Trạm Cầu Giấy', '1.8km', 'Nhận giấy, nhựa, kim loại'),
      (
        'Kho Xanh Đống Đa',
        '2.4km',
        'Có cân điện tử, nhận cồng kềnh',
      ),
      (
        'Hub Tái Chế Bách Khoa',
        '3.1km',
        'Nhận pin và linh kiện điện tử',
      ),
    ];
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Điểm tập kết gần bạn'),
          const SizedBox(height: 12),
          ...List.generate(stations.length, (index) {
            final station = stations[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onRowTap(index),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const _IconTile(
                          icon: Icons.storefront_rounded,
                          color: EcoColors.blue,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                station.$1,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                station.$3,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: EcoColors.bodyMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          station.$2,
                          style: const TextStyle(
                            color: EcoColors.blue,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: EcoColors.iconMuted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _EcoReportCard extends StatelessWidget {
  const _EcoReportCard({required this.onCardTap});

  final VoidCallback onCardTap;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onCardTap,
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(title: 'Báo cáo tháng 5'),
                    SizedBox(height: 14),
                    Text(
                      'Tỷ lệ phân loại đúng',
                      style: TextStyle(color: EcoColors.bodyMuted),
                    ),
                    SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                      child: LinearProgressIndicator(
                        value: .86,
                        minHeight: 12,
                        backgroundColor: EcoColors.progressTrack,
                        color: EcoColors.primary,
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(
                      '86%',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Bạn đã giảm 18.6kg CO2e so với xử lý rác lẫn.',
                      style: TextStyle(
                        color: EcoColors.bodyMuted,
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Chạm để xem chi tiết',
                          style: TextStyle(
                            color: EcoColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: EcoColors.primary,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    showEcoSnackBar(
                      context,
                      'Đã tạo báo cáo demo tháng 5 (PDF).',
                      icon: Icons.file_download_done_rounded,
                    );
                  },
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text('Xuất báo cáo'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectorMatchCard extends StatelessWidget {
  const _CollectorMatchCard({required this.onRowTap});

  final ValueChanged<int> onRowTap;

  @override
  Widget build(BuildContext context) {
    const collectors = [
      ('Cô Lan', '4.9', '300m', EcoColors.primary),
      ('Chú Hùng', '4.8', '1.2km', EcoColors.blue),
      ('Anh Nam', '4.7', '1.8km', EcoColors.orange),
    ];
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Người thu gom phù hợp',
            live: true,
          ),
          const SizedBox(height: 12),
          ...List.generate(collectors.length, (index) {
            final collector = collectors[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onRowTap(index),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                collector.$4.withOpacity(.78),
                                collector.$4,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                collector.$1,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: EcoColors.warmYellow,
                                  ),
                                  Text(
                                    ' ${collector.$2} - ${collector.$3}',
                                    style: const TextStyle(
                                      color: EcoColors.bodyMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: EcoColors.mintBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Sẵn sàng',
                            style: TextStyle(
                              color: EcoColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: EcoColors.iconMuted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SchedulePickupCard extends StatelessWidget {
  const _SchedulePickupCard({required this.onOpenDetail});

  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Đặt lịch gom định kỳ'),
          const SizedBox(height: 12),
          Material(
            color: EcoColors.surfaceMuted,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: onOpenDetail,
              borderRadius: BorderRadius.circular(18),
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    _IconTile(
                      icon: Icons.calendar_month_rounded,
                      color: EcoColors.primary,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thứ 7 hằng tuần',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            'Nhắc trước 2 giờ — chạm xem chi tiết',
                            style: TextStyle(color: EcoColors.bodyMuted),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: EcoColors.iconMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Phù hợp cho văn phòng, lớp học, kí túc xá và hộ gia đình tách rác theo tuần.',
            style: TextStyle(color: EcoColors.bodyMuted, height: 1.35),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    showEcoSnackBar(
                      context,
                      'Đã tạo lịch gom định kỳ sáng thứ 7 (demo).',
                      icon: Icons.event_available_rounded,
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tạo lịch mới'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderSheet extends StatefulWidget {
  const _OrderSheet({
    required this.selectedWaste,
    required this.weight,
    required this.total,
    required this.onSubmitted,
  });

  final WasteType selectedWaste;
  final double weight;
  final int total;
  final VoidCallback onSubmitted;

  @override
  State<_OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends State<_OrderSheet> {
  bool _receiveGreenPoints = true;

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
              Material(
                color: EcoColors.surfaceMuted,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () {
                    showEcoSnackBar(
                      context,
                      'Mở camera chụp đống rác (demo). Ảnh sẽ đính kèm đơn khi tích hợp thiết bị.',
                      icon: Icons.photo_camera_rounded,
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
              SwitchListTile(
                value: _receiveGreenPoints,
                onChanged: (value) =>
                    setState(() => _receiveGreenPoints = value),
                title: const Text('Nhận bằng Điểm Xanh'),
                subtitle: const Text(
                  'Tự động cộng vào Eco-Wallet sau đối soát',
                ),
                secondary: const Icon(
                  Icons.token_rounded,
                  color: EcoColors.blue,
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onSubmitted();
                },
                icon: const Icon(Icons.done_all_rounded),
                label: const Text(
                  'Gửi đơn cho người thu gom gần nhất',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
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

class _HistoryPage extends StatefulWidget {
  const _HistoryPage({required this.wasteTypes, required this.onRowTap});

  final List<WasteType> wasteTypes;
  final void Function(String date, WasteType type, String weight, String points) onRowTap;

  @override
  State<_HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<_HistoryPage> {
  Stream<List<EcoOrder>>? _ordersStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _ordersStream = OrderRepository().watchUserOrders(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ordersStream == null) return const SizedBox();

    return StreamBuilder<List<EcoOrder>>(
      stream: _ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Lỗi tải lịch sử đơn hàng'));
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return _SimplePage(
            title: 'Sao kê rác thải',
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('Chưa có đơn thu gom nào.'),
              ),
            ),
          );
        }

        return _SimplePage(
          title: 'Sao kê rác thải',
          child: Column(
            children: orders.map((order) {
              final wType = widget.wasteTypes.firstWhere(
                (w) => w.name == order.wasteType,
                orElse: () => widget.wasteTypes[0],
              );
              final dateStr = '${order.createdAt.day.toString().padLeft(2, '0')}/${order.createdAt.month.toString().padLeft(2, '0')}/${order.createdAt.year}';
              
              return _TappablePanel(
                margin: const EdgeInsets.only(bottom: 12),
                onTap: () => widget.onRowTap(
                  dateStr,
                  wType,
                  '${order.weight} kg',
                  '+${order.earnedPoints} điểm',
                ),
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    _IconTile(icon: wType.icon, color: wType.color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${order.wasteType} - ${order.weight} kg',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            dateStr,
                            style: const TextStyle(color: EcoColors.bodyMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      order.earnedPoints > 0 ? '+${order.earnedPoints} điểm' : order.status,
                      style: const TextStyle(
                        color: EcoColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: EcoColors.iconMuted,
                      size: 22,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _CollectorPage extends StatelessWidget {
  const _CollectorPage({required this.onStatTap, required this.onHeatZoneTap});

  final ValueChanged<int> onStatTap;
  final ValueChanged<int> onHeatZoneTap;

  @override
  Widget build(BuildContext context) {
    return _SimplePage(
      title: 'Giao diện người thu mua',
      child: Column(
        children: [
          _CollectorStats(onStatTap: onStatTap),
          const SizedBox(height: 14),
          const _RadarMap(height: 330),
          const SizedBox(height: 14),
          _HeatmapPanel(onZoneTap: onHeatZoneTap),
          const SizedBox(height: 14),
          const _CollectorOrderCard(
            title: 'Đơn mới: 12kg giấy bìa',
            address: 'Ngõ 42 Chùa Bộc, Đống Đa',
            distance: 'Cách 300m',
          ),
          const SizedBox(height: 12),
          const _CollectorOrderCard(
            title: 'Đơn gộp: Nhựa PET + kim loại',
            address: 'KTX Đại học Thủy Lợi',
            distance: 'Cách 1.2km',
          ),
        ],
      ),
    );
  }
}

class _CollectorStats extends StatelessWidget {
  const _CollectorStats({required this.onStatTap});

  final ValueChanged<int> onStatTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        const stats = [
          (Icons.route_rounded, '6.4km', 'tuyến tối ưu'),
          (Icons.inventory_2_rounded, '5 đơn', 'có thể ghép'),
          (Icons.payments_rounded, '186k', 'doanh thu dự kiến'),
        ];
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(stats.length, (index) {
            final stat = stats[index];
            return SizedBox(
              width: compact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 24) / 3,
              child: _TappablePanel(
                onTap: () => onStatTap(index),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _IconTile(icon: stat.$1, color: EcoColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stat.$2,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            stat.$3,
                            style: const TextStyle(color: EcoColors.bodyMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: EcoColors.iconMuted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _HeatmapPanel extends StatelessWidget {
  const _HeatmapPanel({required this.onZoneTap});

  final ValueChanged<int> onZoneTap;

  @override
  Widget build(BuildContext context) {
    const zones = [
      ('KTX - Trường học', .92, EcoColors.primary),
      ('Văn phòng Cầu Giấy', .74, EcoColors.blue),
      ('Chợ dân sinh', .58, EcoColors.orange),
    ];
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Bản đồ nhiệt đơn gom'),
          const SizedBox(height: 12),
          ...List.generate(zones.length, (index) {
            final zone = zones[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: EcoColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => onZoneTap(index),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                zone.$1,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text(
                              '${(zone.$2 * 100).round()}%',
                              style: TextStyle(
                                color: zone.$3,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: EcoColors.iconMuted,
                              size: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: zone.$2,
                            minHeight: 10,
                            color: zone.$3,
                            backgroundColor: EcoColors.progressTrack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _WalletPage extends StatefulWidget {
  const _WalletPage({required this.onBalanceTap});
  final VoidCallback onBalanceTap;

  @override
  State<_WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<_WalletPage> {
  Stream<UserProfile>? _profileStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _profileStream = UserRepository().watchProfile(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_profileStream == null) return const SizedBox();

    return StreamBuilder<UserProfile>(
      stream: _profileStream,
      builder: (context, snapshot) {
        final points = snapshot.data?.greenPoints ?? 0;

        return _SimplePage(
          title: 'Ví Điểm Xanh',
          child: Column(
            children: [
              Material(
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: widget.onBalanceTap,
                  child: Ink(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [EcoColors.blue, EcoColors.sky],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Số dư hiện tại',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white70,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$points Điểm',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Chạm để xem lịch sử điểm',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const _RewardTile(
                icon: Icons.local_cafe_rounded,
                title: 'Voucher cafe',
                points: '80 điểm',
              ),
              const _RewardTile(
                icon: Icons.phone_android_rounded,
                title: 'Nạp điện thoại',
                points: '120 điểm',
              ),
              const _RewardTile(
                icon: Icons.forest_rounded,
                title: 'Góp quỹ trồng cây',
                points: '50 điểm',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfilePage extends StatefulWidget {
  const _ProfilePage({required this.onFieldTap});
  final ValueChanged<int> onFieldTap;

  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  Stream<UserProfile>? _profileStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _profileStream = UserRepository().watchProfile(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_profileStream == null) return const SizedBox();

    return StreamBuilder<UserProfile>(
      stream: _profileStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Lỗi tải thông tin cá nhân'));
        }

        final profile = snapshot.data!;

        return _SimplePage(
          title: 'Hồ sơ cá nhân',
          child: Column(
            children: [
              _ProfileField(
                index: 0,
                icon: Icons.person_rounded,
                text: profile.displayName,
                onTap: widget.onFieldTap,
              ),
              _ProfileField(
                index: 1,
                icon: Icons.phone_rounded,
                text: profile.phone,
                onTap: widget.onFieldTap,
              ),
              _ProfileField(
                index: 2,
                icon: Icons.location_on_rounded,
                text: profile.address,
                onTap: widget.onFieldTap,
              ),
              _ProfileField(
                index: 3,
                icon: Icons.verified_user_rounded,
                text: 'UID: ${profile.uid.substring(0, 8)}...',
                onTap: widget.onFieldTap,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                  },
                  icon: const Icon(Icons.logout_rounded, color: EcoColors.orange),
                  label: const Text(
                    'Đăng xuất',
                    style: TextStyle(color: EcoColors.orange, fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: EcoColors.orange, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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

class _SideNav extends StatelessWidget {
  const _SideNav({required this.tab, required this.onChanged});
  final int tab;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Trang chủ'),
      (Icons.history_rounded, 'Lịch sử'),
      (Icons.map_rounded, 'Thu mua'),
      (Icons.account_balance_wallet_rounded, 'Ví Xanh'),
      (Icons.settings_rounded, 'Cài đặt'),
    ];
    return Container(
      width: 128,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: EcoColors.border)),
      ),
      child: Column(
        children: [
          const _MiniLogo(compact: true),
          const SizedBox(height: 24),
          ...List.generate(items.length, (index) {
            final item = items[index];
            final active = index == tab;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => onChanged(index),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: active ? EcoColors.mintBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        item.$1,
                        color: active
                            ? EcoColors.primary
                            : EcoColors.navInactive,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.$2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: active
                              ? EcoColors.primary
                              : EcoColors.navInactive,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SimplePage extends StatelessWidget {
  const _SimplePage({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class _CollectorOrderCard extends StatelessWidget {
  const _CollectorOrderCard({
    required this.title,
    required this.address,
    required this.distance,
  });

  final String title;
  final String address;
  final String distance;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          const _IconTile(
            icon: Icons.inventory_rounded,
            color: EcoColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  '$address - $distance',
                  style: const TextStyle(color: EcoColors.bodyMuted),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () {
              showEcoSnackBar(
                context,
                'Đã nhận đơn: $title. Mở chỉ đường (demo).',
                icon: Icons.navigation_rounded,
              );
            },
            icon: const Icon(Icons.navigation_rounded, size: 18),
            label: const Text('Nhận'),
          ),
        ],
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({
    required this.icon,
    required this.title,
    required this.points,
  });

  final IconData icon;
  final String title;
  final String points;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showEcoSnackBar(
          context,
          'Đã gửi yêu cầu đổi $title ($points). Voucher demo sẽ tới mục Thông báo.',
          icon: Icons.card_giftcard_rounded,
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: _Panel(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            _IconTile(icon: icon, color: EcoColors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              points,
              style: TextStyle(
                color: EcoColors.blue,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.index,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final int index;
  final IconData icon;
  final String text;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return _TappablePanel(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => onTap(index),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          _IconTile(icon: icon, color: EcoColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const Icon(Icons.edit_outlined, color: EcoColors.iconMuted, size: 20),
        ],
      ),
    );
  }
}

class _DetectionRow extends StatelessWidget {
  const _DetectionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.score,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String score;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconTile(icon: icon, color: EcoColors.coral),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(
                subtitle,
                style: const TextStyle(color: EcoColors.bodyMuted),
              ),
            ],
          ),
        ),
        Text(
          score,
          style: const TextStyle(
            color: EcoColors.primary,
            fontWeight: FontWeight.w900,
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: EcoColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: EcoColors.onMint,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanPreviewCard extends StatelessWidget {
  const _ScanPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: EcoColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EcoColors.sheetHandle),
      ),
      child: Stack(
        children: [
          const Center(
            child: Icon(
              Icons.camera_alt_rounded,
              color: EcoColors.primary,
              size: 52,
            ),
          ),
          const Positioned(
            left: 28,
            top: 30,
            child: _ScanBox(label: 'Nhựa PET', color: EcoColors.blue),
          ),
          const Positioned(
            right: 24,
            bottom: 30,
            child: _ScanBox(label: 'Kim loại', color: EcoColors.coral),
          ),
        ],
      ),
    );
  }
}

class _ScanBox extends StatelessWidget {
  const _ScanBox({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _StationRow extends StatelessWidget {
  const _StationRow({
    required this.name,
    required this.distance,
    required this.note,
  });

  final String name;
  final String distance;
  final String note;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const _IconTile(
            icon: Icons.storefront_rounded,
            color: EcoColors.blue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(note, style: const TextStyle(color: EcoColors.bodyMuted)),
              ],
            ),
          ),
          Text(
            distance,
            style: const TextStyle(
              color: EcoColors.blue,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TappablePanel extends StatelessWidget {
  const _TappablePanel({
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
  });

  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: EcoColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.06),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: EcoColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.live = false});
  final String title;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ),
        if (live) ...[
          const Icon(Icons.circle, size: 9, color: EcoColors.success),
          const SizedBox(width: 5),
          const Text(
            'Live',
            style: TextStyle(
              color: EcoColors.bodyMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.badge});
  final IconData icon;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon),
        ),
        Positioned(
          right: -2,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: EcoColors.coral,
              shape: BoxShape.circle,
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniLogo extends StatelessWidget {
  const _MiniLogo({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 50 : 44,
          height: compact ? 50 : 44,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [EcoColors.logoGreenLight, EcoColors.logoGreenDark],
            ),
          ),
          child: const Icon(Icons.eco_rounded, color: Colors.white),
        ),
        if (!compact) ...[
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EcoCollect',
                style: TextStyle(
                  color: EcoColors.primaryDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Đồng nát Online',
                style: TextStyle(color: EcoColors.bodyMuted, height: 1),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MapPill extends StatelessWidget {
  const _MapPill({required this.icon, required this.text, required this.color});
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
