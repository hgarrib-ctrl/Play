import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme Palette (Default & Primary Focus)
  static const Color darkBackground = Color(0xFF080D19);
  static const Color darkSecondaryBackground = Color(0xFF101A2C);
  static const Color darkSurface = Color(0xFF131E33);
  
  // Light Theme Palette
  static const Color lightBackground = Color(0xFFF3F6FA);
  static const Color lightSecondaryBackground = Color(0xFFE5ECF6);
  static const Color lightSurface = Color(0xFFFFFFFF);

  // Accents
  static const Color electricBlue = Color(0xFF638BFF);
  static const Color softCyan = Color(0xFF53D9E8);
  static const Color emeraldGreen = Color(0xFF31D69A);
  static const Color coralRed = Color(0xFFFF5C75);
  static const Color amberOrange = Color(0xFFFFB347);
  static const Color purpleAccent = Color(0xFF9D65FF);

  // Typography - Dark Mode
  static const Color textPrimaryDark = Color(0xFFF5F7FF);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Typography - Light Mode
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Glass Elements - Dark Mode
  static const Color glassFillDark = Color(0x14FFFFFF); // ~8% white
  static const Color glassFillActiveDark = Color(0x22FFFFFF); // ~13% white
  static const Color glassBorderDark = Color(0x28FFFFFF); // ~16% white border
  static const Color glassBorderGlowDark = Color(0x55638BFF); // Blue glow border

  // Glass Elements - Light Mode
  static const Color glassFillLight = Color(0xBAFFFFFF); // ~73% white
  static const Color glassFillActiveLight = Color(0xDFFFFFFF); // ~87% white
  static const Color glassBorderLight = Color(0x40CBD5E1); // slate border
  static const Color glassBorderGlowLight = Color(0x40638BFF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF638BFF), Color(0xFF53D9E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Diwali Festive Gold Theme Palette (Special Festival Rush Theme)
  static const Color diwaliBackground = Color(0xFF140A02);
  static const Color diwaliSecondaryBackground = Color(0xFF221204);
  static const Color diwaliSurface = Color(0xFF2E1906);
  static const Color diwaliGoldAccent = Color(0xFFFFB300);
  static const Color diwaliAmberGlow = Color(0xFFFF7A00);
  static const Color diwaliHighlight = Color(0xFFFFD54F);
  static const Color diwaliBorder = Color(0x40FFB300);
  static const Color diwaliTextPrimary = Color(0xFFFFFBEA);
  static const Color diwaliTextSecondary = Color(0xFFDEC599);

  static const LinearGradient diwaliGradient = LinearGradient(
    colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGreenGradient = LinearGradient(
    colors: [Color(0xFF31D69A), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradientDark = LinearGradient(
    colors: [
      Color(0x26FFFFFF),
      Color(0x0DFFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassBorderGradientDark = LinearGradient(
    colors: [
      Color(0x4DFFFFFF),
      Color(0x14FFFFFF),
      Color(0x33638BFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient exchangeGradient = LinearGradient(
    colors: [Color(0xFFFFB347), Color(0xFFFF5C75)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
