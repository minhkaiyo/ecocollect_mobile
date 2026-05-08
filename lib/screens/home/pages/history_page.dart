import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/order.dart';
import '../../../models/waste_type.dart';
import '../../../repositories/order_repository.dart';
import '../../../theme/eco_colors.dart';
import '../../../ui/loading_widgets.dart';
import '../widgets/common_home_widgets.dart';
import '../../../ui/loading_widgets.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({
    super.key,
    required this.wasteTypes,
    required this.onOrderTap,
  });

  final List<WasteType> wasteTypes;
  final Function(EcoOrder, WasteType) onOrderTap;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Vui lòng đăng nhập'));

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'Lịch sử xanh',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        EcoStreamBuilder<List<EcoOrder>>(
          stream: OrderRepository().watchUserOrders(uid),
          loadingWidget: const Center(child: CircularProgressIndicator()),
          builder: (context, orders) {
            if (orders.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'Chưa có đơn thu gom nào.',
                    style: TextStyle(color: EcoColors.bodyMuted),
                  ),
                ),
              );
            }
            return Column(
              children: orders.map((order) {
                final type = wasteTypes.firstWhere(
                  (t) => t.name == order.wasteType,
                  orElse: () => wasteTypes[0],
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: EcoTappablePanel(
                    onTap: () => onOrderTap(order, type),
                    child: Row(
                      children: [
                        EcoIconTile(icon: type.icon, color: type.color),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.wasteType,
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                              Text(
                                '${order.weight} kg - ${order.status}',
                                style: const TextStyle(color: EcoColors.bodyMuted),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '+${order.earnedPoints}đ',
                          style: TextStyle(
                            color: type.color,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: EcoColors.iconMuted,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
