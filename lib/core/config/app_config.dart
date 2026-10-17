import 'package:flutter/foundation.dart';

/// Runtime configuration.
///
/// Everything here is supplied at build time so no environment-specific value
/// (and no secret) lives in source control. Defaults are safe for local
/// development against the mock backend.
///
/// ```bash
/// # Emulator (Android emulator reaches the host loopback via 10.0.2.2)
/// flutter run --dart-define=USE_MOCK_BACKEND=false \
///             --dart-define=API_BASE_URL=http://10.0.2.2:8080/v1
///
/// # Physical device (use your machine's LAN address)
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8080/v1
///
/// # Production
/// flutter build apk --release \
///   --dart-define=USE_MOCK_BACKEND=false \
///   --dart-define=API_BASE_URL=https://api.nascon.example/v1
/// ```
@immutable
class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.useMockBackend,
    this.connectTimeout = const Duration(seconds: 20),
    this.receiveTimeout = const Duration(seconds: 20),
  });

  /// Base URL of the NaSCon API. Never hard-code `localhost` in source — the
  /// emulator uses `10.0.2.2`, a physical device uses the host's LAN address,
  /// and production supplies the real host via `--dart-define`.
  final String apiBaseUrl;

  /// When `true` the app resolves every repository to its **mock**
  /// implementation. This is the default so the app is fully usable before the
  /// backend exists. It is surfaced in the UI so mock data is never mistaken
  /// for live data.
  final bool useMockBackend;

  final Duration connectTimeout;
  final Duration receiveTimeout;

  static const String _defaultApiBaseUrl = 'http://10.0.2.2:8080/v1';

  factory AppConfig.fromEnvironment() => AppConfig(
    apiBaseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: _defaultApiBaseUrl,
    ),
    useMockBackend: const bool.fromEnvironment(
      'USE_MOCK_BACKEND',
      defaultValue: true,
    ),
  );

  /// Convenience for tests and local previews.
  factory AppConfig.mock({String apiBaseUrl = _defaultApiBaseUrl}) =>
      AppConfig(apiBaseUrl: apiBaseUrl, useMockBackend: true);
}
