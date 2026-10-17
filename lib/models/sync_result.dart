import 'package:flutter/foundation.dart';

import 'sync_queue_entry.dart';

/// Outcome of attempting to synchronise a single queued action.
@immutable
class SyncResult {
  const SyncResult({
    required this.actionId,
    required this.state,
    this.message,
    this.serverState,
    this.retryable = false,
  });

  final String actionId;
  final SyncState state;
  final String? message;

  /// Server-confirmed state where the backend returned one.
  final Map<String, dynamic>? serverState;

  final bool retryable;

  bool get succeeded => state == SyncState.synced;

  factory SyncResult.synced(String actionId, {Map<String, dynamic>? serverState}) =>
      SyncResult(actionId: actionId, state: SyncState.synced, serverState: serverState);

  factory SyncResult.failed(String actionId, String message, {bool retryable = true}) =>
      SyncResult(
        actionId: actionId,
        state: SyncState.failed,
        message: message,
        retryable: retryable,
      );

  factory SyncResult.conflict(String actionId, String message, {Map<String, dynamic>? serverState}) =>
      SyncResult(
        actionId: actionId,
        state: SyncState.conflict,
        message: message,
        serverState: serverState,
      );
}
