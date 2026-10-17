import 'dart:convert';

import '../../core/errors/app_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_routes.dart';
import '../../core/storage/local_database.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../models/cart_item.dart';
import '../../models/club.dart';
import '../../models/fixture.dart';
import '../../models/league.dart';
import '../../models/match_event.dart';
import '../../models/order.dart';
import '../../models/player.dart';
import '../../models/product.dart';
import '../../models/receipt.dart';
import '../../models/roster_action.dart';
import '../../models/scoring_action.dart';
import '../../models/session.dart';
import '../../models/standings_row.dart';
import '../../models/user.dart';
import '../auth_repository.dart';
import '../clubs_repository.dart';
import '../fixtures_repository.dart';
import '../orders_repository.dart';
import '../repository_types.dart';
import '../scoring_repository.dart';
import '../standings_repository.dart';
import '../store_repository.dart';

// =============================================================================
// PRODUCTION REPOSITORIES
//
// ⚠️  PENDING BACKEND CONTRACT.
//
// The NaSCon backend does not exist yet, so **every route referenced here is a
// proposal**, listed in `mobile/FRONTEND_BACKEND_CONTRACT.md` as
// "PENDING BACKEND CONTRACT". These classes are genuine integration points —
// they build real requests and parse real responses — but they are not
// connected to a live service and the default build (`USE_MOCK_BACKEND=true`)
// never instantiates them.
//
// Nothing here fabricates success: transport/parse failures surface as
// `AppException`, and read caches fall back only when the network genuinely
// fails.
// =============================================================================

/// Runs [fetch], caching the encoded result and falling back to the cache when
/// the network fails.
Future<Cached<T>> _cached<T>({
  required LocalDatabase database,
  required String bucket,
  required String key,
  required Future<T> Function() fetch,
  required T Function(dynamic json) parse,
  required Object? Function(T value) encode,
  required bool Function(T value) isEmpty,
}) async {
  try {
    final value = await fetch();
    if (!isEmpty(value)) {
      await database.putCache(bucket, key, jsonEncode(encode(value)));
    }
    return Cached(data: value);
  } on AppException catch (error) {
    if (error.kind != AppErrorKind.network &&
        error.kind != AppErrorKind.timeout) {
      rethrow;
    }
    final cached = await database.getCache(bucket, key);
    if (cached == null) rethrow;
    return Cached(
      data: parse(jsonDecode(cached.payload)),
      fromCache: true,
      updatedAt: cached.updatedAt,
    );
  }
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({required ApiClient client, required SessionStore store})
    : _client = client,
      _store = store;

  final ApiClient _client;
  final SessionStore _store;

  @override
  Future<Session> signIn({
    required String email,
    required String password,
  }) async {
    final json = await _client.post(
      ApiRoutes.login,
      body: {'email': email.trim(), 'password': password},
    );
    final session = Session.fromJson(json);
    if (session.accessToken.isEmpty) {
      throw const AppException(
        'The sign-in response was missing an access token.',
        kind: AppErrorKind.server,
      );
    }
    await _store.saveSession(session);
    return session;
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.post(ApiRoutes.logout);
    } on AppException {
      // Local credentials are cleared regardless of the server's answer.
    } finally {
      await _store.clear();
    }
  }

  @override
  Future<Session?> restoreSession() => _store.readSession();

  @override
  Future<User> currentUser() async {
    final json = await _client.getObject(ApiRoutes.me);
    return User.fromJson(json);
  }
}

class ApiFixturesRepository implements FixturesRepository {
  ApiFixturesRepository({required ApiClient client, required LocalDatabase db})
    : _client = client,
      _db = db;

  final ApiClient _client;
  final LocalDatabase _db;

  @override
  Future<Cached<List<League>>> leagues({bool forceRefresh = false}) async {
    final list = await _client.getList(ApiRoutes.leagues);
    return Cached(data: list.map(League.fromJson).toList());
  }

  @override
  Future<Cached<List<Fixture>>> fixtures({
    String? leagueId,
    FixtureFilter filter = FixtureFilter.all,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${leagueId ?? 'all'}::${filter.name}';
    return _cached<List<Fixture>>(
      database: _db,
      bucket: LocalDatabase.fixturesBucket,
      key: cacheKey,
      fetch: () async {
        final list = await _client.getList(
          ApiRoutes.fixtures,
          query: {
            'league_id': ?leagueId,
            'status': filter.name,
          },
        );
        return list.map(Fixture.fromJson).toList();
      },
      parse: (json) => (json as List)
          .whereType<Map>()
          .map((e) => Fixture.fromJson(e.cast<String, dynamic>()))
          .toList(),
      encode: (value) => value.map((f) => f.toJson()).toList(),
      isEmpty: (value) => value.isEmpty,
    );
  }

  @override
  Future<Cached<Fixture>> fixture(
    String matchId, {
    bool forceRefresh = false,
  }) async {
    return _cached<Fixture>(
      database: _db,
      bucket: LocalDatabase.fixturesBucket,
      key: 'detail::$matchId',
      fetch: () async =>
          Fixture.fromJson(await _client.getObject(ApiRoutes.fixture(matchId))),
      parse: (json) => Fixture.fromJson((json as Map).cast<String, dynamic>()),
      encode: (value) => value.toJson(),
      isEmpty: (_) => false,
    );
  }

  @override
  Future<Cached<List<MatchEvent>>> timeline(
    String matchId, {
    bool forceRefresh = false,
  }) async {
    return _cached<List<MatchEvent>>(
      database: _db,
      bucket: LocalDatabase.fixturesBucket,
      key: 'timeline::$matchId',
      fetch: () async {
        final list = await _client.getList(ApiRoutes.matchEvents(matchId));
        return list.map(MatchEvent.fromJson).toList();
      },
      parse: (json) => (json as List)
          .whereType<Map>()
          .map((e) => MatchEvent.fromJson(e.cast<String, dynamic>()))
          .toList(),
      encode: (value) => value.map((e) => e.toJson()).toList(),
      isEmpty: (_) => false,
    );
  }

  @override
  Future<ScoringConfig> scoringConfig(String matchId) async => ScoringConfig.fromJson(
    await _client.getObject(ApiRoutes.matchScoringConfig(matchId)),
  );
}

class ApiStandingsRepository implements StandingsRepository {
  ApiStandingsRepository({required ApiClient client, required LocalDatabase db})
    : _client = client,
      _db = db;

  final ApiClient _client;
  final LocalDatabase _db;

  @override
  Future<Cached<List<League>>> leagues({bool forceRefresh = false}) async {
    final list = await _client.getList(ApiRoutes.leagues);
    return Cached(data: list.map(League.fromJson).toList());
  }

  @override
  Future<Cached<List<StandingsRow>>> standings(
    String? leagueId, {
    bool forceRefresh = false,
  }) async {
    final resolved = leagueId ?? 'default';
    return _cached<List<StandingsRow>>(
      database: _db,
      bucket: LocalDatabase.standingsBucket,
      key: 'table::$resolved',
      fetch: () async {
        final list = await _client.getList(ApiRoutes.standings(resolved));
        return list.map(StandingsRow.fromJson).toList();
      },
      parse: (json) => (json as List)
          .whereType<Map>()
          .map((e) => StandingsRow.fromJson(e.cast<String, dynamic>()))
          .toList(),
      encode: (value) => value.map((row) => row.toJson()).toList(),
      isEmpty: (value) => value.isEmpty,
    );
  }
}

class ApiClubsRepository implements ClubsRepository {
  ApiClubsRepository({required ApiClient client, required LocalDatabase db})
    : _client = client,
      _db = db;

  final ApiClient _client;
  final LocalDatabase _db;

  @override
  Future<List<Club>> clubs({bool forceRefresh = false}) async {
    final list = await _client.getList(ApiRoutes.clubs);
    return list.map(Club.fromJson).toList();
  }

  @override
  Future<Cached<Club>> club(String clubId, {bool forceRefresh = false}) =>
      _cached<Club>(
        database: _db,
        bucket: LocalDatabase.clubsBucket,
        key: 'club::$clubId',
        fetch: () async =>
            Club.fromJson(await _client.getObject(ApiRoutes.club(clubId))),
        parse: (json) => Club.fromJson((json as Map).cast<String, dynamic>()),
        encode: (value) => value.toJson(),
        isEmpty: (_) => false,
      );

  @override
  Future<Cached<List<Player>>> roster(
    String clubId, {
    bool forceRefresh = false,
  }) async {
    return _cached<List<Player>>(
      database: _db,
      bucket: LocalDatabase.clubsBucket,
      key: 'roster::$clubId',
      fetch: () async {
        final list = await _client.getList(ApiRoutes.clubRoster(clubId));
        return list.map(Player.fromJson).toList();
      },
      parse: (json) => (json as List)
          .whereType<Map>()
          .map((e) => Player.fromJson(e.cast<String, dynamic>()))
          .toList(),
      encode: (value) => value.map((p) => p.toJson()).toList(),
      isEmpty: (value) => value.isEmpty,
    );
  }

  @override
  Future<RosterLimits> rosterLimits(String clubId) async {
    final json = await _client.getObject(ApiRoutes.clubRoster(clubId));
    final limits = json['limits'];
    return limits is Map
        ? RosterLimits.fromJson(limits.cast<String, dynamic>())
        : const RosterLimits();
  }

  @override
  Future<Player> applyRosterAction(RosterAction action) async {
    final json = await _client.post(
      ApiRoutes.rosterAction(action.clubId),
      body: action.toPayload(),
      idempotencyKey: action.id,
    );
    return Player.fromJson(json);
  }
}

class ApiStoreRepository implements StoreRepository {
  ApiStoreRepository({required ApiClient client, required LocalDatabase db})
    : _client = client,
      _db = db;

  final ApiClient _client;
  final LocalDatabase _db;

  @override
  Future<Cached<List<Product>>> products({
    String? category,
    String? query,
    bool forceRefresh = false,
  }) async {
    return _cached<List<Product>>(
      database: _db,
      bucket: LocalDatabase.productsBucket,
      key: 'products::${category ?? 'all'}',
      fetch: () async {
        final list = await _client.getList(
          ApiRoutes.products,
          query: {
            'category': ?category,
            'q': ?query,
          },
        );
        return list.map(Product.fromJson).toList();
      },
      parse: (json) => (json as List)
          .whereType<Map>()
          .map((e) => Product.fromJson(e.cast<String, dynamic>()))
          .toList(),
      encode: (value) => value.map((p) => p.toJson()).toList(),
      isEmpty: (_) => false,
    );
  }

  @override
  Future<Cached<Product>> product(String productId) async => Cached(
    data: Product.fromJson(
      await _client.getObject(ApiRoutes.product(productId)),
    ),
  );

  @override
  Future<List<String>> categories() async {
    final list = await _client.getList(ApiRoutes.products);
    final set = <String>{};
    for (final item in list) {
      final category = item['category'];
      if (category is String && category.isNotEmpty) set.add(category);
    }
    return set.toList()..sort();
  }
}

class ApiOrdersRepository implements OrdersRepository {
  ApiOrdersRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  @override
  Future<CheckoutResult> placeOrder({
    required List<CartItem> items,
    required String idempotencyKey,
  }) async {
    final json = await _client.post(
      ApiRoutes.orders,
      body: {'items': items.map((item) => item.toJson()).toList()},
      idempotencyKey: idempotencyKey,
    );
    final order = Order.fromJson(
      (json['order'] as Map?)?.cast<String, dynamic>() ?? json,
    );
    final receiptJson = json['receipt'];
    return CheckoutResult(
      order: order,
      receipt: receiptJson is Map
          ? Receipt.fromJson(receiptJson.cast<String, dynamic>())
          : null,
    );
  }

  @override
  Future<Order> order(String orderId) async =>
      Order.fromJson(await _client.getObject(ApiRoutes.order(orderId)));

  @override
  Future<Receipt> receipt(String orderId) async => Receipt.fromJson(
    await _client.getObject(ApiRoutes.orderReceipt(orderId)),
  );
}

class ApiScoringRepository implements ScoringRepository {
  ApiScoringRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  @override
  Future<List<MatchEvent>> events(String matchId) async {
    final list = await _client.getList(ApiRoutes.matchEvents(matchId));
    return list.map(MatchEvent.fromJson).toList();
  }

  @override
  Future<MatchEvent> submitEvent(ScoringAction action) async {
    final json = await _client.post(
      ApiRoutes.scoringEvents(action.matchId),
      body: action.toPayload(),
      idempotencyKey: action.id,
    );
    return MatchEvent.fromJson(json);
  }

  @override
  Future<MatchEvent> correctEvent({
    required String matchId,
    required String eventId,
    required MatchEventType type,
    int? points,
    String? note,
  }) async {
    final json = await _client.post(
      ApiRoutes.scoringEvents(matchId),
      body: {
        'type': MatchEventType.correction.wire,
        'corrects_event_id': eventId,
        'points': points,
        'note': note,
      },
    );
    return MatchEvent.fromJson(json);
  }
}
