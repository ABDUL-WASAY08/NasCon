import 'package:flutter/foundation.dart';

import 'match_event.dart';

/// A scoring entry, shaped for both direct submission and offline queueing.
///
/// The event type comes from the match's advertised configuration, so this
/// model stays sport-agnostic.
@immutable
class ScoringAction {
  const ScoringAction({
    required this.id,
    required this.matchId,
    required this.type,
    required this.teamId,
    this.teamName,
    this.playerId,
    this.playerName,
    this.points,
    this.period,
    this.minute,
    this.note,
    this.baseVersion,
    this.createdAt,
  });

  /// Stable client-generated action id (used for idempotency).
  final String id;

  final String matchId;
  final MatchEventType type;
  final String teamId;
  final String? teamName;
  final String? playerId;
  final String? playerName;
  final int? points;
  final String? period;
  final int? minute;
  final String? note;

  /// Last confirmed match version the action was based on.
  final String? baseVersion;

  final DateTime? createdAt;

  String get summary {
    final who = playerName ?? teamName ?? 'Team';
    return '${type.label} — $who';
  }

  Map<String, dynamic> toPayload() => {
    'action_id': id,
    'match_id': matchId,
    'type': type.wire,
    'team_id': teamId,
    'team_name': teamName,
    'player_id': playerId,
    'player_name': playerName,
    'points': points,
    'period': period,
    'minute': minute,
    'note': note,
    'base_version': baseVersion,
  };
}
