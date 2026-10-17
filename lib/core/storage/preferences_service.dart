import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive preferences (theme, onboarding). Secrets belong in
/// [SecureStorageService].
class PreferencesService {
  PreferencesService({SharedPreferences? prefs}) : _prefs = prefs;

  static const String _themeKey = 'nascon.theme_mode';
  static const String _onboardingKey = 'nascon.onboarding_seen';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _store async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<ThemeMode> readThemeMode() async {
    final raw = (await _store).getString(_themeKey);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> writeThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await (await _store).setString(_themeKey, value);
  }

  Future<bool> readOnboardingSeen() async =>
      (await _store).getBool(_onboardingKey) ?? false;

  Future<void> writeOnboardingSeen(bool value) async =>
      (await _store).setBool(_onboardingKey, value);
}

/// Overridden at bootstrap with an initialised instance.
final preferencesServiceProvider = Provider<PreferencesService>(
  (ref) => PreferencesService(),
);
