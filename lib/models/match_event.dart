import 'package:flutter/foundation.dart';

/// Kind of scored event. Intentionally sport-agnostic — the scoring screen is
/// driven by the event types the backend advertises for a match, not by a
/// hard-coded football model.
enum MatchEventType {
  goal('goal', 'Goal'),
  point('point', 'Point'),
  tryScore('try', 'Try'),
  wicket('wicket', 'Wicket'),
  card('card', 'Card'),
  substitution('substitution', 'Substitution'),
  periodStart('period_start', 'Period start'),
  periodEnd('period_end', 'Period end'),
  correction('correction', 'Correction'),
  other('other', 'Other'),
  unknown('unknown', 'Unknown');

  const MatchEventType(this.wire, this.label);

  final String wire;
  final String label;

  static MatchEventType fromWire(Object? value) {
    if (value is! String) return MatchEventType.unknown;
    for (final type in values) {
      if (type.wire == value) return type;
    }
    return MatchEventType.unknown;
  }
}

/// Server acknowledgement of an event.
enum EventStatus {
  confirmed('confirmed', 'Confirmed'),
  pending('pending', 'Pending'),
  corrected('corrected', 'Corrected'),
  rejected('rejected', 'Rejected'),
  unknown('unknown', 'Unknown');

  const EventStatus(this.wire, this.label);

  final String wire;
  final String label;

  static EventStatus fromWire(Object? value) {
    if (value is! String) return EventStatus.unknown;
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return EventStatus.unknown;
  }
}

/// One entry in a match timeline.
@immutable
class MatchEvent {
  const MatchEvent({
    required this.id,
    required this.matchId,
    required this.type,
    required this.sequence,
    this.teamId,
    this.teamName,
    this.playerId,
    this.playerName,
    this.description,
    this.minute,
    this.period,
    this.points,
    this.status = EventStatus.confirmed,
    this.createdAt,
    this.clientActionId,
  });

  final String id;
  final String matchId;
  final MatchEventType type;

  /// Server-defined ordering key.
  final int sequence;

  final String? teamId;
  final String? teamName;
  final String? playerId;
  final String? playerName;
  final String? description;
  final int? minute;
  final String? period;
  final int? points;
  final EventStatus status;
  final DateTime? createdAt;

  /// Present when this event originated from an offline client action.
  final String? clientActionId;

  factory MatchEvent.fromJson(Map<String, dynamic> json) => MatchEvent(
    id: json['id'] as String? ?? '',
    matchId: json['match_id'] as String? ?? '',
    type: MatchEventType.fromWire(json['type']),
    sequence: (json['sequence'] as num?)?.toInt() ?? 0,
    teamId: json['team_id'] as String?,
    teamName: json['team_name'] as String?,
    playerId: json['player_id'] as String?,
    playerName: json['player_name'] as String?,
    description: json['description'] as String?,
    minute: (json['minute'] as num?)?.toInt(),
    period: json['period'] as String?,
    points: (json['points'] as num?)?.toInt(),
    status: EventStatus.fromWire(json['status']),
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal(),
    clientActionId: json['client_action_id'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'match_id': matchId,
    'type': type.wire,
    'sequence': sequence,
    'team_id': teamId,
    'team_name': teamName,
    'player_id': playerId,
    'player_name': playerName,
    'description': description,
    'minute': minute,
    'period': period,
    'points': points,
    'status': status.wire,
    'created_at': createdAt?.toUtc().toIso8601String(),
    'client_action_id': clientActionId,
  };
}
