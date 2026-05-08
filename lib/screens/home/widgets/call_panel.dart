import 'package:flutter/material.dart';
import '../../../models/waste_type.dart';
import '../../../theme/eco_colors.dart';
import '../../../utils/formatters.dart';
import 'common_home_widgets.dart';

class CallPanel extends StatelessWidget {
  const CallPanel({
    super.key,
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
    return EcoPanel(
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
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCreateOrder,
              icon: const Icon(Icons.radar_rounded),
              label: const Text('PHÁT TÍN HIỆU THU GOM'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
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
