import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../models/price_point.dart';
import '../../../theme/eco_colors.dart';

class MaterialTrendChart extends StatelessWidget {
  final List<PricePoint> history;
  final Color color;

  const MaterialTrendChart({
    super.key,
    required this.history,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Text('Chưa có dữ liệu biến động', style: TextStyle(color: EcoColors.bodyMuted)),
      );
    }

    // Lấy giá trị min/max để scale biểu đồ
    double minPrice = history.map((e) => e.price).reduce((a, b) => a < b ? a : b);
    double maxPrice = history.map((e) => e.price).reduce((a, b) => a > b ? a : b);
    double padding = (maxPrice - minPrice) * 0.2;
    if (padding == 0) padding = 1000;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (history.length - 1).toDouble(),
        minY: minPrice - padding,
        maxY: maxPrice + padding,
        lineBarsData: [
          LineChartBarData(
            spots: history.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.price);
            }).toList(),
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.3),
                  color.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => color,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final price = spot.y;
                return LineTooltipItem(
                  '${price.toStringAsFixed(0)}đ',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
