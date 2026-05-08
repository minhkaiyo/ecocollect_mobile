import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../theme/eco_colors.dart';

class MarketFluctuationCard extends StatefulWidget {
  const MarketFluctuationCard({super.key});

  @override
  State<MarketFluctuationCard> createState() => _MarketFluctuationCardState();
}

class _MarketFluctuationCardState extends State<MarketFluctuationCard> {
  String _selectedMaterial = 'Giấy';

  final Map<String, List<FlSpot>> _baseData = {
    'Giấy': [const FlSpot(0, 2), const FlSpot(1, 1.8), const FlSpot(2, 2.5), const FlSpot(3, 2.2)],
    'Nhựa': [const FlSpot(0, 3), const FlSpot(1, 3.5), const FlSpot(2, 3.2), const FlSpot(3, 3.8)],
    'Kim loại': [const FlSpot(0, 4), const FlSpot(1, 4.2), const FlSpot(2, 4.5), const FlSpot(3, 4.3)],
    'Điện tử': [const FlSpot(0, 5), const FlSpot(1, 5.5), const FlSpot(2, 5.2), const FlSpot(3, 5.8)],
  };

  final Map<String, Color> _materialColors = {
    'Giấy': EcoColors.blue,
    'Nhựa': EcoColors.primary,
    'Kim loại': EcoColors.orange,
    'Điện tử': EcoColors.purple,
  };

  @override
  Widget build(BuildContext context) {
    final currentColor = _materialColors[_selectedMaterial]!;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('wasteType', isEqualTo: _selectedMaterial)
            .limit(3)
            .snapshots(),
        builder: (context, snapshot) {
          List<FlSpot> spots = List.from(_baseData[_selectedMaterial]!);
          
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            final docs = snapshot.data!.docs;
            for (int i = 0; i < docs.length; i++) {
              final data = docs[i].data() as Map<String, dynamic>;
              final weight = (data['weight'] ?? 1.0) as double;
              final estimate = (data['estimate'] ?? 0) as int;
              if (weight > 0) {
                // Normalize price to 0-6 range for chart
                double price = estimate / weight / 2000; 
                if (price > 6) price = 6;
                spots.add(FlSpot(spots.length.toDouble(), price));
              }
            }
          }

          // Keep max 7 points
          if (spots.length > 7) {
            spots = spots.sublist(spots.length - 7);
            // Re-index X axis
            for (int i = 0; i < spots.length; i++) {
              spots[i] = FlSpot(i.toDouble(), spots[i].y);
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Phân tích thị trường', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  Text('Real-time • Live', style: TextStyle(color: EcoColors.success, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _baseData.keys.map((m) => _MaterialChip(
                    label: m,
                    selected: _selectedMaterial == m,
                    color: _materialColors[m]!,
                    onTap: () => setState(() => _selectedMaterial = m),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _StatItem(label: 'Giá hiện tại', value: '${(spots.last.y * 2000).toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ', color: currentColor),
                  const Spacer(),
                  _StatItem(label: 'Cao nhất', value: '${(spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 2000).toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ', color: EcoColors.bodyMuted),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 160,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            const style = TextStyle(color: EcoColors.bodyMuted, fontWeight: FontWeight.w700, fontSize: 10);
                            return Text('T${value.toInt() + 1}', style: style);
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: currentColor,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                            radius: index == spots.length - 1 ? 5 : 0,
                            color: currentColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [currentColor.withOpacity(0.2), currentColor.withOpacity(0)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                  duration: const Duration(milliseconds: 400),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MaterialChip extends StatelessWidget {
  const _MaterialChip({required this.label, required this.selected, required this.color, required this.onTap});
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? Colors.white : color, fontSize: 12, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: EcoColors.bodyMuted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }
}
