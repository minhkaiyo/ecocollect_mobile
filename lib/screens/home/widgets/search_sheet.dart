import 'package:flutter/material.dart';
import '../../../theme/eco_colors.dart';

class SearchSheet extends StatelessWidget {
  const SearchSheet({super.key, required this.onItemTap});

  final void Function(String title, IconData icon) onItemTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: EcoColors.sheetHandle, borderRadius: BorderRadius.circular(999)))),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Tìm vật liệu, voucher, trạm...',
                    prefixIcon: const Icon(Icons.search_rounded, color: EcoColors.bodyMuted),
                    filled: true,
                    fillColor: EcoColors.inputFill,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Tìm kiếm gần đây', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SearchTag(label: 'Giấy báo'),
              _SearchTag(label: 'Voucher Highland'),
              _SearchTag(label: 'Nhựa PET'),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Gợi ý cho bạn', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _SuggestionItem(icon: Icons.recycling_rounded, title: 'Cách phân loại nhựa PET', color: EcoColors.primary, onTap: () => onItemTap('Cách phân loại nhựa PET', Icons.recycling_rounded)),
                _SuggestionItem(icon: Icons.local_offer_rounded, title: 'Ưu đãi đổi điểm lấy cây', color: EcoColors.orange, onTap: () => onItemTap('Đổi cây cảnh', Icons.park_rounded)),
                _SuggestionItem(icon: Icons.volunteer_activism_rounded, title: 'Chiến dịch Gom yêu thương', color: EcoColors.coral, onTap: () => onItemTap('Gom yêu thương', Icons.volunteer_activism_rounded)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchTag extends StatelessWidget {
  const _SearchTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: EcoColors.surfaceMuted, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: EcoColors.bodyMuted)),
    );
  }
}

class _SuggestionItem extends StatelessWidget {
  const _SuggestionItem({required this.icon, required this.title, required this.color, required this.onTap});
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.north_west_rounded, size: 18, color: EcoColors.iconMuted),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }
}
