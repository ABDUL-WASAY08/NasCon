import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/connectivity/connectivity_service.dart';
import '../core/permissions/app_permissions.dart';
import '../core/storage/local_database.dart';
import '../core/storage/secure_storage_service.dart';
import '../core/services/api_service.dart';
import '../core/sync/sync_adapter.dart';
import '../core/sync/sync_service.dart';
import '../models/session.dart';
import '../models/sync_queue_entry.dart';
import '../core/network/api_client.dart';
import 'api/api_repositories.dart';
import 'auth_repository.dart';
import 'clubs_repository.dart';
import 'fixtures_repository.dart';
import 'mock/mock_repositories.dart';
import 'orders_repository.dart';
import 'scoring_repository.dart';
import 'standings_repository.dart';
import 'store_repository.dart';

// -----------------------------------------------------------------------------
// Core services (overridden at bootstrap with real, initialised instances)
// -----------------------------------------------------------------------------

/// Device connectivity, exposed as a stream for the UI.
final connectivityStatusProvider = StreamProvider<bool>(
  (ref) => ref.watch(connectivityServiceProvider).onStatusChange,
);

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

final localDatabaseProvider = Provider<LocalDatabase>(
  (ref) => MemoryLocalDatabase(),
);

final sessionStoreProvider = Provider<SessionStore>(
  (ref) => InMemorySessionStore(),
);

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityPlusService(),
);

/// Exposed so the app can flip failure modes in preview builds.
final mockBackendProvider = Provider<MockBackend>((ref) => MockBackend());

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final store = ref.watch(sessionStoreProvider);
  // NOTE: no `onUnauthorized` callback here — wiring it to the session provider
  // would create a provider cycle (session → auth repo → api client). A 401 is
  // instead surfaced as `AppErrorKind.unauthorized` and handled by the UI.
  return ApiClient(config: config, accessToken: store.accessToken);
});

final apiServiceProvider = Provider<ApiService>(
  (ref) => ApiService(client: ref.watch(apiClientProvider)),
);

// -----------------------------------------------------------------------------
// Repositories — mock or production, selected by configuration
// -----------------------------------------------------------------------------

bool _useMock(Ref ref) => ref.watch(appConfigProvider).useMockBackend;

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (_useMock(ref)) {
    return MockAuthRepository(
      storage: ref.watch(sessionStoreProvider),
      backend: ref.watch(mockBackendProvider),
    );
  }
  return ApiAuthRepository(
    client: ref.watch(apiClientProvider),
    store: ref.watch(sessionStoreProvider),
  );
});

final fixturesRepositoryProvider = Provider<FixturesRepository>((ref) {
  if (_useMock(ref)) {
    return MockFixturesRepository(
      database: ref.watch(localDatabaseProvider),
      backend: ref.watch(mockBackendProvider),
    );
  }
  return ApiFixturesRepository(
    client: ref.watch(apiClientProvider),
    db: ref.watch(localDatabaseProvider),
  );
});

final standingsRepositoryProvider = Provider<StandingsRepository>((ref) {
  if (_useMock(ref)) {
    return MockStandingsRepository(
      database: ref.watch(localDatabaseProvider),
      backend: ref.watch(mockBackendProvider),
    );
  }
  return ApiStandingsRepository(
    client: ref.watch(apiClientProvider),
    db: ref.watch(localDatabaseProvider),
  );
});

final clubsRepositoryProvider = Provider<ClubsRepository>((ref) {
  if (_useMock(ref)) {
    return MockClubsRepository(
      database: ref.watch(localDatabaseProvider),
      backend: ref.watch(mockBackendProvider),
    );
  }
  return ApiClubsRepository(
    client: ref.watch(apiClientProvider),
    db: ref.watch(localDatabaseProvider),
  );
});

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  if (_useMock(ref)) {
    return MockStoreRepository(
      database: ref.watch(localDatabaseProvider),
      backend: ref.watch(mockBackendProvider),
    );
  }
  return ApiStoreRepository(
    client: ref.watch(apiClientProvider),
    db: ref.watch(localDatabaseProvider),
  );
});

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  if (_useMock(ref)) {
    return MockOrdersRepository(backend: ref.watch(mockBackendProvider));
  }
  return ApiOrdersRepository(client: ref.watch(apiClientProvider));
});

final scoringRepositoryProvider = Provider<ScoringRepository>((ref) {
  if (_useMock(ref)) {
    return MockScoringRepository(backend: ref.watch(mockBackendProvider));
  }
  return ApiScoringRepository(client: ref.watch(apiClientProvider));
});

/// All clubs, for roster destination pickers.
final clubsListProvider = FutureProvider((ref) {
  return ref.read(clubsRepositoryProvider).clubs();
});

// -----------------------------------------------------------------------------
// Offline sync
// -----------------------------------------------------------------------------

final syncAdapterProvider = Provider<SyncAdapter>((ref) {
  if (_useMock(ref)) return MockSyncAdapter();
  return ApiSyncAdapter(client: ref.watch(apiClientProvider));
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    database: ref.watch(localDatabaseProvider),
    adapter: ref.watch(syncAdapterProvider),
  );
});

// -----------------------------------------------------------------------------
// Session
// -----------------------------------------------------------------------------

class SessionController extends StateNotifier<AsyncValue<Session?>> {
  SessionController(this._auth) : super(const AsyncValue<Session?>.data(null));

  final AuthRepository _auth;

  /// Resolves any persisted session during bootstrap.
  Future<void> restore() async {
    state = const AsyncValue<Session?>.loading();
    state = await AsyncValue.guard(() => _auth.restoreSession());
  }

  Future<Session> signIn({
    required String email,
    required String password,
  }) async {
    final session = await _auth.signIn(email: email, password: password);
    state = AsyncValue<Session?>.data(session);
    return session;
  }

  /// Clears local credentials and returns to a signed-out state. Used by the
  /// profile screen's sign-out and by the API layer on a 401.
  Future<void> signOut() async {
    await _auth.signOut();
    state = const AsyncValue<Session?>.data(null);
  }

  void clear() => state = const AsyncValue<Session?>.data(null);
}

final sessionProvider =
    StateNotifierProvider<SessionController, AsyncValue<Session?>>(
      (ref) => SessionController(ref.watch(authRepositoryProvider)),
    );

/// Convenience: the signed-in user, or `null`.
final currentUserProvider = Provider(
  (ref) => ref.watch(sessionProvider).value?.user,
);

/// Central capability gate derived from the signed-in user's role.
final permissionsProvider = Provider<AppPermissions>(
  (ref) => AppPermissions.forUser(ref.watch(currentUserProvider)),
);

// -----------------------------------------------------------------------------
// Sync queue state
// -----------------------------------------------------------------------------

class SyncQueueController
    extends StateNotifier<AsyncValue<List<SyncQueueEntry>>> {
  SyncQueueController(this._service)
    : super(const AsyncValue<List<SyncQueueEntry>>.data([]));

  final SyncService _service;

  bool get isSyncing => _service.isSyncing;

  DateTime? get lastSyncedAt => _service.lastSyncedAt;

  Future<void> load() async {
    state = await AsyncValue.guard(() => _service.allActions());
  }

  Future<SyncSummary?> syncNow() async {
    final summary = await _service.syncNow();
    await load();
    return summary;
  }

  Future<SyncSummary?> retryFailed() async {
    final summary = await _service.retryFailed();
    await load();
    return summary;
  }

  /// Queues an offline action and refreshes the list.
  Future<void> enqueue({
    required String actionType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    await _service.enqueue(
      actionType: actionType,
      entityId: entityId,
      payload: payload,
    );
    await load();
  }

  Future<void> remove(String actionId) async {
    await _service.allActions();
    await load();
  }
}

final syncQueueProvider =
    StateNotifierProvider<
      SyncQueueController,
      AsyncValue<List<SyncQueueEntry>>
    >((ref) => SyncQueueController(ref.watch(syncServiceProvider)));
