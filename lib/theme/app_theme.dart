import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  /// Adapts the theme to Telegram `themeParams` (§7.2): bg_color→surface-bg,
  /// text_color→neutral-dark, button_color→primary-base, accent_text_color→
  /// secondary-base, section_bg_color→surface-card, subtitle_text_color→neutral-mid.
  static ThemeData fromTelegram(Map<String, dynamic> params) {
    Color? parse(String key) {
      final v = params[key];
      if (v is! String || v.isEmpty) return null;
      final hex = v.replaceFirst('#', '');
      final n = int.tryParse(hex, radix: 16);
      if (n == null) return null;
      return Color(0xFF000000 | n);
    }

    final bg = parse('bg_color');
    final text = parse('text_color');
    final button = parse('button_color');
    final accent = parse('accent_text_color');
    final section = parse('section_bg_color');
    final subtitle = parse('subtitle_text_color');

    final isDark = bg != null && bg.computeLuminance() < 0.5;
    final base = _base(isDark ? Brightness.dark : Brightness.light);

    return base.copyWith(
      scaffoldBackgroundColor: bg ?? base.scaffoldBackgroundColor,
      colorScheme: base.colorScheme.copyWith(
        primary: button ?? base.colorScheme.primary,
        secondary: accent ?? base.colorScheme.secondary,
        surface: section ?? base.colorScheme.surface,
        onSurface: text ?? base.colorScheme.onSurface,
        onSurfaceVariant: subtitle ?? base.colorScheme.onSurfaceVariant,
      ),
    );
  }

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final canvas = isDark ? const Color(0xFF16100B) : AppColors.surfaceBg;
    final card = isDark ? const Color(0xFF211912) : AppColors.surfaceCard;
    const primary = AppColors.primaryGold;
    final border = isDark ? const Color(0xFF3A3129) : AppColors.cardBorder;
    final textColor = isDark ? AppColors.surfaceCard : AppColors.neutralDark;
    const onPrimary = AppColors.neutralDark; // dark text on gold CTA (high contrast)

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: AppColors.secondaryClay,
      surface: card,
      error: AppColors.dangerRed,
    ).copyWith(
      surface: card,
      onSurface: textColor,
      onSurfaceVariant: AppColors.neutralMid,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: canvas,
      textTheme: AppTypography.dualScript(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: textColor,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          fontFamilyFallback: const ['NotoSansEthiopic'],
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textColor,
          height: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.08),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.tsomGreen,
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? card : Colors.white,
        side: BorderSide(color: border),
        labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
        labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? card : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.neutralMid, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
      checkboxTheme: const CheckboxThemeData(side: BorderSide(color: AppColors.neutralMid)),
    );
  }
}