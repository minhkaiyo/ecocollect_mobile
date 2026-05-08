import 'package:flutter/material.dart';
import '../../../models/waste_type.dart';
import '../widgets/top_bar.dart';
import '../widgets/call_panel.dart';
import '../widgets/radar_map.dart';
import '../widgets/home_cards.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({
    super.key,
    required this.isWide,
    required this.wasteTypes,
    required this.selectedWaste,
    required this.weight,
    required this.estimate,
    required this.paperBankProgress,
    required this.onSearch,
    required this.onMobileSearchOpen,
    required this.onNotificationsTap,
    required this.onPointsTap,
    required this.onWasteChanged,
    required this.onWeightChanged,
    required this.onCreateOrder,
    required this.onQuickAction,
    required this.onImpactDetail,
    required this.onMarketItemTap,
    required this.onPaperBankTap,
    required this.onAiScanTap,
    required this.onSortingGuideTap,
    required this.onStationTap,
    required this.onEcoReportTap,
    required this.onCollectorInvite,
    required this.onSchedulePickupTap,
  });

  final bool isWide;
  final List<WasteType> wasteTypes;
  final int selectedWaste;
  final double weight;
  final int estimate;
  final double paperBankProgress;

  final ValueChanged<String> onSearch;
  final VoidCallback onMobileSearchOpen;
  final VoidCallback onNotificationsTap;
  final VoidCallback onPointsTap;
  final ValueChanged<int> onWasteChanged;
  final ValueChanged<double> onWeightChanged;
  final VoidCallback onCreateOrder;
  final ValueChanged<int> onQuickAction;
  final ValueChanged<int> onImpactDetail;
  final ValueChanged<int> onMarketItemTap;
  final VoidCallback onPaperBankTap;
  final VoidCallback onAiScanTap;
  final ValueChanged<int> onSortingGuideTap;
  final ValueChanged<int> onStationTap;
  final VoidCallback onEcoReportTap;
  final ValueChanged<int> onCollectorInvite;
  final VoidCallback onSchedulePickupTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HomeTopBar(
          isWide: isWide,
          onSearch: onSearch,
          onMobileSearchOpen: onMobileSearchOpen,
          onNotificationsTap: onNotificationsTap,
          onPointsTap: onPointsTap,
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: isWide ? 28 : 16),
            children: [
              const ActiveOrderBanner(),
              const SizedBox(height: 16),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          CallPanel(
                            wasteTypes: wasteTypes,
                            selectedWaste: selectedWaste,
                            weight: weight,
                            estimate: estimate,
                            onWasteChanged: onWasteChanged,
                            onWeightChanged: onWeightChanged,
                            onCreateOrder: onCreateOrder,
                          ),
                          const SizedBox(height: 16),
                          QuickActionsBar(onAction: onQuickAction),
                          const SizedBox(height: 16),
                          ImpactStrip(onTap: onImpactDetail),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          const RadarMap(height: 400),
                          const SizedBox(height: 16),
                          MarketCard(wasteTypes: wasteTypes, onItemTap: onMarketItemTap),
                          const SizedBox(height: 16),
                          PaperBankCard(progress: paperBankProgress, onTap: onPaperBankTap),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                CallPanel(
                  wasteTypes: wasteTypes,
                  selectedWaste: selectedWaste,
                  weight: weight,
                  estimate: estimate,
                  onWasteChanged: onWasteChanged,
                  onWeightChanged: onWeightChanged,
                  onCreateOrder: onCreateOrder,
                ),
                const SizedBox(height: 16),
                QuickActionsBar(onAction: onQuickAction),
                const SizedBox(height: 16),
                ImpactStrip(onTap: onImpactDetail),
                const SizedBox(height: 16),
                const RadarMap(height: 280),
                const SizedBox(height: 16),
                MarketCard(wasteTypes: wasteTypes, onItemTap: onMarketItemTap),
                const SizedBox(height: 16),
                PaperBankCard(progress: paperBankProgress, onTap: onPaperBankTap),
              ],
              const SizedBox(height: 16),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: AiScanCard(onTap: onAiScanTap)),
                    const SizedBox(width: 16),
                    Expanded(child: SortingGuideCard(onRowTap: onSortingGuideTap)),
                  ],
                )
              else ...[
                AiScanCard(onTap: onAiScanTap),
                const SizedBox(height: 16),
                SortingGuideCard(onRowTap: onSortingGuideTap),
              ],
              const SizedBox(height: 16),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: StationFinderCard(onTap: onStationTap)),
                    const SizedBox(width: 16),
                    Expanded(child: EcoReportCard(onCardTap: onEcoReportTap)),
                  ],
                )
              else ...[
                StationFinderCard(onTap: onStationTap),
                const SizedBox(height: 16),
                EcoReportCard(onCardTap: onEcoReportTap),
              ],
              const SizedBox(height: 16),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: CollectorMatchCard(onRowTap: onCollectorInvite)),
                    const SizedBox(width: 16),
                    Expanded(child: SchedulePickupCard(onOpenDetail: onSchedulePickupTap)),
                  ],
                )
              else ...[
                CollectorMatchCard(onRowTap: onCollectorInvite),
                const SizedBox(height: 16),
                SchedulePickupCard(onOpenDetail: onSchedulePickupTap),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}
