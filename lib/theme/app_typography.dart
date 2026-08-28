import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Dual-script type scale per §7.3.
/// Critical rules:
///  - Amharic body line-height >= 1.65 (we apply tall `height` values globally so
///    Ethiopic diacritics never clip).
///  - Any control that can hold Amharic adds >= 12px vertical inner padding
///    (handled in theme + widget margins).
class AppTypography {
  AppTypography._();

  static const String _latin = 'Inter';
  static const List<String> _ethiopicStack = [
    'NotoSansEthiopic',
    'Noto Sans Ethiopic',
    'sans-serif',
  ];

  static TextTheme dualScript() {
    TextStyle fs({
      required double size,
      required FontWeight weight,
      double height = 1.6,
      double spacing = 0,
      Color color = AppColors.neutralDark,
    }) => TextStyle(
      fontFamily: _latin,
      fontFamilyFallback: _ethiopicStack,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: spacing,
      color: color,
    );

    return const TextTheme().copyWith(
      displayLarge: fs(size: 28, weight: FontWeight.w700, height: 1.4, spacing: -0.02),
      displayMedium: fs(size: 24, weight: FontWeight.w700, height: 1.4, spacing: -0.02),
      displaySmall: fs(size: 22, weight: FontWeight.w700, height: 1.4),
      headlineLarge: fs(size: 22, weight: FontWeight.w600, height: 1.4),
      headlineMedium: fs(size: 20, weight: FontWeight.w600, height: 1.5),
      headlineSmall: fs(size: 18, weight: FontWeight.w600, height: 1.5),
      titleLarge: fs(size: 18, weight: FontWeight.w600, height: 1.5),
      titleMedium: fs(size: 16, weight: FontWeight.w600, height: 1.6),
      titleSmall: fs(size: 14, weight: FontWeight.w600, height: 1.6),
      bodyLarge: fs(size: 14, weight: FontWeight.w400, height: 1.65),
      bodyMedium: fs(size: 13, weight: FontWeight.w400, height: 1.65),
      bodySmall: fs(size: 12, weight: FontWeight.w400, height: 1.65, color: AppColors.neutralMid),
      labelLarge: fs(size: 14, weight: FontWeight.w600, height: 1.5),
      labelMedium: fs(size: 12, weight: FontWeight.w500, height: 1.7, color: AppColors.neutralMid),
      labelSmall: fs(size: 10, weight: FontWeight.w400, height: 1.8, color: AppColors.neutralMid),
    );
  }
}