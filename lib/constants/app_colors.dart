import 'package:flutter/material.dart';

/// SSVM Institutions brand palette — blue, white, light orange, light green.
class AppColors {
  AppColors._();

  /// Logo blue sampled from [assets/images/ssvm_logo.jpg].
  static const Color navy = Color(0xFF254598);
  static const Color lightOrange = Color(0xFFFFB74D);
  static const Color lightGreen = Color(0xFF81C784);
  static const Color softBlue = Color(0xFF90CAF9);
  static const Color white = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F7FB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A2F66);
  static const Color textSecondary = Color(0xFF5C6B8A);
  static const Color present = Colors.green;
  static const Color absent = Color(0xFFE57373);
  static const Color holiday = softBlue;

  static const Color primary = navy;
  static const Color primaryDark = Color(0xFF1A3370);
  static const Color accent = Colors.orangeAccent;
  static const Color background = surface;
  static const Color success = Colors.green;
  static const Color danger = absent;
  static const Color warning = Colors.orangeAccent;
  static const Color info = softBlue;
  static const Color divider = Color(0xFFDCE3F0);

  /// Legacy aliases used across the app.
  static const Color yellow = Colors.yellowAccent;
  static const Color lightBlue = softBlue;
  static const Color orange = Colors.orangeAccent;
}
