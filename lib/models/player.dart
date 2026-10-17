import 'package:flutter/foundation.dart';

/// Availability of a squad member.
enum PlayerStatus {
  active('active', 'Active'),
  injured('injured', 'Injured'),
  suspended('suspended', 'Suspended'),
  unavailable('unavailable', 'Unavailable'),
  unknown('unknown', 'Unknown');

  const PlayerStatus(this.wire, this.label);

  final String wire;
  final String label;

  static PlayerStatus fromWire(Object? value) {
    if (value is! String) return PlayerStatus.unknown;
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return PlayerStatus.unknown;
  }
}

/// A player registered to a club.
@immutable
class Player {
  const Player({
    required this.id,
    required this.name,
    required this.clubId,
    this.position,
    this.jerseyNumber,
    this.status = PlayerStatus.active,
    this.loanClubId,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String clubId;
  final String? position;
  final int? jerseyNumber;
  final PlayerStatus status;

  /// Set when the player is currently out on loan.
  final String? loanClubId;

  final String? avatarUrl;

  bool get isOnLoan => loanClubId != null;

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    clubId: json['club_id'] as String? ?? '',
    position: json['position'] as String?,
    jerseyNumber: (json['jersey_number'] as num?)?.toInt(),
    status: PlayerStatus.fromWire(json['status']),
    loanClubId: json['loan_club_id'] as String?,
    avatarUrl: json['avatar_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'club_id': clubId,
    'position': position,
    'jersey_number': jerseyNumber,
    'status': status.wire,
    'loan_club_id': loanClubId,
    'avatar_url': avatarUrl,
  };
}
