/// App-wide, build-time constants and layout tokens.
abstract final class AppConstants {
  static const String appName = 'NaSCon \u201926';
  static const String appTagline = 'Multi-Sport League & Club Operations';
  static const String appVersion = '1.0.0';

  /// Shown wherever mock data is in use so it is never mistaken for live data.
  static const String mockModeLabel = 'Demo data';

  // Motion timing
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 350);
  static const Duration animationSlow = Duration(milliseconds: 550);

  /// Caps form/content width so it stays readable on tablets and desktop.
  static const double maxContentWidth = 480;

  /// Cached data older than this is flagged as stale in the UI.
  static const Duration staleAfter = Duration(minutes: 15);

  /// Upper bound on cached rows we page in one query.
  static const int pageSize = 50;
}

/// Spacing scale (4pt base).
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

/// Corner radii.
abstract final class AppRadius {
  static const double sm = 8;
  static const double input = 12;
  static const double button = 14;
  static const double card = 16;
  static const double sheet = 24;
  static const double pill = 999;
}

/// Fixed dimensions.
abstract final class AppSizes {
  /// Minimum accessible touch target.
  static const double minTouchTarget = 48;
  static const double buttonHeight = 52;
  static const double buttonHeightSmall = 44;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double avatarSm = 36;
  static const double avatarMd = 48;
  static const double avatarLg = 96;
}
