import 'package:flutter/foundation.dart';

/// Lifecycle of a fixture.
enum MatchStatus {
  scheduled('scheduled', 'Upcoming'),
  live('live', 'Live'),
  completed('completed', 'Completed'),
  postponed('postponed', 'Postponed'),
  cancelled('cancelled', 'Cancelled'),
  unknown('unknown', 'Unknown');

  const MatchStatus(this.wire, this.label);

  final String wire;
  final String label;

  static MatchStatus fromWire(Object? value) {
    if (value is! String) return MatchStatus.unknown;
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return MatchStatus.unknown;
  }
}

/// A lightweight reference to a participating team.
@immutable
class TeamRef {
  const TeamRef({
    required this.id,
    required this.name,
    this.shortName,
    this.logoUrl,
  });

  final String id;
  final String name;
  final String? shortName;
  final String? logoUrl;

  String get displayName => shortName?.trim().isNotEmpty == true
      ? shortName!.trim()
      : name;

  String get initials {
    final source = name.trim();
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
    return words.take(3).map((w) => w.substring(0, 1)).join().toUpperCase();
  }

  factory TeamRef.fromJson(Map<String, dynamic> json) => TeamRef(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    shortName: json['short_name'] as String?,
    logoUrl: json['logo_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'short_name': shortName,
    'logo_url': logoUrl,
  };
}

/// A scheduled (or played) match between two teams.
@immutable
class Fixture {
  const Fixture({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.kickoff,
    this.leagueId,
    this.venue,
    this.status = MatchStatus.scheduled,
    this.homeScore,
    this.awayScore,
    this.minute,
    this.round,
  });

  final String id;
  final TeamRef homeTeam;
  final TeamRef awayTeam;
  final DateTime kickoff;
  final String? leagueId;
  final String? venue;
  final MatchStatus status;
  final int? homeScore;
  final int? awayScore;
  final int? minute;
  final String? round;

  bool get hasScore => homeScore != null && awayScore != null;

  bool get isUpcoming =>
      status == MatchStatus.scheduled || status == MatchStatus.postponed;

  bool get isLive => status == MatchStatus.live;

  bool get isCompleted => status == MatchStatus.completed;

  factory Fixture.fromJson(Map<String, dynamic> json) => Fixture(
    id: json['id'] as String? ?? '',
    homeTeam: TeamRef.fromJson(
      (json['home_team'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    awayTeam: TeamRef.fromJson(
      (json['away_team'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    kickoff:
        DateTime.tryParse(json['kickoff'] as String? ?? '')?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0),
    leagueId: json['league_id'] as String?,
    venue: json['venue'] as String?,
    status: MatchStatus.fromWire(json['status']),
    homeScore: (json['home_score'] as num?)?.toInt(),
    awayScore: (json['away_score'] as num?)?.toInt(),
    minute: (json['minute'] as num?)?.toInt(),
    round: json['round'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'home_team': homeTeam.toJson(),
    'away_team': awayTeam.toJson(),
    'kickoff': kickoff.toUtc().toIso8601String(),
    'league_id': leagueId,
    'venue': venue,
    'status': status.wire,
    'home_score': homeScore,
    'away_score': awayScore,
    'minute': minute,
    'round': round,
  };
}
