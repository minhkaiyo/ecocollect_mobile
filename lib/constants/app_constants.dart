import 'package:flutter/material.dart';

class AppConstants {
  // App
  static const String appName = 'EcoCollect';
  
  // UI Spacing
  static const double spacingXs = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXl = 20.0;
  static const double spacingXxl = 24.0;
  static const double spacing3xl = 32.0;

  // UI Padding
  static const EdgeInsets paddingS = EdgeInsets.all(8.0);
  static const EdgeInsets paddingM = EdgeInsets.all(12.0);
  static const EdgeInsets paddingL = EdgeInsets.all(16.0);
  static const EdgeInsets paddingXl = EdgeInsets.all(20.0);
  static const EdgeInsets paddingXxl = EdgeInsets.all(24.0);

  // UI Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXl = 20.0;
  static const double radius2xl = 24.0;
  static const double radius3xl = 28.0;

  // Icon Sizes
  static const double iconSizeS = 18.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;

  // Font Sizes
  static const double fontSizeS = 12.0;
  static const double fontSizeM = 14.0;
  static const double fontSizeL = 16.0;
  static const double fontSizeXl = 18.0;
  static const double fontSize2xl = 20.0;
  static const double fontSize3xl = 24.0;

  // Logic
  static const int maxPickupLocationsDefault = 3;
  static const int maxSavedPartnersPerQuery = 10;

  // Subscription Tiers
  static const Map<String, Map<String, dynamic>> subTiers = {
    'free': {'label': 'Cơ bản', 'limit': 3, 'price': 0},
    'pro': {'label': 'Pro', 'limit': 10, 'price': 100000},
    'plus': {'label': 'Plus', 'limit': 20, 'price': 400000},
    'ultra': {'label': 'Ultra', 'limit': 50, 'price': 1000000},
  };
}
