import 'package:flutter/material.dart';

/// Design-system color tokens per the product spec (§7.1).
/// Do NOT use raw Ethiopian flag colors or generic tech blue as the primary scheme.
class AppColors {
  AppColors._();

  static const Color primaryGold = Color(0xFFE69A09); // Teff Honey Gold — primary CTA
  static const Color primaryHover = Color(0xFFC78200); // pressed primary CTA
  static const Color secondaryClay = Color(0xFFC84B20); // Berbere Clay — culinary tags, promos
  static const Color surfaceGround = Color(0xFFFA9812); // warnings / pending transaction
  static const Color tsomGreen = Color(0xFF1E6B3A); // Highland Green — fasting/vegan/success
  static const Color neutralDark = Color(0xFF21130A); // Abyssinian Teff Brown — body text
  static const Color neutralMid = Color(0xFF6E5D53); // secondary metadata / borders
  static const Color surfaceCard = Color(0xFFFFFFFF); // white elevated cards
  static const Color surfaceBg = Color(0xFFF7F4F0); // warm off-white canvas
  static const Color cardBorder = Color(0xFFD9D0C5); // 1px card borders

  static const Color halalTeal = Color(0xFF0E7C6B); // halal-observing accent
  static const Color refundBlue = Color(0xFF2F5D9E); // refund tracker accent
  static const Color dangerRed = Color(0xFFB3261E); // destructive / overcharge flags

  static const Color shadow = Color(0x14000000); // rgba(0,0,0,0.08)-ish card shadow

  static const Map<String, Color> statusSeverity = {
    'primary': primaryGold,
    'secondary': secondaryClay,
    'tsom': tsomGreen,
    'ground': surfaceGround,
    'neutral': neutralDark,
  };
}