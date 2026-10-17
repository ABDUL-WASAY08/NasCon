import 'package:flutter/foundation.dart';

/// Aggregate win/loss record for a club. Every field is optional because the
/// backend may not supply all of them — the UI must not invent the gaps.
@immutable
class ClubStats {
  const ClubStats({
    this.played,
    this.won,
    this.drawn,
    this.lost,
    this.points,
    this.differential,
  });

  final int? played;
  final int? won;
  final int? drawn;
  final int? lost;
  final int? points;
  final int? differential;

  factory ClubStats.fromJson(Map<String, dynamic> json) => ClubStats(
    played: (json['played'] as num?)?.toInt(),
    won: (json['won'] as num?)?.toInt(),
    drawn: (json['drawn'] as num?)?.toInt(),
    lost: (json['lost'] as num?)?.toInt(),
    points: (json['points'] as num?)?.toInt(),
    differential: (json['differential'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    'played': played,
    'won': won,
    'drawn': drawn,
    'lost': lost,
    'points': points,
    'differential': differential,
  };
}

/// A club / team.
@immutable
class Club {
  const Club({
    required this.id,
    required this.name,
    this.shortName,
    this.leagueId,
    this.logoUrl,
    this.description,
    this.stats,
  });

  final String id;
  final String name;
  final String? shortName;
  final String? leagueId;
  final String? logoUrl;
  final String? description;
  final ClubStats? stats;

  /// 2–3 letter monogram used when no logo is available.
  String get initials {
    final source = (shortName?.trim().isNotEmpty ?? false)
        ? shortName!.trim()
        : name.trim();
    if (source.isEmpty) return '?';
    final words = source
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.length == 1) {
      return words.first
          .substring(0, words.first.length >= 3 ? 3 : words.first.length)
          .toUpperCase();
    }
    return words
        .take(3)
        .map((w) => w.substring(0, 1))
        .join()
        .toUpperCase();
  }

  factory Club.fromJson(Map<String, dynamic> json) => Club(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    shortName: json['short_name'] as String?,
    leagueId: json['league_id'] as String?,
    logoUrl: json['logo_url'] as String?,
    description: json['description'] as String?,
    stats: json['stats'] is Map
        ? ClubStats.fromJson((json['stats'] as Map).cast<String, dynamic>())
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'short_name': shortName,
    'league_id': leagueId,
    'logo_url': logoUrl,
    'description': description,
    'stats': stats?.toJson(),
  };
}
