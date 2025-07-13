import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xff006700);
  static const Color primaryGradient = Color(0xff009800);

  /// [Primary background color]
  // Transparent Colors
  static Color get primaryBgColor => Colors.black.withAlpha((0.2 * 255).toInt());
}
