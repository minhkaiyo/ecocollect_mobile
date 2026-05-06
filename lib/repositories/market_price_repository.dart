import 'package:flutter/material.dart';
import '../models/waste_type.dart';
import '../theme/eco_colors.dart';
import 'base_repository.dart';

class MarketPriceRepository extends BaseRepository {
  Stream<List<WasteType>> watchPrices() {
    return db.collection('market_prices').snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        // Fallback data if collection is empty
        return const [
          WasteType('Giấy hỗn hợp', '3.000 – 4.500', 4500, Icons.description_rounded, EcoColors.blue, 'Ép phẳng, buộc gọn, tránh ẩm mốc.'),
          WasteType('Nhựa PET', '4.000 – 6.000', 6000, Icons.local_drink_rounded, EcoColors.coral, 'Xả sạch nước, tháo nắp nếu khác loại nhựa.'),
          WasteType('Kim loại', '12.000 – 35.000', 35000, Icons.build_rounded, EcoColors.orange, 'Tách riêng sắt, nhôm, đồng để tối ưu giá.'),
        ];
      }

      return snap.docs.map((doc) {
        final data = doc.data();
        
        // Parse icon
        IconData iconData = Icons.recycling_rounded;
        final iconName = data['icon'] as String?;
        if (iconName == 'description_rounded' || iconName == 'description') iconData = Icons.description_rounded;
        if (iconName == 'local_drink_rounded' || iconName == 'local_drink') iconData = Icons.local_drink_rounded;
        if (iconName == 'build_rounded' || iconName == 'build') iconData = Icons.build_rounded;
        if (iconName == 'computer_rounded' || iconName == 'computer') iconData = Icons.computer_rounded;

        // Parse color
        Color color = EcoColors.primary;
        final colorHex = data['colorHex'] as String?;
        if (colorHex != null && colorHex.length == 7) {
          color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
        }

        return WasteType(
          data['name'] ?? 'Không tên',
          data['range'] ?? '0 - 0',
          data['pricePerKg'] ?? 0,
          iconData,
          color,
          data['guide'] ?? '',
        );
      }).toList();
    });
  }
}
