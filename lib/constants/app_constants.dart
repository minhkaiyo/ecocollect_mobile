import 'package:flutter/material.dart';

/// App-wide constants for spacing, sizing, and configuration
abstract final class AppConstants {
  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXl = 18.0;
  static const double spacingXxl = 24.0;
  static const double spacing3xl = 32.0;
  static const double spacing4xl = 48.0;

  // Border Radius
  static const double radiusS = 12.0;
  static const double radiusM = 14.0;
  static const double radiusL = 16.0;
  static const double radiusXl = 18.0;
  static const double radiusXxl = 20.0;
  static const double radius3xl = 22.0;
  static const double radius4xl = 24.0;
  static const double radius5xl = 28.0;

  // Padding
  static const EdgeInsets paddingS = EdgeInsets.all(8.0);
  static const EdgeInsets paddingM = EdgeInsets.all(12.0);
  static const EdgeInsets paddingL = EdgeInsets.all(16.0);
  static const EdgeInsets paddingXl = EdgeInsets.all(18.0);
  static const EdgeInsets paddingXxl = EdgeInsets.all(22.0);
  static const EdgeInsets padding3xl = EdgeInsets.all(24.0);

  static const EdgeInsets paddingHorizontalL = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets paddingHorizontalXl = EdgeInsets.symmetric(horizontal: 22.0);
  static const EdgeInsets paddingHorizontalXxl = EdgeInsets.symmetric(horizontal: 28.0);

  static const EdgeInsets paddingVerticalM = EdgeInsets.symmetric(vertical: 12.0);
  static const EdgeInsets paddingVerticalL = EdgeInsets.symmetric(vertical: 16.0);

  // Breakpoints
  static const double breakpointWide = 1200.0;
  static const double breakpointTablet = 768.0;
  static const double breakpointMobile = 430.0;

  // Map
  static const double defaultMapZoom = 14.5;
  static const double collectorRadiusKm = 5.0;
  static const int locationUpdateDistanceMeters = 5;

  // Weight slider
  static const double minWeight = 1.0;
  static const double maxWeight = 50.0;
  static const int weightDivisions = 49;

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationVerySlow = Duration(milliseconds: 800);

  // Snackbar
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const double snackbarBottomMargin = 16.0;
  static const double snackbarBottomMarginWithNav = 72.0;

  // Icon sizes
  static const double iconSizeS = 18.0;
  static const double iconSizeM = 22.0;
  static const double iconSizeL = 24.0;
  static const double iconSizeXl = 28.0;

  // Font sizes
  static const double fontSizeS = 14.0;
  static const double fontSizeM = 15.0;
  static const double fontSizeL = 16.0;
  static const double fontSizeXl = 18.0;
  static const double fontSizeXxl = 20.0;
  static const double fontSize3xl = 22.0;
  static const double fontSize4xl = 24.0;
  static const double fontSize5xl = 30.0;

  // Default locations
  static const double defaultLatitude = 21.0285; // Hanoi
  static const double defaultLongitude = 105.8542;

  // Limits
  static const int maxPickupLocationsDefault = 2;
  static const int maxSavedPartnersPerQuery = 10;
}
