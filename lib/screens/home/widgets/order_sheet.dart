import 'package:flutter/material.dart';
import '../../../models/waste_type.dart';
import '../../../theme/eco_colors.dart';
import '../../../utils/formatters.dart';

class OrderSheet extends StatefulWidget {
  const OrderSheet({
    super.key,
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
  State<OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends State<OrderSheet> {
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mở camera chụp đống rác (demo). Ảnh sẽ đính kèm đơn khi tích hợp thiết bị.'),
                      ),
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
                onChanged: (value) => setState(() => _receiveGreenPoints = value),
                title: const Text('Nhận bằng Điểm Xanh'),
                subtitle: const Text('Tự động cộng vào Eco-Wallet sau đối soát'),
                secondary: const Icon(Icons.token_rounded, color: EcoColors.blue),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onSubmitted();
                },
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
