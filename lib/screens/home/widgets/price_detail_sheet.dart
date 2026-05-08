import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../models/waste_type.dart';
import '../../../models/user_profile.dart';
import '../../../models/price_point.dart';
import '../../../repositories/market_price_repository.dart';
import '../../../repositories/user_repository.dart';
import '../../../theme/eco_colors.dart';
import '../../../ui/app_feedback.dart';
import 'material_trend_chart.dart';

class PriceDetailSheet extends StatefulWidget {
  const PriceDetailSheet({super.key, required this.wasteType});
  final WasteType wasteType;

  @override
  State<PriceDetailSheet> createState() => _PriceDetailSheetState();
}

class _PriceDetailSheetState extends State<PriceDetailSheet> {
  final _priceController = TextEditingController();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _priceController.text = widget.wasteType.price.toString();
  }

  Future<void> _updatePrice() async {
    final newPrice = double.tryParse(_priceController.text);
    if (newPrice == null || newPrice <= 0) {
      showEcoSnackBar(context, 'Giá không hợp lệ', icon: Icons.error_outline);
      return;
    }

    setState(() => _isUpdating = true);
    try {
      await MarketPriceRepository().updatePrice(widget.wasteType.name, newPrice);
      if (mounted) {
        showEcoSnackBar(context, 'Đã cập nhật giá mới cho ${widget.wasteType.name}', icon: Icons.trending_up);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showEcoSnackBar(context, 'Lỗi cập nhật: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
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
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.wasteType.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.wasteType.icon, color: widget.wasteType.color, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.wasteType.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              'Khoảng giá: ${widget.wasteType.range} VND/kg',
                              style: const TextStyle(color: EcoColors.bodyMuted, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Biến động 7 ngày qua', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 16),
                  Container(
                    height: 180,
                    padding: const EdgeInsets.only(right: 16, top: 16),
                    child: StreamBuilder<List<PricePoint>>(
                      stream: MarketPriceRepository().watchHistory(widget.wasteType.name),
                      initialData: widget.wasteType.priceHistory,
                      builder: (context, snapshot) {
                        return MaterialTrendChart(
                          history: snapshot.data ?? [],
                          color: widget.wasteType.color,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Hướng dẫn phân loại', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: EcoColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      widget.wasteType.guide,
                      style: const TextStyle(height: 1.5, color: EcoColors.textBody),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (uid != null)
                    StreamBuilder<UserProfile>(
                      stream: UserRepository().watchProfile(uid),
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        if (user?.isCollector ?? false) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Divider(),
                              const SizedBox(height: 16),
                              const Text('Cập nhật giá hôm nay (Dành cho Collector)', style: TextStyle(fontWeight: FontWeight.w800, color: EcoColors.primary)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _priceController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        suffixText: 'VND/kg',
                                        filled: true,
                                        fillColor: EcoColors.inputFill,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  FilledButton(
                                    onPressed: _isUpdating ? null : _updatePrice,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: EcoColors.primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    child: _isUpdating 
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Text('CẬP NHẬT', style: TextStyle(fontWeight: FontWeight.w900)),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
