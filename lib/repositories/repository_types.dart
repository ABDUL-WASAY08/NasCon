import 'package:flutter/foundation.dart';

import '../models/match_event.dart';
import '../models/order.dart';
import '../models/receipt.dart';

/// Data plus its provenance, so the UI can show cached/stale state honestly.
@immutable
class Cached<T> {
  const Cached({required this.data, this.fromCache = false, this.updatedAt});

  final T data;

  /// `true` when served from the local cache because the network failed.
  final bool fromCache;

  /// When the cached copy was stored.
  final DateTime? updatedAt;

  bool isStale(Duration maxAge) {
    final updated = updatedAt;
    if (updated == null) return false;
    return DateTime.now().difference(updated) > maxAge;
  }

  Cached<R> map<R>(R Function(T value) transform) =>
      Cached<R>(data: transform(data), fromCache: fromCache, updatedAt: updatedAt);

  static Cached<T> fresh<T>(T data) => Cached<T>(data: data);
}

/// How a sport scores. Supplied by the backend per match, so the scoring screen
/// is configuration driven rather than hard-coded to one sport.
@immutable
class ScoringEventTypeConfig {
  const ScoringEventTypeConfig({
    required this.type,
    this.label,
    this.defaultPoints,
    this.requiresPlayer = false,
    this.requiresPeriod = false,
    this.isCorrection = false,
  });

  final MatchEventType type;
  final String? label;
  final int? defaultPoints;
  final bool requiresPlayer;
  final bool requiresPeriod;
  final bool isCorrection;

  String get displayLabel => label ?? type.label;

  factory ScoringEventTypeConfig.fromJson(Map<String, dynamic> json) =>
      ScoringEventTypeConfig(
        type: MatchEventType.fromWire(json['type']),
        label: json['label'] as String?,
        defaultPoints: (json['points'] as num?)?.toInt(),
        requiresPlayer: json['requires_player'] as bool? ?? false,
        requiresPeriod: json['requires_period'] as bool? ?? false,
        isCorrection: json['is_correction'] as bool? ?? false,
      );
}

@immutable
class ScoringConfig {
  const ScoringConfig({
    required this.matchId,
    this.sport,
    this.eventTypes = const [],
    this.periods = const [],
    this.allowsCorrection = false,
  });

  final String matchId;
  final String? sport;
  final List<ScoringEventTypeConfig> eventTypes;
  final List<String> periods;
  final bool allowsCorrection;

  bool get isEmpty => eventTypes.isEmpty;

  factory ScoringConfig.fromJson(Map<String, dynamic> json) => ScoringConfig(
    matchId: json['match_id'] as String? ?? '',
    sport: json['sport'] as String?,
    eventTypes:
        (json['event_types'] as List?)
            ?.whereType<Map>()
            .map(
              (e) =>
                  ScoringEventTypeConfig.fromJson(e.cast<String, dynamic>()),
            )
            .toList() ??
        const [],
    periods:
        (json['periods'] as List?)?.whereType<String>().toList() ?? const [],
    allowsCorrection: json['allows_correction'] as bool? ?? false,
  );
}

/// Squad constraints. Any field may be unknown (`null`), and unknown means the
/// app must not assume a modification is permitted.
@immutable
class RosterLimits {
  const RosterLimits({
    this.squadSize,
    this.maxSquadSize,
    this.transferWindowOpen,
    this.positionRequirements = const {},
    this.restrictions = const [],
  });

  final int? squadSize;
  final int? maxSquadSize;
  final bool? transferWindowOpen;
  final Map<String, int> positionRequirements;
  final List<String> restrictions;

  bool get isFull =>
      squadSize != null && maxSquadSize != null && squadSize! >= maxSquadSize!;

  /// Fail closed: an unknown transfer-window state blocks modifications.
  bool get canModifySquad => transferWindowOpen ?? false;

  factory RosterLimits.fromJson(Map<String, dynamic> json) => RosterLimits(
    squadSize: (json['squad_size'] as num?)?.toInt(),
    maxSquadSize: (json['max_squad_size'] as num?)?.toInt(),
    transferWindowOpen: json['transfer_window_open'] as bool?,
    positionRequirements:
        (json['position_requirements'] as Map?)?.map(
          (key, value) => MapEntry('$key', (value as num).toInt()),
        ) ??
        const {},
    restrictions:
        (json['restrictions'] as List?)?.whereType<String>().toList() ??
        const [],
  );
}

/// Result of a successful checkout.
@immutable
class CheckoutResult {
  const CheckoutResult({required this.order, this.receipt});

  final Order order;
  final Receipt? receipt;
}

/// Which fixtures to show.
enum FixtureFilter {
  all('All'),
  upcoming('Upcoming'),
  live('Live'),
  completed('Completed');

  const FixtureFilter(this.label);

  final String label;
}
