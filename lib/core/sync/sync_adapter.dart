import '../errors/app_exception.dart';
import '../../models/sync_queue_entry.dart';
import '../../models/sync_result.dart';
import '../network/api_client.dart';
import '../network/api_routes.dart';

/// Pushes one queued action to the backend.
///
/// Kept as a narrow boundary so the offline engine is testable without a
/// network and so the production implementation can be swapped in once the
/// sync contract arrives.
abstract interface class SyncAdapter {
  Future<SyncResult> push(SyncQueueEntry entry);
}

/// Deterministic adapter used in mock mode and tests.
///
/// Failures and conflicts are configured per action id — nothing is randomised,
/// so results are reproducible.
class MockSyncAdapter implements SyncAdapter {
  MockSyncAdapter({
    Set<String>? failActionIds,
    Set<String>? conflictActionIds,
    Set<String>? reviewActionIds,
    this.latency = const Duration(milliseconds: 120),
  }) : _failIds = failActionIds ?? const {},
       _conflictIds = conflictActionIds ?? const {},
       _reviewIds = reviewActionIds ?? const {};

  final Set<String> _failIds;
  final Set<String> _conflictIds;
  final Set<String> _reviewIds;
  final Duration latency;

  @override
  Future<SyncResult> push(SyncQueueEntry entry) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);

    if (_reviewIds.contains(entry.id)) {
      return const SyncResult(
        actionId: '',
        state: SyncState.needsReview,
        message: 'This action needs manual review before it can be applied.',
      ).copyFor(entry.id);
    }
    if (_conflictIds.contains(entry.id)) {
      return SyncResult.conflict(
        entry.id,
        'The server state changed since this action was created.',
        serverState: {'conflict': true},
      );
    }
    if (_failIds.contains(entry.id)) {
      return SyncResult.failed(
        entry.id,
        'The server rejected this action (mock failure).',
      );
    }
    return SyncResult.synced(entry.id, serverState: {'accepted': true});
  }
}

extension on SyncResult {
  SyncResult copyFor(String actionId) => SyncResult(
    actionId: actionId,
    state: state,
    message: message,
    serverState: serverState,
    retryable: retryable,
  );
}

/// Production adapter.
///
/// **PENDING BACKEND CONTRACT** — the batch sync endpoint, its request schema,
/// idempotency semantics and conflict payload have not been specified. This
/// implementation does not pretend to be connected: it reports the missing
/// contract instead of silently succeeding.
class ApiSyncAdapter implements SyncAdapter {
  ApiSyncAdapter({required ApiClient client}) : _client = client;

  final ApiClient _client;

  @override
  Future<SyncResult> push(SyncQueueEntry entry) async {
    try {
      await _client.post(
        ApiRoutes.syncBatch,
        body: {'actions': [entry.toRow()]},
        idempotencyKey: entry.id,
      );
      return SyncResult.synced(entry.id);
    } on AppException catch (error) {
      if (error.kind == AppErrorKind.pendingContract) rethrow;
      return SyncResult.failed(entry.id, error.message);
    }
  }
}
