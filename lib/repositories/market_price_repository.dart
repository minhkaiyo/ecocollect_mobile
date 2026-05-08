import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/waste_type.dart';
import '../models/price_point.dart';
import '../theme/eco_colors.dart';
import 'base_repository.dart';

class MarketPriceRepository extends BaseRepository {
  Stream<List<WasteType>> watchPrices() {
    return db.collection('market_prices').snapshots().asyncMap((snap) async {
      if (snap.docs.isEmpty) {
        return const [
          WasteType('Giấy hỗn hợp', '3.000 – 4.500', 4500, Icons.description_rounded, EcoColors.blue, 'Ép phẳng, buộc gọn, tránh ẩm mốc.'),
          WasteType('Nhựa PET', '4.000 – 6.000', 6000, Icons.local_drink_rounded, EcoColors.coral, 'Xả sạch nước, tháo nắp nếu khác loại nhựa.'),
          WasteType('Kim loại', '12.000 – 35.000', 35000, Icons.build_rounded, EcoColors.orange, 'Tách riêng sắt, nhôm, đồng để tối ưu giá.'),
        ];
      }

      List<WasteType> list = [];
      for (var doc in snap.docs) {
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

        // Lấy lịch sử giá (giới hạn 10 điểm gần nhất cho danh sách tổng)
        final historySnap = await doc.reference.collection('price_history')
            .orderBy('time', descending: true)
            .limit(10)
            .get();
        
        final history = historySnap.docs.map(PricePoint.fromFirestore).toList().reversed.toList();

        list.add(WasteType(
          data['name'] ?? 'Không tên',
          data['range'] ?? '0 - 0',
          data['pricePerKg'] ?? 0,
          iconData,
          color,
          data['guide'] ?? '',
          priceHistory: history,
        ));
      }
      return list;
    });
  }

  /// Theo dõi lịch sử giá chi tiết của 1 loại vật liệu
  Stream<List<PricePoint>> watchHistory(String materialName) {
    return db
        .collection('market_prices')
        .doc(materialName)
        .collection('price_history')
        .orderBy('time', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs.map(PricePoint.fromFirestore).toList().reversed.toList());
  }

  /// Cập nhật giá mới (dành cho Collector/Station)
  Future<void> updatePrice(String materialName, double newPrice) async {
    final batch = db.batch();
    final docRef = db.collection('market_prices').doc(materialName);
    
    // 1. Cập nhật giá hiện tại
    batch.update(docRef, {
      'pricePerKg': newPrice.toInt(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // 2. Thêm vào lịch sử
    final historyRef = docRef.collection('price_history').doc();
    batch.set(historyRef, {
      'time': FieldValue.serverTimestamp(),
      'price': newPrice,
    });

    await batch.commit();
  }
}
