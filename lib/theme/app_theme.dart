import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'eco_colors.dart';

ThemeData buildEcoTheme() {
  final base = GoogleFonts.beVietnamProTextTheme();
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: EcoColors.primary,
      primary: EcoColors.primary,
      secondary: EcoColors.blue,
      surface: Colors.white,
    ),
    textTheme: base,
  );
}
