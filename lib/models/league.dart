import 'package:flutter/foundation.dart';

/// A competition within the platform (e.g. "NaSCon Football 2026").
@immutable
class League {
  const League({
    required this.id,
    required this.name,
    this.season,
    this.sport,
    this.teamCount,
  });

  final String id;
  final String name;
  final String? season;

  /// Free-form sport key (`football`, `cricket`, …). Scoring is configuration
  /// driven off this, never hard-coded to one sport.
  final String? sport;

  final int? teamCount;

  factory League.fromJson(Map<String, dynamic> json) => League(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    season: json['season'] as String?,
    sport: json['sport'] as String?,
    teamCount: (json['team_count'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'season': season,
    'sport': sport,
    'team_count': teamCount,
  };
}
