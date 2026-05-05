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

/// Định dạng số tiền VND kiểu 1.234.567 (không có đơn vị).
String formatVnd(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final fromEnd = text.length - i;
    buffer.write(text[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) {
      buffer.write('.');
    }
  }
  return buffer.toString();
}
