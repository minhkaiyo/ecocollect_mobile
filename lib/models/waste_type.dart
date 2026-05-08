import 'package:flutter/material.dart';
import 'price_point.dart';

class WasteType {
  const WasteType(
    this.name,
    this.range,
    this.price,
    this.icon,
    this.color,
    this.guide, {
    this.priceHistory = const [],
  });

  final String name;
  final String range;
  final int price;
  final IconData icon;
  final Color color;
  final String guide;
  final List<PricePoint> priceHistory;
}
