import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/preferences_service.dart';

/// Persists and exposes the user's theme choice.
class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._preferences) : super(ThemeMode.system);

  final PreferencesService _preferences;

  /// Restores the persisted value during bootstrap.
  Future<void> load() async {
    final mode = await _preferences.readThemeMode();
    if (mounted) state = mode;
  }

  Future<void> setMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    await _preferences.writeThemeMode(mode);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
      return ThemeModeController(ref.watch(preferencesServiceProvider));
    });
