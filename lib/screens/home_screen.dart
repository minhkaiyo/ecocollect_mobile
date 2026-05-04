import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  int _selectedWaste = 0;
  double _weight = 12;

  final List<WasteType> _wasteTypes = const [
    WasteType(
      'Giấy',
      '4.500 - 6.000',
      5200,
      Icons.article_rounded,
      Color(0xFF119F63),
      'Ép phẳng, buộc gọn',
    ),
    WasteType(
      'Nhựa',
      '7.000 - 9.500',
      8200,
      Icons.water_drop_rounded,
      Color(0xFF1F73D6),
      'Làm sạch, tháo nhãn',
    ),
    WasteType(
      'Kim loại',
      '12.000 - 15.000',
      13500,
      Icons.view_in_ar_rounded,
      Color(0xFF68717A),
      'Tách theo nhóm kim loại',
    ),
    WasteType(
      'Điện tử',
      'Theo món',
      25000,
      Icons.memory_rounded,
      Color(0xFF7D55C7),
      'Bảo quản nguyên khối',
    ),
    WasteType(
      'Cồng kềnh',
      'Hẹn giá',
      0,
      Icons.chair_rounded,
      Color(0xFFE78B25),
      'Chụp ảnh trước khi gửi',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 920;

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
                    onWasteChanged: (value) =>
                        setState(() => _selectedWaste = value),
                    onWeightChanged: (value) => setState(() => _weight = value),
                    onCreateOrder: _showOrderSheet,
                  ),
                  _HistoryPage(wasteTypes: _wasteTypes),
                  const _CollectorPage(),
                  const _WalletPage(),
                  const _ProfilePage(),
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
  }

  void _setTab(int value) => setState(() => _tab = value);

  void _showOrderSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrderSheet(
        selectedWaste: _wasteTypes[_selectedWaste],
        weight: _weight,
        total: (_wasteTypes[_selectedWaste].price * _weight).round(),
      ),
    );
  }
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard({
    required this.wasteTypes,
    required this.selectedWaste,
    required this.weight,
    required this.onWasteChanged,
    required this.onWeightChanged,
    required this.onCreateOrder,
  });

  final List<WasteType> wasteTypes;
  final int selectedWaste;
  final double weight;
  final ValueChanged<int> onWasteChanged;
  final ValueChanged<double> onWeightChanged;
  final VoidCallback onCreateOrder;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 920;
    final selected = wasteTypes[selectedWaste];
    final estimate = (selected.price * weight).round();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _TopBar(isWide: isWide)),
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
              const _QuickActionsBar(),
              const SizedBox(height: 18),
              const _ImpactStrip(),
              const SizedBox(height: 18),
              _ResponsiveGrid(
                children: [
                  _PaperBankCard(progress: weight),
                  _MarketCard(wasteTypes: wasteTypes),
                  const _AiScanCard(),
                  const _SortingGuideCard(),
                  const _StationFinderCard(),
                  const _EcoReportCard(),
                  const _CollectorMatchCard(),
                  const _SchedulePickupCard(),
                ],
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isWide ? 28 : 16, 16, isWide ? 28 : 16, 10),
      child: Row(
        children: [
          const _MiniLogo(),
          if (isWide) ...[
            const SizedBox(width: 28),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Giá thị trường, trạm tập kết, cẩm nang phân loại',
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
          ] else
            const Spacer(),
          const SizedBox(width: 14),
          _IconBadge(icon: Icons.notifications_none_rounded, badge: '1'),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(Icons.token_rounded, color: Color(0xFF1F73D6)),
                SizedBox(width: 8),
                Text('150 Điểm', style: TextStyle(fontWeight: FontWeight.w800)),
              ],
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
              color: Color(0xFF102A24),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Nhập địa chỉ, chọn nhóm phế liệu và phát tín hiệu để hệ thống ghép người thu gom hoặc trạm tập kết gần nhất.',
            style: TextStyle(
              color: Color(0xFF60736D),
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
              fillColor: const Color(0xFFF8FAF9),
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
                  color: active ? Colors.white : const Color(0xFF20322D),
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
                style: TextStyle(color: Color(0xFF60736D)),
              ),
              const Spacer(),
              Text(
                '${_money(estimate)} đ',
                style: const TextStyle(
                  color: Color(0xFF0B6B4B),
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
              color: const Color(0xFFEAF8F1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFBFE8D4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFF119F63)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${wasteTypes[selectedWaste].guide}. Giá tự động đối chiếu khi cân thực tế.',
                    style: const TextStyle(
                      color: Color(0xFF31524A),
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
            width: double.infinity,
            height: 62,
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

class _RadarMap extends StatelessWidget {
  const _RadarMap({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final collectors = const [
      Offset(.22, .68),
      Offset(.36, .42),
      Offset(.62, .36),
      Offset(.76, .55),
      Offset(.68, .76),
      Offset(.88, .24),
    ];

    return _Panel(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: height,
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
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Live',
                    style: TextStyle(
                      color: Color(0xFF60736D),
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
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _MapPainter())),
                    Positioned.fill(
                      child: CustomPaint(painter: _RoutePainter()),
                    ),
                    Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: .35, end: 1),
                        duration: const Duration(seconds: 2),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 150 * value,
                                height: 150 * value,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF119F63,
                                  ).withOpacity(.18 * (1 - value)),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              child!,
                            ],
                          );
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF119F63),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 5),
                          ),
                        ),
                      ),
                    ),
                    ...collectors.map((point) => _CollectorPin(point: point)),
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: _MapPill(
                        icon: Icons.place_rounded,
                        text: 'Trạm tập kết',
                        color: const Color(0xFF119F63),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 14,
                      child: Text(
                        'EcoMap',
                        style: TextStyle(
                          color: Colors.black.withOpacity(.35),
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
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

class _CollectorPin extends StatelessWidget {
  const _CollectorPin({required this.point});

  final Offset point;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(point.dx * 2 - 1, point.dy * 2 - 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
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
              color: Color(0xFF119F63),
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'Cách 1.2km',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1050
            ? 4
            : constraints.maxWidth >= 720
            ? 2
            : 1;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: constraints.maxWidth >= 1050 ? 1.15 : 1.55,
          children: children,
        );
      },
    );
  }
}

class _MarketCard extends StatelessWidget {
  const _MarketCard({required this.wasteTypes});

  final List<WasteType> wasteTypes;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Giá thị trường hôm nay', live: true),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (_, __) => const Divider(height: 14),
              itemBuilder: (context, index) {
                final item = wasteTypes[index];
                return Row(
                  children: [
                    _IconTile(icon: item.icon, color: item.color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            '${item.range} VND/kg',
                            style: const TextStyle(color: Color(0xFF60736D)),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      index == 0 ? Icons.trending_up : Icons.trending_flat,
                      color: index == 0
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFE76F51),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveOrderBanner extends StatelessWidget {
  const _ActiveOrderBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF102A24), Color(0xFF0B6B4B)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF119F63).withOpacity(.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final content = [
            const _LivePulse(),
            const SizedBox(width: 12, height: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đang ghép đơn quanh Đống Đa',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '3 người thu gom sẵn sàng, thời gian đến dự kiến 8-12 phút.',
                    style: TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12, height: 12),
            OutlinedButton.icon(
              onPressed: () {},
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
    );
  }
}

class _LivePulse extends StatelessWidget {
  const _LivePulse();

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
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
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
  const _ImpactStrip();

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
          children: items.map((item) {
            return SizedBox(
              width: compact
                  ? (constraints.maxWidth - 12) / 2
                  : (constraints.maxWidth - 36) / 4,
              child: _Panel(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _IconTile(icon: item.$1, color: const Color(0xFF119F63)),
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
                              color: Color(0xFF60736D),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _QuickActionsBar extends StatelessWidget {
  const _QuickActionsBar();

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
          children: actions.map((action) {
            return SizedBox(
              width: compact
                  ? (constraints.maxWidth - 12) / 2
                  : (constraints.maxWidth - 36) / 4,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE1E9E6)),
                    ),
                    child: Row(
                      children: [
                        _IconTile(
                          icon: action.$1,
                          color: const Color(0xFF119F63),
                        ),
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
                                  color: Color(0xFF60736D),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF9AA8A3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _PaperBankCard extends StatelessWidget {
  const _PaperBankCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF0B6B4B), Color(0xFF45C184)],
        ),
      ),
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
                'Gom giấy định kỳ cho lớp, văn phòng và ký túc xá.',
                style: TextStyle(color: Colors.white, height: 1.35),
              ),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (progress / 50).clamp(0, 1),
                  minHeight: 12,
                  backgroundColor: Colors.white.withOpacity(.55),
                  color: const Color(0xFFFFC857),
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
    );
  }
}

class _AiScanCard extends StatelessWidget {
  const _AiScanCard();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Quét & Phân Loại AI'),
          const SizedBox(height: 12),
          Container(
            height: 92,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFBFE8D4)),
            ),
            child: const Center(
              child: Icon(
                Icons.add_a_photo_rounded,
                color: Color(0xFF119F63),
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
  const _SortingGuideCard();

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
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF119F63),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: '${row.$1}: ',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                        children: [
                          TextSpan(
                            text: row.$2,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF52645F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StationFinderCard extends StatelessWidget {
  const _StationFinderCard();

  @override
  Widget build(BuildContext context) {
    const stations = [
      ('Trạm Cầu Giấy', '1.8km', 'Nhận giấy, nhựa, kim loại'),
      ('Kho Xanh Đống Đa', '2.4km', 'Có cân điện tử, nhận cồng kềnh'),
      ('Hub Tái chế Bách Khoa', '3.1km', 'Nhận pin và linh kiện điện tử'),
    ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Điểm tập kết gần bạn'),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final station = stations[index];
                return Row(
                  children: [
                    const _IconTile(
                      icon: Icons.storefront_rounded,
                      color: Color(0xFF1F73D6),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            station.$1,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            station.$3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF60736D)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      station.$2,
                      style: const TextStyle(
                        color: Color(0xFF1F73D6),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EcoReportCard extends StatelessWidget {
  const _EcoReportCard();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Báo cáo tháng 5'),
          const SizedBox(height: 14),
          const Text(
            'Tỷ lệ phân loại đúng',
            style: TextStyle(color: Color(0xFF60736D)),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(
              value: .86,
              minHeight: 12,
              backgroundColor: Color(0xFFE1E9E6),
              color: Color(0xFF119F63),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '86%',
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
          ),
          const Text(
            'Bạn đã giảm 18.6kg CO2e so với xử lý rác lẫn.',
            style: TextStyle(color: Color(0xFF60736D), height: 1.35),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
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
  const _CollectorMatchCard();

  @override
  Widget build(BuildContext context) {
    const collectors = [
      ('Cô Lan', '4.9', '300m', Color(0xFF119F63)),
      ('Chú Hùng', '4.8', '1.2km', Color(0xFF1F73D6)),
      ('Anh Nam', '4.7', '1.8km', Color(0xFFE78B25)),
    ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Người thu gom phù hợp', live: true),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: collectors.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final collector = collectors[index];
                return Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [collector.$4.withOpacity(.78), collector.$4],
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
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: Color(0xFFFFC857),
                              ),
                              Text(
                                ' ${collector.$2} - ${collector.$3}',
                                style: const TextStyle(
                                  color: Color(0xFF60736D),
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
                        color: const Color(0xFFEAF8F1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Sẵn sàng',
                        style: TextStyle(
                          color: Color(0xFF119F63),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SchedulePickupCard extends StatelessWidget {
  const _SchedulePickupCard();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Đặt lịch gom định kỳ'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8F7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                _IconTile(
                  icon: Icons.calendar_month_rounded,
                  color: Color(0xFF119F63),
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
                        'Nhắc trước 2 giờ',
                        style: TextStyle(color: Color(0xFF60736D)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Phù hợp cho văn phòng, lớp học, ký túc xá và hộ gia đình tích rác theo tuần.',
            style: TextStyle(color: Color(0xFF60736D), height: 1.35),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {},
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

class _OrderSheet extends StatelessWidget {
  const _OrderSheet({
    required this.selectedWaste,
    required this.weight,
    required this.total,
  });

  final WasteType selectedWaste;
  final double weight;
  final int total;

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
                    color: const Color(0xFFD7E2DE),
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
                    icon: selectedWaste.icon,
                    label: selectedWaste.name,
                  ),
                  _ConfirmChip(
                    icon: Icons.scale_rounded,
                    label: '${weight.toStringAsFixed(0)} kg',
                  ),
                  _ConfirmChip(
                    icon: Icons.payments_rounded,
                    label: '${_money(total)} đ',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                height: 142,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8F7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD7E2DE)),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_rounded,
                      size: 44,
                      color: Color(0xFF119F63),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Chụp ảnh đống rác',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Giúp người gom chuẩn bị xe và cân phù hợp',
                      style: TextStyle(color: Color(0xFF60736D)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SwitchListTile(
                value: true,
                onChanged: (_) {},
                title: const Text('Nhận bằng Điểm Xanh'),
                subtitle: const Text(
                  'Tự động cộng vào Eco-Wallet sau đối soát',
                ),
                secondary: const Icon(
                  Icons.token_rounded,
                  color: Color(0xFF1F73D6),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.done_all_rounded),
                label: const Text('Gửi đơn cho người thu gom gần nhất'),
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

class _HistoryPage extends StatelessWidget {
  const _HistoryPage({required this.wasteTypes});

  final List<WasteType> wasteTypes;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('03/05/2026', wasteTypes[0], '8 kg', '+42 điểm'),
      ('28/04/2026', wasteTypes[1], '5 kg', '+36 điểm'),
      ('21/04/2026', wasteTypes[2], '2 kg', '+54 điểm'),
    ];
    return _SimplePage(
      title: 'Sao kê rác thải',
      child: Column(
        children: rows
            .map(
              (row) => _Panel(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    _IconTile(icon: row.$2.icon, color: row.$2.color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${row.$2.name} - ${row.$3}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            row.$1,
                            style: const TextStyle(color: Color(0xFF60736D)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      row.$4,
                      style: const TextStyle(
                        color: Color(0xFF119F63),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CollectorPage extends StatelessWidget {
  const _CollectorPage();

  @override
  Widget build(BuildContext context) {
    return _SimplePage(
      title: 'Giao diện người thu mua',
      child: Column(
        children: [
          const _CollectorStats(),
          const SizedBox(height: 14),
          const _RadarMap(height: 330),
          const SizedBox(height: 14),
          const _HeatmapPanel(),
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
  const _CollectorStats();

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
          children: stats.map((stat) {
            return SizedBox(
              width: compact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 24) / 3,
              child: _Panel(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _IconTile(icon: stat.$1, color: const Color(0xFF119F63)),
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
                            style: const TextStyle(color: Color(0xFF60736D)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _HeatmapPanel extends StatelessWidget {
  const _HeatmapPanel();

  @override
  Widget build(BuildContext context) {
    const zones = [
      ('KTX - Trường học', .92, Color(0xFF119F63)),
      ('Văn phòng Cầu Giấy', .74, Color(0xFF1F73D6)),
      ('Chợ dân sinh', .58, Color(0xFFE78B25)),
    ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: 'Bản đồ nhiệt đơn gom'),
          const SizedBox(height: 12),
          ...zones.map(
            (zone) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          zone.$1,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        '${(zone.$2 * 100).round()}%',
                        style: TextStyle(
                          color: zone.$3,
                          fontWeight: FontWeight.w900,
                        ),
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
                      backgroundColor: const Color(0xFFE1E9E6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletPage extends StatelessWidget {
  const _WalletPage();

  @override
  Widget build(BuildContext context) {
    return _SimplePage(
      title: 'Ví Điểm Xanh',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF1F73D6), Color(0xFF39B7E8)],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Số dư hiện tại',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                SizedBox(height: 6),
                Text(
                  '150 Điểm',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
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
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    return const _SimplePage(
      title: 'Hồ sơ cá nhân',
      child: Column(
        children: [
          _ProfileField(icon: Icons.person_rounded, text: 'Nguyễn Minh'),
          _ProfileField(icon: Icons.phone_rounded, text: '0988 000 000'),
          _ProfileField(
            icon: Icons.location_on_rounded,
            text: 'Số 12 Chùa Bộc, Đống Đa, Hà Nội',
          ),
          _ProfileField(
            icon: Icons.verified_user_rounded,
            text: 'Đã xác thực số điện thoại',
          ),
        ],
      ),
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
        border: Border(right: BorderSide(color: Color(0xFFE1E9E6))),
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
                    color: active
                        ? const Color(0xFFEAF8F1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        item.$1,
                        color: active
                            ? const Color(0xFF119F63)
                            : const Color(0xFF7B8783),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.$2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: active
                              ? const Color(0xFF119F63)
                              : const Color(0xFF7B8783),
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
            color: Color(0xFF119F63),
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
                  style: const TextStyle(color: Color(0xFF60736D)),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () {},
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
    return _Panel(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _IconTile(icon: icon, color: const Color(0xFF1F73D6)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            points,
            style: const TextStyle(
              color: Color(0xFF1F73D6),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _IconTile(icon: icon, color: const Color(0xFF119F63)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
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
        _IconTile(icon: icon, color: const Color(0xFFE76F51)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              Text(subtitle, style: const TextStyle(color: Color(0xFF60736D))),
            ],
          ),
        ),
        Text(
          score,
          style: const TextStyle(
            color: Color(0xFF119F63),
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
      avatar: Icon(icon, color: const Color(0xFF119F63)),
      label: Text(label),
      labelStyle: const TextStyle(fontWeight: FontWeight.w800),
      backgroundColor: const Color(0xFFEAF8F1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        border: Border.all(color: const Color(0xFFE1E9E6)),
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
          const Icon(Icons.circle, size: 9, color: Color(0xFF22C55E)),
          const SizedBox(width: 5),
          const Text(
            'Live',
            style: TextStyle(
              color: Color(0xFF60736D),
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
              color: Color(0xFFE76F51),
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
              colors: [Color(0xFF7AD34F), Color(0xFF0B8D5B)],
            ),
          ),
          child: const Icon(Icons.eco_rounded, color: Colors.white),
        ),
        if (!compact) ...[
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EcoCollect',
                style: TextStyle(
                  color: Color(0xFF0B6B4B),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Đồng nát Online',
                style: TextStyle(color: Color(0xFF60736D), height: 1),
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

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFEAF0F4);
    canvas.drawRect(Offset.zero & size, bg);

    final water = Paint()..color = const Color(0xFFD5E6F6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .58,
          -20,
          size.width * .22,
          size.height + 70,
        ),
        const Radius.circular(80),
      ),
      water,
    );

    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final smallRoad = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 7; i++) {
      final y = size.height * (i / 6);
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 70), road);
    }
    for (var i = 0; i < 6; i++) {
      final x = size.width * (i / 5);
      canvas.drawLine(Offset(x, 0), Offset(x + 90, size.height), smallRoad);
    }

    final park = Paint()..color = const Color(0xFFDDEFE4);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .22, size.height * .26),
        width: size.width * .24,
        height: size.height * .18,
      ),
      park,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .82, size.height * .72),
        width: size.width * .26,
        height: size.height * .16,
      ),
      park,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()
      ..color = Colors.black.withOpacity(.08)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final route = Paint()
      ..color = const Color(0xFF119F63)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * .22, size.height * .68)
      ..cubicTo(
        size.width * .34,
        size.height * .55,
        size.width * .44,
        size.height * .44,
        size.width * .5,
        size.height * .5,
      )
      ..cubicTo(
        size.width * .58,
        size.height * .58,
        size.width * .68,
        size.height * .58,
        size.width * .76,
        size.height * .55,
      )
      ..cubicTo(
        size.width * .82,
        size.height * .52,
        size.width * .86,
        size.height * .36,
        size.width * .88,
        size.height * .24,
      );

    canvas.drawPath(path, shadow);
    canvas.drawPath(path, route);

    final dash = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 7; i++) {
      final t = i / 6;
      final point = Offset(
        size.width * (.22 + (.88 - .22) * t),
        size.height * (.68 + (.24 - .68) * t),
      );
      canvas.drawCircle(point, 2.4, dash);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WasteType {
  const WasteType(
    this.name,
    this.range,
    this.price,
    this.icon,
    this.color,
    this.guide,
  );

  final String name;
  final String range;
  final int price;
  final IconData icon;
  final Color color;
  final String guide;
}

String _money(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final fromEnd = text.length - i;
    buffer.write(text[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) {
      buffer.write('.');
    }
  }
  return buffer.toString();
}
