import 'package:flutter/material.dart';

/// Central colour system for the app.
///
/// Brand and status colours are mode-independent; surfaces, borders and text
/// are split per brightness. Widgets should prefer `Theme.of(context)` and fall
/// back to the light/dark constants here only for one-off cases.
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Brand
  // ---------------------------------------------------------------------------
  /// Primary accent — deep indigo / violet.
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryDark = Color(0xFF5646CE);
  static const Color primaryLight = Color(0xFF8B7BF0);

  /// Secondary accent — vibrant mint green.
  static const Color secondary = Color(0xFF00B894);
  static const Color secondaryDark = Color(0xFF00997B);
  static const Color secondaryLight = Color(0xFF22D3A5);

  // ---------------------------------------------------------------------------
  // Backgrounds
  // ---------------------------------------------------------------------------
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color darkBackground = Color(0xFF0F172A);

  // ---------------------------------------------------------------------------
  // Surfaces / cards (with subtle border shades)
  // ---------------------------------------------------------------------------
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color darkSurface = Color(0xFF1E293B);

  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color darkBorder = Color(0xFF334155);

  // ---------------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------------
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextMuted = Color(0xFF64748B);

  // ---------------------------------------------------------------------------
  // Status
  // ---------------------------------------------------------------------------
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ---------------------------------------------------------------------------
  // Gradients
  // ---------------------------------------------------------------------------
  static const List<Color> primaryGradient = [primary, primaryLight];
  static const List<Color> brandGradient = [primary, secondary];
  static const List<Color> secondaryGradient = [secondaryLight, secondary];
}
