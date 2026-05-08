import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../models/waste_type.dart';
import '../theme/eco_colors.dart';
import '../ui/app_feedback.dart';
import '../repositories/order_repository.dart';
import '../repositories/market_price_repository.dart';
import '../repositories/paper_bank_repository.dart';

import 'home/pages/home_dashboard.dart';
import 'home/pages/history_page.dart';
import 'home/pages/collector_page.dart';
import 'home/pages/wallet_page.dart';
import 'home/pages/profile_page.dart';
import 'home/widgets/side_nav.dart';
import 'home/widgets/order_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  int _selectedWaste = 0;
  double _weight = 12;
  LatLng? _currentLocation;
  List<WasteType> _wasteTypes = [];
  double _paperBankProgress = 0;

  final _orderRepo = OrderRepository();
  final _marketPriceRepo = MarketPriceRepository();
  final _paperBankRepo = PaperBankRepository();

  @override
  void initState() {
    super.initState();
    _initStreams();
    _getCurrentLocation();
  }

  void _initStreams() {
    _marketPriceRepo.watchPrices().listen((list) {
      if (mounted) setState(() => _wasteTypes = list);
    });
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _paperBankRepo.watchUserProgress(uid).listen((p) {
        if (mounted) setState(() => _paperBankProgress = p);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));
    } catch (_) {}
  }

  void _setTab(int value) {
    ecoLightTap();
    setState(() => _tab = value);
  }

  void _handleSearch(String q) {
    _showToast('Tìm kiếm: $q (luồng tìm kiếm sẽ hiển thị kết quả lọc).');
  }

  void _showToast(String message, {IconData? icon}) {
    showEcoSnackBar(context, message, icon: icon);
  }

  void _showOrderSheet() {
    if (_wasteTypes.isEmpty) return;
    ecoLightTap();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OrderSheet(
        selectedWaste: _wasteTypes[_selectedWaste],
        weight: _weight,
        total: (_wasteTypes[_selectedWaste].price * _weight).round(),
        onSubmitted: () async {
          try {
            await _orderRepo.createOrder({
              'wasteType': _wasteTypes[_selectedWaste].name,
              'weight': _weight,
              'totalPrice': (_wasteTypes[_selectedWaste].price * _weight).round(),
              'status': 'pending',
              'userId': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
            });
            if (mounted) _showToast('Đã phát tín hiệu thu gom!');
          } catch (e) {
            if (mounted) _showToast('Lỗi: $e', icon: Icons.error_outline_rounded);
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1200;

        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                if (isWide) HomeSideNav(tab: _tab, onChanged: _setTab),
                Expanded(
                  child: IndexedStack(
                    index: _tab,
                    children: [
                      HomeDashboard(
                        isWide: isWide,
                        wasteTypes: _wasteTypes,
                        selectedWaste: _selectedWaste,
                        weight: _weight,
                        estimate: (_wasteTypes[_selectedWaste].price * _weight).round(),
                        paperBankProgress: _paperBankProgress,
                        onSearch: _handleSearch,
                        onMobileSearchOpen: () {}, // Implement mobile search sheet if needed
                        onNotificationsTap: () {}, // Implement notifications sheet
                        onPointsTap: () => _setTab(3),
                        onWasteChanged: (v) => setState(() => _selectedWaste = v),
                        onWeightChanged: (v) => setState(() => _weight = v),
                        onCreateOrder: _showOrderSheet,
                        onQuickAction: (i) {},
                        onImpactDetail: (i) {},
                        onMarketItemTap: (i) {},
                        onPaperBankTap: () {},
                        onAiScanTap: () {},
                        onSortingGuideTap: (i) {},
                        onStationTap: (i) {},
                        onEcoReportTap: () {},
                        onCollectorInvite: (i) {},
                        onSchedulePickupTap: () {},
                      ),
                      HistoryPage(
                        wasteTypes: _wasteTypes,
                        onOrderTap: (order, type) {},
                      ),
                      const CollectorPage(),
                      const WalletPage(),
                      ProfilePage(onFieldTap: (i) {}),
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
                  destinations: const [
                    NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
                    NavigationDestination(icon: Icon(Icons.history_rounded), label: 'Lịch sử'),
                    NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Thu mua'),
                    NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Ví Xanh'),
                    NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Cài đặt'),
                  ],
                ),
        );
      },
    );
  }
}
