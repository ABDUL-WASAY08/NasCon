import 'package:flutter/foundation.dart';

import '../errors/app_exception.dart';
import '../../models/sync_queue_entry.dart';
import '../../models/sync_result.dart';
import '../storage/local_database.dart';
import 'sync_adapter.dart';

/// Aggregate outcome of a synchronisation pass.
@immutable
class SyncSummary {
  const SyncSummary({
    this.attempted = 0,
    this.succeeded = 0,
    this.failed = 0,
    this.conflicts = 0,
    this.needsReview = 0,
    this.lastSyncedAt,
  });

  final int attempted;
  final int succeeded;
  final int failed;
  final int conflicts;
  final int needsReview;
  final DateTime? lastSyncedAt;

  bool get hadFailures => failed > 0 || conflicts > 0 || needsReview > 0;
}

/// Drains the persistent offline queue.
///
/// Guarantees:
///  * single-flight — a second [syncNow] while one is running is rejected;
///  * ordering — actions are pushed oldest-first;
///  * at-most-once per pass — each action carries its stable client id as the
///    idempotency key;
///  * nothing is discarded on failure — a failed action stays queued with its
///    error and attempt count, and conflicts/needs-review are preserved for a
///    human.
class SyncService {
  SyncService({
    required LocalDatabase database,
    required SyncAdapter adapter,
    DateTime Function()? clock,
  }) : _database = database,
       _adapter = adapter,
       _clock = clock ?? DateTime.now;

  final LocalDatabase _database;
  final SyncAdapter _adapter;
  final DateTime Function() _clock;

  Future<SyncSummary>? _inFlight;
  DateTime? _lastSyncedAt;

  bool get isSyncing => _inFlight != null;

  DateTime? get lastSyncedAt => _lastSyncedAt;

  /// Queues an action for later delivery. Persisted immediately, so it survives
  /// a force-close.
  Future<SyncQueueEntry> enqueue({
    required String actionType,
    required String entityId,
    required Map<String, dynamic> payload,
    String? baseVersion,
  }) async {
    final entry = SyncQueueEntry(
      id: '${actionType}_${entityId}_${_clock().microsecondsSinceEpoch}',
      actionType: actionType,
      entityId: entityId,
      payload: payload,
      baseVersion: baseVersion,
      createdAt: _clock(),
    );
    await _database.enqueue(entry);
    return entry;
  }

  Future<List<SyncQueueEntry>> pendingActions() async {
    final all = await _database.queueEntries();
    return all.where((entry) => !entry.state.isTerminal).toList();
  }

  Future<List<SyncQueueEntry>> allActions() => _database.queueEntries();

  /// Runs one synchronisation pass. Never throws for an individual action's
  /// failure — the result is reported instead.
  ///
  /// Single-flight: a caller that arrives while a pass is running receives the
  /// same future rather than starting a second pass.
  Future<SyncSummary> syncNow() {
    final existing = _inFlight;
    if (existing != null) return existing;

    final run = _run().whenComplete(() => _inFlight = null);
    _inFlight = run;
    return run;
  }

  Future<SyncSummary> _run() async {
    var attempted = 0;
    var succeeded = 0;
    var failed = 0;
    var conflicts = 0;
    var needsReview = 0;

    final entries = (await _database.queueEntries())
        .where((entry) => entry.state.isRetryable)
        .toList();

    for (final entry in entries) {
      attempted++;
      await _database.updateQueueEntry(
        entry.copyWith(state: SyncState.syncing, updatedAt: _clock()),
      );

      SyncResult result;
      try {
        result = await _adapter.push(entry);
      } on AppException catch (error) {
        result = SyncResult.failed(
          entry.id,
          error.message,
          retryable: error.isRetryable,
        );
      } catch (_) {
        result = SyncResult.failed(entry.id, 'Unexpected sync error.');
      }

      switch (result.state) {
        case SyncState.synced:
          succeeded++;
          await _database.updateQueueEntry(
            entry.copyWith(
              state: SyncState.synced,
              attempts: entry.attempts + 1,
              updatedAt: _clock(),
              serverResult: result.serverState,
              clearError: true,
            ),
          );
        case SyncState.conflict:
          conflicts++;
          await _database.updateQueueEntry(
            entry.copyWith(
              state: SyncState.conflict,
              attempts: entry.attempts + 1,
              lastError: result.message,
              updatedAt: _clock(),
              serverResult: result.serverState,
            ),
          );
        case SyncState.needsReview:
          needsReview++;
          await _database.updateQueueEntry(
            entry.copyWith(
              state: SyncState.needsReview,
              attempts: entry.attempts + 1,
              lastError: result.message,
              updatedAt: _clock(),
            ),
          );
        case SyncState.pending:
        case SyncState.syncing:
        case SyncState.failed:
          failed++;
          await _database.updateQueueEntry(
            entry.copyWith(
              state: SyncState.failed,
              attempts: entry.attempts + 1,
              lastError: result.message ?? 'Sync failed.',
              updatedAt: _clock(),
            ),
          );
      }
    }

    if (attempted == 0 || succeeded > 0) {
      _lastSyncedAt = _clock();
    }

    return SyncSummary(
      attempted: attempted,
      succeeded: succeeded,
      failed: failed,
      conflicts: conflicts,
      needsReview: needsReview,
      lastSyncedAt: _lastSyncedAt,
    );
  }

  /// Retries only actions that are safe to retry; conflicts and needs-review
  /// items are left untouched for a human.
  Future<SyncSummary> retryFailed() async {
    final entries = await _database.queueEntries();
    for (final entry in entries) {
      if (entry.state == SyncState.conflict ||
          entry.state == SyncState.needsReview) {
        continue;
      }
      if (entry.state == SyncState.failed) {
        await _database.updateQueueEntry(
          entry.copyWith(state: SyncState.pending, updatedAt: _clock()),
        );
      }
    }
    return syncNow();
  }
}
