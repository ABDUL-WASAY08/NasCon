import 'package:flutter_test/flutter_test.dart';

import 'package:nescom/core/storage/local_database.dart';
import 'package:nescom/core/sync/sync_adapter.dart';
import 'package:nescom/core/sync/sync_service.dart';
import 'package:nescom/models/sync_queue_entry.dart';
import 'package:nescom/models/sync_result.dart';

/// Records what the adapter was asked to push.
class _RecordingAdapter implements SyncAdapter {
  _RecordingAdapter({this.failIds = const {}, this.conflictIds = const {}});

  final Set<String> failIds;
  final Set<String> conflictIds;
  final List<String> pushed = [];

  @override
  Future<SyncResult> push(SyncQueueEntry entry) async {
    pushed.add(entry.id);
    if (conflictIds.contains(entry.id)) {
      return SyncResult.conflict(entry.id, 'stale base version');
    }
    if (failIds.contains(entry.id)) {
      return SyncResult.failed(entry.id, 'server rejected');
    }
    return SyncResult.synced(entry.id);
  }
}

SyncQueueEntry _entry(String id, {int minuteOffset = 0}) => SyncQueueEntry(
  id: id,
  actionType: SyncActionTypes.rosterTransfer,
  entityId: 'cl_falcons',
  payload: const {'player': 'Zain'},
  createdAt: DateTime(2026).add(Duration(minutes: minuteOffset)),
);

void main() {
  late MemoryLocalDatabase database;

  setUp(() async {
    database = MemoryLocalDatabase();
    await database.open();
  });

  test('queued actions survive a repository restart', () async {
    final first = SyncService(
      database: database,
      adapter: _RecordingAdapter(),
    );
    await first.enqueue(
      actionType: SyncActionTypes.scoringEvent,
      entityId: 'fx_03',
      payload: const {'type': 'goal'},
    );

    // A new service over the same store represents a fresh app launch.
    final second = SyncService(
      database: database,
      adapter: _RecordingAdapter(),
    );
    final pending = await second.pendingActions();
    expect(pending, hasLength(1));
    expect(pending.first.state, SyncState.pending);
    expect(pending.first.payload['type'], 'goal');
  });

  test('syncs every pending action and marks them synced', () async {
    await database.enqueue(_entry('a1'));
    await database.enqueue(_entry('a2', minuteOffset: 1));

    final adapter = _RecordingAdapter();
    final service = SyncService(database: database, adapter: adapter);

    final summary = await service.syncNow();

    expect(summary.attempted, 2);
    expect(summary.succeeded, 2);
    expect(summary.hadFailures, isFalse);
    expect(adapter.pushed, ['a1', 'a2']); // oldest first
    for (final entry in await database.queueEntries()) {
      expect(entry.state, SyncState.synced);
    }
  });

  test('a failed action is preserved with its error, and others still sync',
      () async {
    await database.enqueue(_entry('ok'));
    await database.enqueue(_entry('bad', minuteOffset: 1));

    final service = SyncService(
      database: database,
      adapter: _RecordingAdapter(failIds: {'bad'}),
    );

    final summary = await service.syncNow();

    expect(summary.succeeded, 1);
    expect(summary.failed, 1);
    final failed = await database.findQueueEntry('bad');
    expect(failed!.state, SyncState.failed);
    expect(failed.lastError, isNotNull);
    expect(failed.attempts, 1);

    final succeeded = await database.findQueueEntry('ok');
    expect(succeeded!.state, SyncState.synced);
  });

  test('retryFailed retries failures but never touches conflicts', () async {
    await database.enqueue(_entry('bad'));
    await database.enqueue(_entry('conflict', minuteOffset: 1));

    final service = SyncService(
      database: database,
      adapter: _RecordingAdapter(
        failIds: {'bad'},
        conflictIds: {'conflict'},
      ),
    );

    await service.syncNow();
    expect((await database.findQueueEntry('conflict'))!.state, SyncState.conflict);

    // Second pass with a healthy adapter: only the failed one is retried.
    final healthy = SyncService(
      database: database,
      adapter: _RecordingAdapter(),
    );
    final summary = await healthy.retryFailed();

    expect(summary.attempted, 1);
    expect((await database.findQueueEntry('bad'))!.state, SyncState.synced);
    expect(
      (await database.findQueueEntry('conflict'))!.state,
      SyncState.conflict,
    );
  });

  test('a conflict is preserved and explained, never discarded', () async {
    await database.enqueue(_entry('c1'));
    final service = SyncService(
      database: database,
      adapter: _RecordingAdapter(conflictIds: {'c1'}),
    );

    final summary = await service.syncNow();

    expect(summary.conflicts, 1);
    final entry = await database.findQueueEntry('c1');
    expect(entry, isNotNull);
    expect(entry!.state, SyncState.conflict);
    expect(entry.lastError, contains('stale'));
    expect(entry.state.needsHuman, isTrue);
  });

  test('syncNow is single-flight', () async {
    await database.enqueue(_entry('a1'));
    final service = SyncService(
      database: database,
      adapter: MockSyncAdapter(latency: const Duration(milliseconds: 30)),
    );

    final first = service.syncNow();
    final second = service.syncNow();

    expect(identical(first, second), isTrue);
    await first;
  });

  test('an empty queue reports a clean, no-op pass', () async {
    final service = SyncService(
      database: database,
      adapter: _RecordingAdapter(),
    );
    final summary = await service.syncNow();
    expect(summary.attempted, 0);
    expect(summary.hadFailures, isFalse);
  });
}
