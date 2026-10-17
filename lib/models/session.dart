import 'package:flutter/foundation.dart';

import 'user.dart';

/// An authenticated session: tokens plus the resolved user.
///
/// Tokens are persisted in secure storage only; this object is never logged.
@immutable
class Session {
  const Session({
    required this.accessToken,
    required this.user,
    this.refreshToken,
    this.expiresAt,
  });

  final String accessToken;
  final String? refreshToken;
  final User user;
  final DateTime? expiresAt;

  /// A locally-known expiry is advisory: the server remains the source of truth
  /// for validity. Screens must still handle a 401 response.
  bool get isExpired {
    final expiry = expiresAt;
    return expiry != null && DateTime.now().isAfter(expiry);
  }

  Session copyWith({String? accessToken, User? user, DateTime? expiresAt}) =>
      Session(
        accessToken: accessToken ?? this.accessToken,
        refreshToken: refreshToken,
        user: user ?? this.user,
        expiresAt: expiresAt ?? this.expiresAt,
      );

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    accessToken: json['access_token'] as String? ?? '',
    refreshToken: json['refresh_token'] as String?,
    user: User.fromJson(
      (json['user'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
  );

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'user': user.toJson(),
    'expires_at': expiresAt?.toIso8601String(),
  };
}
