import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppStyles {
  AppStyles._();

  static String? get _font => GoogleFonts.rubik().fontFamily;

  static TextStyle heading = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    fontFamily: _font,
  );

  static TextStyle subHeading = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: _font,
  );

  static TextStyle cardTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: _font,
  );

  static TextStyle cardTitleBold = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    fontFamily: _font,
  );

  static TextStyle cardValue = TextStyle(
    color: AppColors.primary,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    fontFamily: _font,
  );

  static TextStyle caption = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontFamily: _font,
  );

  static InputDecoration searchDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: subHeading,
      filled: true,
      fillColor: AppColors.white,
      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
