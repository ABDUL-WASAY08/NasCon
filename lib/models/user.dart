import 'package:flutter/foundation.dart';

/// The five NaSCon roles plus an `unknown` sentinel.
///
/// Parsing never silently coerces an unrecognised role into a privileged one —
/// unknown values resolve to [UserRole.unknown], which the permission layer
/// treats as **no privileges** (fail closed).
enum UserRole {
  superAdmin('super_admin', 'Platform Super-Admin'),
  leagueOrganizer('league_organizer', 'League Organizer'),
  clubManager('club_manager', 'Club Manager'),
  player('player', 'Player'),
  viewer('viewer', 'General Viewer'),
  unknown('unknown', 'Unknown');

  const UserRole(this.wire, this.label);

  /// Value used on the wire / in storage.
  final String wire;

  /// Human-readable label.
  final String label;

  static UserRole fromWire(Object? value) {
    if (value is! String) return UserRole.unknown;
    for (final role in values) {
      if (role.wire == value) return role;
    }
    return UserRole.unknown;
  }
}

/// An authenticated user.
@immutable
class User {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    this.role = UserRole.viewer,
    this.clubId,
    this.leagueId,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;

  /// Club this user belongs to, when applicable.
  final String? clubId;

  /// League context, when applicable.
  final String? leagueId;

  final String? avatarUrl;

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.substring(0, 1);
    if (parts.length == 1) return first.toUpperCase();
    return (first + parts.last.substring(0, 1)).toUpperCase();
  }

  User copyWith({
    String? fullName,
    String? email,
    UserRole? role,
    String? clubId,
    String? leagueId,
    String? avatarUrl,
  }) {
    return User(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      clubId: clubId ?? this.clubId,
      leagueId: leagueId ?? this.leagueId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String? ?? '',
    fullName: json['full_name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    role: UserRole.fromWire(json['role']),
    clubId: json['club_id'] as String?,
    leagueId: json['league_id'] as String?,
    avatarUrl: json['avatar_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'email': email,
    'role': role.wire,
    'club_id': clubId,
    'league_id': leagueId,
    'avatar_url': avatarUrl,
  };

  @override
  bool operator ==(Object other) =>
      other is User &&
      other.id == id &&
      other.fullName == fullName &&
      other.email == email &&
      other.role == role &&
      other.clubId == clubId &&
      other.leagueId == leagueId &&
      other.avatarUrl == avatarUrl;

  @override
  int get hashCode =>
      Object.hash(id, fullName, email, role, clubId, leagueId, avatarUrl);
}
