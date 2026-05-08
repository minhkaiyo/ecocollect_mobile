import 'package:flutter/material.dart';

class WasteType {
  const WasteType(
    this.name,
    this.range,
    this.price,
    this.icon,
    this.color,
    this.guide,
  );

  final String name;
  final String range;
  final int price;
  final IconData icon;
  final Color color;
  final String guide;
}
