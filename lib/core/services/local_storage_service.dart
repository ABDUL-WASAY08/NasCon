import 'package:shared_preferences/shared_preferences.dart';

/// Well-known keys used with [LocalStorageService].
abstract final class StorageKeys {
  static const String authToken = 'auth_token';
  static const String currentUser = 'current_user';
  static const String onboardingSeen = 'onboarding_seen';
  static const String themeMode = 'theme_mode';
}

/// Thin, typed wrapper around `shared_preferences`.
class LocalStorageService {
  LocalStorageService._();

  static final LocalStorageService instance = LocalStorageService._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _store async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  String? getString(String key) => _prefs?.getString(key);
  bool? getBool(String key) => _prefs?.getBool(key);
  int? getInt(String key) => _prefs?.getInt(key);

  Future<bool> setString(String key, String value) async =>
      (await _store).setString(key, value);
  Future<bool> setBool(String key, bool value) async =>
      (await _store).setBool(key, value);
  Future<bool> setInt(String key, int value) async =>
      (await _store).setInt(key, value);

  Future<bool> remove(String key) async => (await _store).remove(key);
  Future<bool> clear() async => (await _store).clear();
}
