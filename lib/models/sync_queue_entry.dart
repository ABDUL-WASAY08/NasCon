import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Lifecycle of a queued offline action.
///
/// An action is **never** treated as officially committed until it reaches
/// [SyncState.synced] on the server's acknowledgement.
enum SyncState {
  pending('pending', 'Pending'),
  syncing('syncing', 'Syncing'),
  synced('synced', 'Synced'),
  failed('failed', 'Failed'),
  conflict('conflict', 'Conflict'),
  needsReview('needs_review', 'Needs review');

  const SyncState(this.wire, this.label);

  final String wire;
  final String label;

  bool get isTerminal => this == SyncState.synced;

  /// Whether an automatic/manual retry is safe for this action.
  bool get isRetryable =>
      this == SyncState.pending || this == SyncState.failed;

  /// Whether a human must resolve it (never auto-discarded).
  bool get needsHuman =>
      this == SyncState.conflict || this == SyncState.needsReview;

  static SyncState fromWire(Object? value) {
    if (value is! String) return SyncState.pending;
    for (final state in values) {
      if (state.wire == value) return state;
    }
    return SyncState.pending;
  }
}

/// Action-type keys stored in the queue.
abstract final class SyncActionTypes {
  static const String scoringEvent = 'scoring_event';
  static const String rosterAdd = 'roster_add';
  static const String rosterTransfer = 'roster_transfer';
  static const String rosterLoan = 'roster_loan';
  static const String rosterRelease = 'roster_release';

  static String describe(String type) => switch (type) {
    scoringEvent => 'Scoring event',
    rosterAdd => 'Add player',
    rosterTransfer => 'Transfer player',
    rosterLoan => 'Loan player',
    rosterRelease => 'Release player',
    _ => type,
  };
}

/// A durable offline action. Persisted in SQLite so it survives force-close.
@immutable
class SyncQueueEntry {
  const SyncQueueEntry({
    required this.id,
    required this.actionType,
    required this.entityId,
    required this.payload,
    required this.createdAt,
    this.state = SyncState.pending,
    this.attempts = 0,
    this.lastError,
    this.baseVersion,
    this.updatedAt,
    this.serverResult,
  });

  /// Stable client-generated id — the idempotency key sent to the server.
  final String id;

  final String actionType;

  /// Owning entity (match id for scoring, club id for roster).
  final String entityId;

  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final SyncState state;
  final int attempts;
  final String? lastError;

  /// Server version the action was based on, for conflict detection.
  final String? baseVersion;

  final DateTime? updatedAt;
  final Map<String, dynamic>? serverResult;

  String get description => SyncActionTypes.describe(actionType);

  SyncQueueEntry copyWith({
    SyncState? state,
    int? attempts,
    String? lastError,
    DateTime? updatedAt,
    Map<String, dynamic>? serverResult,
    bool clearError = false,
  }) => SyncQueueEntry(
    id: id,
    actionType: actionType,
    entityId: entityId,
    payload: payload,
    createdAt: createdAt,
    state: state ?? this.state,
    attempts: attempts ?? this.attempts,
    lastError: clearError ? null : (lastError ?? this.lastError),
    baseVersion: baseVersion,
    updatedAt: updatedAt ?? this.updatedAt,
    serverResult: serverResult ?? this.serverResult,
  );

  /// SQLite row representation (payloads stored as JSON strings).
  Map<String, Object?> toRow() => {
    'id': id,
    'action_type': actionType,
    'entity_id': entityId,
    'payload': jsonEncode(payload),
    'created_at': createdAt.toUtc().millisecondsSinceEpoch,
    'state': state.wire,
    'attempts': attempts,
    'last_error': lastError,
    'base_version': baseVersion,
    'updated_at': updatedAt?.toUtc().millisecondsSinceEpoch,
    'server_result': serverResult == null ? null : jsonEncode(serverResult),
  };

  factory SyncQueueEntry.fromRow(Map<String, Object?> row) => SyncQueueEntry(
    id: row['id'] as String,
    actionType: row['action_type'] as String? ?? '',
    entityId: row['entity_id'] as String? ?? '',
    payload: _decodeMap(row['payload']),
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      (row['created_at'] as int?) ?? 0,
      isUtc: true,
    ).toLocal(),
    state: SyncState.fromWire(row['state']),
    attempts: (row['attempts'] as int?) ?? 0,
    lastError: row['last_error'] as String?,
    baseVersion: row['base_version'] as String?,
    updatedAt: row['updated_at'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            row['updated_at'] as int,
            isUtc: true,
          ).toLocal(),
    serverResult: row['server_result'] == null
        ? null
        : _decodeMap(row['server_result']),
  );

  static Map<String, dynamic> _decodeMap(Object? raw) {
    if (raw is! String || raw.isEmpty) return const {};
    final decoded = jsonDecode(raw);
    return decoded is Map ? decoded.cast<String, dynamic>() : const {};
  }
}
