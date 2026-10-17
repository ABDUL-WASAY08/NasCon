import 'package:flutter/foundation.dart';

/// The roster operations the app can request.
enum RosterActionType {
  add('add', 'Add player'),
  transfer('transfer', 'Transfer player'),
  loan('loan', 'Loan player'),
  release('release', 'Release player');

  const RosterActionType(this.wire, this.label);

  final String wire;
  final String label;

  static RosterActionType fromWire(Object? value) {
    for (final type in values) {
      if (type.wire == value) return type;
    }
    return RosterActionType.add;
  }
}

/// A roster operation, shaped for both direct submission and offline queueing.
@immutable
class RosterAction {
  const RosterAction({
    required this.id,
    required this.type,
    required this.clubId,
    required this.playerId,
    required this.playerName,
    this.destinationClubId,
    this.returnDate,
    this.position,
    this.jerseyNumber,
    this.baseVersion,
    this.createdAt,
  });

  /// Stable client-generated action id (used for idempotency).
  final String id;

  final RosterActionType type;
  final String clubId;
  final String playerId;
  final String playerName;
  final String? destinationClubId;
  final DateTime? returnDate;
  final String? position;
  final int? jerseyNumber;

  /// Squad version the action was based on, for conflict detection.
  final String? baseVersion;

  final DateTime? createdAt;

  /// Whether this action is safe to queue and reconcile while offline.
  bool get isOfflineCapable => switch (type) {
    RosterActionType.add ||
    RosterActionType.transfer ||
    RosterActionType.loan ||
    RosterActionType.release => true,
  };

  String get summary => switch (type) {
    RosterActionType.add => 'Add $playerName',
    RosterActionType.transfer => 'Transfer $playerName',
    RosterActionType.loan => 'Loan $playerName',
    RosterActionType.release => 'Release $playerName',
  };

  Map<String, dynamic> toPayload() => {
    'action_id': id,
    'type': type.wire,
    'club_id': clubId,
    'player_id': playerId,
    'player_name': playerName,
    'destination_club_id': destinationClubId,
    'return_date': returnDate?.toUtc().toIso8601String(),
    'position': position,
    'jersey_number': jerseyNumber,
    'base_version': baseVersion,
  };
}
