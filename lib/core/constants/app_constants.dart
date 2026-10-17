/// App-wide, build-time constants.
abstract final class AppConstants {
  static const String appName = 'Nescom';
  static const String appTagline = 'Book. Manage. Grow.';
  static const String appVersion = '1.0.0';

  /// Backend root used by [ApiClient]. Swap per environment.
  static const String apiBaseUrl = 'https://api.nescom.app/v1';

  /// How long the splash lingers before handing off to auth.
  static const Duration splashDuration = Duration(milliseconds: 2600);

  // ---------------------------------------------------------------------------
  // Shared motion timing
  // ---------------------------------------------------------------------------
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 350);
  static const Duration animationSlow = Duration(milliseconds: 550);

  /// Caps form/content width so it stays readable on tablets and desktop.
  static const double maxContentWidth = 480;
}

/// Consistent spacing scale (4pt base).
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}
