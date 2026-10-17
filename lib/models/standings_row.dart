import 'package:flutter/foundation.dart';

/// Competition status supplied by the backend. NaSCon does not hard-code a
/// points system or tie-breaker — when the server omits this, [StandingsRow.qualification]
/// stays `null` and no badge is shown.
enum QualificationStatus {
  qualified('qualified', 'Qualified'),
  inContention('in_contention', 'In Contention'),
  eliminated('eliminated', 'Eliminated'),
  unknown('unknown', 'Unknown');

  const QualificationStatus(this.wire, this.label);

  final String wire;
  final String label;

  static QualificationStatus? fromWire(Object? value) {
    if (value is! String) return null;
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return QualificationStatus.unknown;
  }
}

/// A single row of a league table.
@immutable
class StandingsRow {
  const StandingsRow({
    required this.teamId,
    required this.teamName,
    required this.position,
    this.teamShortName,
    this.played,
    this.won,
    this.drawn,
    this.lost,
    this.points,
    this.differential,
    this.qualification,
  });

  final String teamId;
  final String teamName;
  final int position;
  final String? teamShortName;
  final int? played;
  final int? won;
  final int? drawn;
  final int? lost;
  final int? points;
  final int? differential;

  /// `null` when the backend does not supply a qualification state.
  final QualificationStatus? qualification;

  factory StandingsRow.fromJson(Map<String, dynamic> json) => StandingsRow(
    teamId: json['team_id'] as String? ?? '',
    teamName: json['team_name'] as String? ?? '',
    position: (json['position'] as num?)?.toInt() ?? 0,
    teamShortName: json['team_short_name'] as String?,
    played: (json['played'] as num?)?.toInt(),
    won: (json['won'] as num?)?.toInt(),
    drawn: (json['drawn'] as num?)?.toInt(),
    lost: (json['lost'] as num?)?.toInt(),
    points: (json['points'] as num?)?.toInt(),
    differential: (json['differential'] as num?)?.toInt(),
    qualification: QualificationStatus.fromWire(json['qualification']),
  );

  Map<String, dynamic> toJson() => {
    'team_id': teamId,
    'team_name': teamName,
    'position': position,
    'team_short_name': teamShortName,
    'played': played,
    'won': won,
    'drawn': drawn,
    'lost': lost,
    'points': points,
    'differential': differential,
    'qualification': qualification?.wire,
  };
}
