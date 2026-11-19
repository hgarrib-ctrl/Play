import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppStyles {
  // Border Radii
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 14.0;
  static const double radiusLarge = 20.0;
  static const double radiusXLarge = 28.0;

  static final BorderRadius borderRadiusSmall = BorderRadius.circular(radiusSmall);
  static final BorderRadius borderRadiusMedium = BorderRadius.circular(radiusMedium);
  static final BorderRadius borderRadiusLarge = BorderRadius.circular(radiusLarge);
  static final BorderRadius borderRadiusXLarge = BorderRadius.circular(radiusXLarge);

  // Blur strengths
  static const double glassBlur = 12.0;
  static const double heavyGlassBlur = 24.0;
  static ImageFilter get glassImageFilter => ImageFilter.blur(sigmaX: glassBlur, sigmaY: glassBlur);
  static ImageFilter get heavyGlassImageFilter => ImageFilter.blur(sigmaX: heavyGlassBlur, sigmaY: heavyGlassBlur);

  // Shadows
  static List<BoxShadow> get subtleShadowDark => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get glowShadowBlue => [
    BoxShadow(
      color: AppColors.electricBlue.withValues(alpha: 0.3),
      blurRadius: 18,
      spreadRadius: 1,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get glowShadowGreen => [
    BoxShadow(
      color: AppColors.emeraldGreen.withValues(alpha: 0.3),
      blurRadius: 18,
      spreadRadius: 1,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get subtleShadowLight => [
    BoxShadow(
      color: const Color(0xFF64748B).withValues(alpha: 0.12),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];

  // Text Styles (Clean, High Readability)
  static const TextStyle heading1 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle priceLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const TextStyle priceMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle priceSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
}
