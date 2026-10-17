import '../models/session.dart';
import '../models/user.dart';

/// Authentication and session lifecycle.
abstract interface class AuthRepository {
  /// Creates an account and persists the resulting authenticated session.
  Future<Session> register({
    required String fullName,
    required String email,
    required String password,
  });

  /// Exchanges credentials for a session. Throws an `AppException` on invalid
  /// credentials, network failure or a malformed response.
  Future<Session> signIn({required String email, required String password});

  /// Clears server (if applicable) and local credentials.
  Future<void> signOut();

  /// Reads a persisted session, if any. Does not by itself prove the session is
  /// still valid — the API layer surfaces a 401 for that.
  Future<Session?> restoreSession();

  /// Refreshes the current user profile (role/context may have changed).
  Future<User> currentUser();
}
