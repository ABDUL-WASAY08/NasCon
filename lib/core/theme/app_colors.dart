import 'package:flutter/material.dart';

/// Central colour system.
///
/// Brand and status colours are mode-independent; surfaces, borders and text are
/// split per brightness. Prefer the semantic accessors (`context.semantic`) for
/// status containers so light/dark contrast is handled for you — never scatter
/// raw hex values through widgets.
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Brand
  // ---------------------------------------------------------------------------
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryDark = Color(0xFF5646CE);
  static const Color primaryLight = Color(0xFF8B7BF0);

  static const Color secondary = Color(0xFF00B894);
  static const Color secondaryDark = Color(0xFF00997B);
  static const Color secondaryLight = Color(0xFF22D3A5);

  // ---------------------------------------------------------------------------
  // Backgrounds & surfaces
  // ---------------------------------------------------------------------------
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color darkBackground = Color(0xFF0F172A);

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

  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextMuted = Color(0xFF94A3B8);

  // ---------------------------------------------------------------------------
  // Status
  // ---------------------------------------------------------------------------
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF0284C7);

  // ---------------------------------------------------------------------------
  // Gradients
  // ---------------------------------------------------------------------------
  static const List<Color> primaryGradient = [primary, primaryLight];
  static const List<Color> brandGradient = [primary, secondary];
  static const List<Color> secondaryGradient = [secondaryLight, secondary];
}

/// Mode-aware semantic colours (status containers, muted text, borders).
///
/// Registered as a [ThemeExtension] so widgets read them from the theme:
/// `Theme.of(context).extension<AppSemanticColors>()!` or `context.semantic`.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.muted,
    required this.cardBorder,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.dangerContainer,
    required this.onDangerContainer,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.neutralContainer,
  });

  final Color muted;
  final Color cardBorder;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color dangerContainer;
  final Color onDangerContainer;
  final Color infoContainer;
  final Color onInfoContainer;
  final Color neutralContainer;

  static const AppSemanticColors light = AppSemanticColors(
    muted: AppColors.lightTextMuted,
    cardBorder: AppColors.lightBorder,
    successContainer: Color(0xFFDCFCE7),
    onSuccessContainer: Color(0xFF14532D),
    warningContainer: Color(0xFFFEF3C7),
    onWarningContainer: Color(0xFF78350F),
    dangerContainer: Color(0xFFFEE2E2),
    onDangerContainer: Color(0xFF7F1D1D),
    infoContainer: Color(0xFFE0F2FE),
    onInfoContainer: Color(0xFF075985),
    neutralContainer: Color(0xFFF1F5F9),
  );

  static const AppSemanticColors dark = AppSemanticColors(
    muted: AppColors.darkTextMuted,
    cardBorder: AppColors.darkBorder,
    successContainer: Color(0xFF14311F),
    onSuccessContainer: Color(0xFF86EFAC),
    warningContainer: Color(0xFF3A2A0B),
    onWarningContainer: Color(0xFFFCD34D),
    dangerContainer: Color(0xFF3B1616),
    onDangerContainer: Color(0xFFFCA5A5),
    infoContainer: Color(0xFF0B2A3B),
    onInfoContainer: Color(0xFF7DD3FC),
    neutralContainer: Color(0xFF243044),
  );

  @override
  AppSemanticColors copyWith({
    Color? muted,
    Color? cardBorder,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? dangerContainer,
    Color? onDangerContainer,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? neutralContainer,
  }) {
    return AppSemanticColors(
      muted: muted ?? this.muted,
      cardBorder: cardBorder ?? this.cardBorder,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      onDangerContainer: onDangerContainer ?? this.onDangerContainer,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      neutralContainer: neutralContainer ?? this.neutralContainer,
    );
  }

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      muted: Color.lerp(muted, other.muted, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      onDangerContainer: Color.lerp(
        onDangerContainer,
        other.onDangerContainer,
        t,
      )!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      neutralContainer: Color.lerp(
        neutralContainer,
        other.neutralContainer,
        t,
      )!,
    );
  }
}

/// Ergonomic access to [AppSemanticColors].
extension AppSemanticColorsX on BuildContext {
  AppSemanticColors get semantic =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.light;
}
