import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/session.dart';

/// Persists authentication material. Secrets never touch `shared_preferences`
/// and are never logged.
abstract interface class SessionStore {
  Future<void> saveSession(Session session);

  Future<Session?> readSession();

  Future<String?> accessToken();

  Future<void> clear();
}

/// Platform secure storage (Keychain / EncryptedSharedPreferences).
class SecureStorageService implements SessionStore {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _sessionKey = 'nascon.session';

  final FlutterSecureStorage _storage;

  @override
  Future<void> saveSession(Session session) =>
      _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));

  @override
  Future<Session?> readSession() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return Session.fromJson(decoded.cast<String, dynamic>());
    } catch (_) {
      // Corrupt payload: drop it rather than crashing bootstrap.
      await clear();
      return null;
    }
  }

  @override
  Future<String?> accessToken() async => (await readSession())?.accessToken;

  @override
  Future<void> clear() => _storage.delete(key: _sessionKey);
}

/// Non-persistent store for tests and previews.
class InMemorySessionStore implements SessionStore {
  InMemorySessionStore([this._session]);

  Session? _session;

  @override
  Future<void> saveSession(Session session) async => _session = session;

  @override
  Future<Session?> readSession() async => _session;

  @override
  Future<String?> accessToken() async => _session?.accessToken;

  @override
  Future<void> clear() async => _session = null;
}
