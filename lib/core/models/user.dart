import 'package:flutter/foundation.dart';

/// A signed-in user.
@immutable
class User {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.role = 'member',
  });

  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String role;

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
    String? avatarUrl,
    String? role,
  }) {
    return User(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    fullName: json['full_name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String?,
    role: json['role'] as String? ?? 'member',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'email': email,
    'avatar_url': avatarUrl,
    'role': role,
  };
}
