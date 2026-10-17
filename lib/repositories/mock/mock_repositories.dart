import 'dart:convert';

import '../../core/errors/app_exception.dart';
import '../../core/storage/local_database.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../models/cart_item.dart';
import '../../models/cart_totals.dart';
import '../../models/club.dart';
import '../../models/fixture.dart';
import '../../models/league.dart';
import '../../models/match_event.dart';
import '../../models/order.dart';
import '../../models/order_item.dart';
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
import 'mock_data.dart';

/// Controls the fake backend's failure modes so offline/decline/out-of-stock
/// paths are reachable in the app and deterministic in tests.
class MockBackend {
  MockBackend({this.latency = const Duration(milliseconds: 150)});

  Duration latency;

  /// When `true`, every network call fails and repositories fall back to cache.
  bool offline = false;

  /// Causes checkout to return a declined payment.
  bool declinePayments = false;

  /// Forces specific products out of stock at checkout.
  final Set<String> outOfStockProductIds = {};

  /// Returns an empty fixture list (to exercise the empty state).
  bool fixturesEmpty = false;

  Future<void> tick() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
  }

  void requireOnline() {
    if (offline) {
      throw const AppException(
        'Unable to reach the server.',
        kind: AppErrorKind.network,
      );
    }
  }
}

T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}

String _encodeList<T>(List<T> items, Map<String, dynamic> Function(T) toJson) =>
    jsonEncode(items.map(toJson).toList());

// -----------------------------------------------------------------------------
// Auth
// -----------------------------------------------------------------------------

class MockAuthRepository implements AuthRepository {
  MockAuthRepository({
    required SessionStore storage,
    required MockBackend backend,
  }) : _storage = storage,
       _backend = backend;

  final SessionStore _storage;
  final MockBackend _backend;

  @override
  Future<Session> signIn({
    required String email,
    required String password,
  }) async {
    await _backend.tick();
    _backend.requireOnline();

    final account = _firstWhereOrNull(
      MockData.demoAccounts,
      (a) => a.email.toLowerCase() == email.trim().toLowerCase(),
    );

    if (account == null || account.password != password) {
      throw const AppException(
        'Incorrect email or password.',
        kind: AppErrorKind.invalidCredentials,
        statusCode: 401,
      );
    }

    final session = Session(
      accessToken: 'mock.${account.user.role.wire}.${account.user.id}',
      refreshToken: 'mock-refresh-token',
      user: account.user,
      expiresAt: DateTime.now().add(const Duration(hours: 12)),
    );
    await _storage.saveSession(session);
    return session;
  }

  @override
  Future<void> signOut() => _storage.clear();

  @override
  Future<Session?> restoreSession() => _storage.readSession();

  @override
  Future<User> currentUser() async {
    final session = await _storage.readSession();
    if (session == null) {
      throw const AppException(
        'No active session.',
        kind: AppErrorKind.unauthorized,
        statusCode: 401,
      );
    }
    return session.user;
  }
}

// -----------------------------------------------------------------------------
// Fixtures
// -----------------------------------------------------------------------------

class MockFixturesRepository implements FixturesRepository {
  MockFixturesRepository({
    required LocalDatabase database,
    required MockBackend backend,
  }) : _db = database,
       _backend = backend;

  final LocalDatabase _db;
  final MockBackend _backend;

  @override
  Future<Cached<List<League>>> leagues({bool forceRefresh = false}) async {
    await _backend.tick();
    return Cached(data: MockData.leagues);
  }

  @override
  Future<Cached<List<Fixture>>> fixtures({
    String? leagueId,
    FixtureFilter filter = FixtureFilter.all,
    bool forceRefresh = false,
  }) async {
    await _backend.tick();
    final cacheKey = '${leagueId ?? 'all'}::${filter.name}';

    if (_backend.offline) {
      final cached = await _db.getCache(LocalDatabase.fixturesBucket, cacheKey);
      if (cached == null) {
        throw const AppException(
          'You are offline and no fixtures have been cached yet.',
          kind: AppErrorKind.network,
        );
      }
      return Cached(
        data: CachedPayload.decodeList(cached.payload)
            .map(Fixture.fromJson)
            .toList(),
        fromCache: true,
        updatedAt: cached.updatedAt,
      );
    }

    final all = _backend.fixturesEmpty ? <Fixture>[] : MockData.fixtures;
    final filtered = all.where((fixture) {
      if (leagueId != null && fixture.leagueId != leagueId) return false;
      return switch (filter) {
        FixtureFilter.all => true,
        FixtureFilter.upcoming => fixture.isUpcoming,
        FixtureFilter.live => fixture.isLive,
        FixtureFilter.completed => fixture.isCompleted,
      };
    }).toList();

    await _db.putCache(
      LocalDatabase.fixturesBucket,
      cacheKey,
      _encodeList(filtered, (f) => f.toJson()),
    );
    return Cached(data: filtered);
  }

  @override
  Future<Cached<Fixture>> fixture(
    String matchId, {
    bool forceRefresh = false,
  }) async {
    await _backend.tick();
    final cacheKey = 'detail::$matchId';

    if (_backend.offline) {
      final cached = await _db.getCache(LocalDatabase.fixturesBucket, cacheKey);
      if (cached == null) {
        throw const AppException(
          'You are offline and this match has not been cached.',
          kind: AppErrorKind.network,
        );
      }
      final json = cached.decodeObject();
      if (json == null) {
        throw const AppException(
          'The cached match is unreadable.',
          kind: AppErrorKind.server,
        );
      }
      return Cached(
        data: Fixture.fromJson(json),
        fromCache: true,
        updatedAt: cached.updatedAt,
      );
    }

    final match = _firstWhereOrNull(MockData.fixtures, (f) => f.id == matchId);
    if (match == null) {
      throw const AppException(
        'That match could not be found.',
        kind: AppErrorKind.notFound,
        statusCode: 404,
      );
    }
    await _db.putCache(
      LocalDatabase.fixturesBucket,
      cacheKey,
      jsonEncode(match.toJson()),
    );
    return Cached(data: match);
  }

  @override
  Future<Cached<List<MatchEvent>>> timeline(
    String matchId, {
    bool forceRefresh = false,
  }) async {
    await _backend.tick();
    final cacheKey = 'timeline::$matchId';

    if (_backend.offline) {
      final cached = await _db.getCache(LocalDatabase.fixturesBucket, cacheKey);
      if (cached != null) {
        return Cached(
          data: CachedPayload.decodeList(cached.payload)
              .map(MatchEvent.fromJson)
              .toList(),
          fromCache: true,
          updatedAt: cached.updatedAt,
        );
      }
      return const Cached(data: []);
    }

    final events = MockData.events.where((e) => e.matchId == matchId).toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    await _db.putCache(
      LocalDatabase.fixturesBucket,
      cacheKey,
      _encodeList(events, (e) => e.toJson()),
    );
    return Cached(data: events);
  }

  @override
  Future<ScoringConfig> scoringConfig(String matchId) async {
    await _backend.tick();
    final match = _firstWhereOrNull(MockData.fixtures, (f) => f.id == matchId);
    final league = match?.leagueId == null
        ? null
        : _firstWhereOrNull(MockData.leagues, (l) => l.id == match!.leagueId);

    if (league?.sport == 'cricket') {
      return ScoringConfig(
        matchId: matchId,
        sport: 'cricket',
        allowsCorrection: true,
        periods: const ['Innings 1', 'Innings 2'],
        eventTypes: const [
          ScoringEventTypeConfig(
            type: MatchEventType.point,
            label: 'Run',
            defaultPoints: 1,
            requiresPlayer: true,
          ),
          ScoringEventTypeConfig(
            type: MatchEventType.wicket,
            label: 'Wicket',
            requiresPlayer: true,
            requiresPeriod: true,
          ),
          ScoringEventTypeConfig(
            type: MatchEventType.other,
            label: 'Boundary (4)',
            defaultPoints: 4,
            requiresPlayer: true,
          ),
        ],
      );
    }

    return ScoringConfig(
      matchId: matchId,
      sport: 'football',
      allowsCorrection: true,
      periods: const ['1H', '2H', 'ET'],
      eventTypes: const [
        ScoringEventTypeConfig(
          type: MatchEventType.goal,
          defaultPoints: 1,
          requiresPlayer: true,
        ),
        ScoringEventTypeConfig(
          type: MatchEventType.card,
          label: 'Card',
          requiresPlayer: true,
        ),
        ScoringEventTypeConfig(
          type: MatchEventType.substitution,
          requiresPlayer: true,
        ),
        ScoringEventTypeConfig(type: MatchEventType.periodEnd),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Standings
// -----------------------------------------------------------------------------

class MockStandingsRepository implements StandingsRepository {
  MockStandingsRepository({
    required LocalDatabase database,
    required MockBackend backend,
  }) : _db = database,
       _backend = backend;

  final LocalDatabase _db;
  final MockBackend _backend;

  @override
  Future<Cached<List<League>>> leagues({bool forceRefresh = false}) async {
    await _backend.tick();
    return const Cached(data: MockData.leagues);
  }

  @override
  Future<Cached<List<StandingsRow>>> standings(
    String? leagueId, {
    bool forceRefresh = false,
  }) async {
    await _backend.tick();
    final resolved = leagueId ?? 'lg_football';
    final cacheKey = 'table::$resolved';

    if (_backend.offline) {
      final cached = await _db.getCache(LocalDatabase.standingsBucket, cacheKey);
      if (cached == null) {
        throw const AppException(
          'You are offline and this table has not been cached.',
          kind: AppErrorKind.network,
        );
      }
      return Cached(
        data: CachedPayload.decodeList(cached.payload)
            .map(StandingsRow.fromJson)
            .toList(),
        fromCache: true,
        updatedAt: cached.updatedAt,
      );
    }

    final rows = resolved == 'lg_cricket'
        ? MockData.cricketStandings
        : MockData.footballStandings;
    await _db.putCache(
      LocalDatabase.standingsBucket,
      cacheKey,
      _encodeList(rows, (r) => r.toJson()),
    );
    return Cached(data: rows);
  }
}

// -----------------------------------------------------------------------------
// Clubs & roster
// -----------------------------------------------------------------------------

class MockClubsRepository implements ClubsRepository {
  MockClubsRepository({
    required LocalDatabase database,
    required MockBackend backend,
  }) : _db = database,
       _backend = backend,
       _players = [...MockData.players];

  final LocalDatabase _db;
  final MockBackend _backend;
  final List<Player> _players;

  @override
  Future<List<Club>> clubs({bool forceRefresh = false}) async {
    await _backend.tick();
    _backend.requireOnline();
    return MockData.clubs;
  }

  @override
  Future<Cached<Club>> club(String clubId, {bool forceRefresh = false}) async {
    await _backend.tick();
    final cacheKey = 'club::$clubId';

    if (_backend.offline) {
      final cached = await _db.getCache(LocalDatabase.clubsBucket, cacheKey);
      final json = cached?.decodeObject();
      if (json == null) {
        throw const AppException(
          'You are offline and this club has not been cached.',
          kind: AppErrorKind.network,
        );
      }
      return Cached(
        data: Club.fromJson(json),
        fromCache: true,
        updatedAt: cached!.updatedAt,
      );
    }

    final club = _firstWhereOrNull(MockData.clubs, (c) => c.id == clubId);
    if (club == null) {
      throw const AppException(
        'That club could not be found.',
        kind: AppErrorKind.notFound,
        statusCode: 404,
      );
    }
    await _db.putCache(
      LocalDatabase.clubsBucket,
      cacheKey,
      jsonEncode(club.toJson()),
    );
    return Cached(data: club);
  }

  @override
  Future<Cached<List<Player>>> roster(
    String clubId, {
    bool forceRefresh = false,
  }) async {
    await _backend.tick();
    final cacheKey = 'roster::$clubId';

    if (_backend.offline) {
      final cached = await _db.getCache(LocalDatabase.clubsBucket, cacheKey);
      if (cached == null) {
        throw const AppException(
          'You are offline and this squad has not been cached.',
          kind: AppErrorKind.network,
        );
      }
      return Cached(
        data: CachedPayload.decodeList(cached.payload)
            .map(Player.fromJson)
            .toList(),
        fromCache: true,
        updatedAt: cached.updatedAt,
      );
    }

    final squad = _players.where((p) => p.clubId == clubId).toList();
    await _db.putCache(
      LocalDatabase.clubsBucket,
      cacheKey,
      _encodeList(squad, (p) => p.toJson()),
    );
    return Cached(data: squad);
  }

  @override
  Future<RosterLimits> rosterLimits(String clubId) async {
    await _backend.tick();
    final club = _firstWhereOrNull(MockData.clubs, (c) => c.id == clubId);
    return RosterLimits(
      squadSize: _players.where((p) => p.clubId == clubId).length,
      maxSquadSize: club?.leagueId == 'lg_cricket' ? 15 : 22,
      transferWindowOpen: true,
      positionRequirements: const {
        'Goalkeeper': 2,
        'Defender': 6,
        'Midfielder': 6,
        'Forward': 4,
      },
    );
  }

  @override
  Future<Player> applyRosterAction(RosterAction action) async {
    await _backend.tick();
    _backend.requireOnline();

    final index = _players.indexWhere((p) => p.id == action.playerId);
    if (index < 0) {
      throw const AppException(
        'That player is not in the selected squad.',
        kind: AppErrorKind.validation,
        statusCode: 422,
      );
    }

    final current = _players[index];
    final updated = switch (action.type) {
      RosterActionType.add => current.copyWith(clubId: action.clubId),
      RosterActionType.transfer => current.copyWith(clubId: action.destinationClubId ?? action.clubId),
      RosterActionType.loan => current.copyWith(
        loanClubId: action.destinationClubId,
      ),
      RosterActionType.release => current.copyWith(
        clubId: 'released',
        loanClubId: null,
      ),
    };
    _players[index] = updated;
    return updated;
  }
}

extension on Player {
  Player copyWith({String? clubId, String? loanClubId}) => Player(
    id: id,
    name: name,
    clubId: clubId ?? this.clubId,
    position: position,
    jerseyNumber: jerseyNumber,
    status: status,
    loanClubId: loanClubId ?? this.loanClubId,
    avatarUrl: avatarUrl,
  );
}

// -----------------------------------------------------------------------------
// Store
// -----------------------------------------------------------------------------

class MockStoreRepository implements StoreRepository {
  MockStoreRepository({
    required LocalDatabase database,
    required MockBackend backend,
  }) : _db = database,
       _backend = backend;

  final LocalDatabase _db;
  final MockBackend _backend;

  @override
  Future<Cached<List<Product>>> products({
    String? category,
    String? query,
    bool forceRefresh = false,
  }) async {
    await _backend.tick();
    final cacheKey = 'products::${category ?? 'all'}';

    if (_backend.offline) {
      final cached = await _db.getCache(LocalDatabase.productsBucket, cacheKey);
      if (cached == null) {
        throw const AppException(
          'You are offline and the store has not been cached.',
          kind: AppErrorKind.network,
        );
      }
      return Cached(
        data: CachedPayload.decodeList(cached.payload)
            .map(Product.fromJson)
            .toList(),
        fromCache: true,
        updatedAt: cached.updatedAt,
      );
    }

    final term = query?.trim().toLowerCase() ?? '';
    final results = MockData.products.where((product) {
      if (category != null &&
          category.isNotEmpty &&
          product.category != category) {
        return false;
      }
      if (term.isNotEmpty && !product.name.toLowerCase().contains(term)) {
        return false;
      }
      return true;
    }).toList();

    await _db.putCache(
      LocalDatabase.productsBucket,
      cacheKey,
      _encodeList(results, (p) => p.toJson()),
    );
    return Cached(data: results);
  }

  @override
  Future<Cached<Product>> product(String productId) async {
    await _backend.tick();
    final product = _firstWhereOrNull(
      MockData.products,
      (p) => p.id == productId,
    );
    if (product == null) {
      throw const AppException(
        'That product could not be found.',
        kind: AppErrorKind.notFound,
        statusCode: 404,
      );
    }
    return Cached(data: product);
  }

  @override
  Future<List<String>> categories() async {
    await _backend.tick();
    final set = <String>{};
    for (final product in MockData.products) {
      final category = product.category;
      if (category != null && category.isNotEmpty) set.add(category);
    }
    return set.toList()..sort();
  }
}

// -----------------------------------------------------------------------------
// Orders
// -----------------------------------------------------------------------------

class MockOrdersRepository implements OrdersRepository {
  MockOrdersRepository({required MockBackend backend}) : _backend = backend;

  final MockBackend _backend;
  final Map<String, Order> _orders = {};

  @override
  Future<CheckoutResult> placeOrder({
    required List<CartItem> items,
    required String idempotencyKey,
  }) async {
    await _backend.tick();
    _backend.requireOnline();

    if (items.isEmpty) {
      throw const AppException(
        'Your cart is empty.',
        kind: AppErrorKind.validation,
        statusCode: 422,
      );
    }

    // Idempotency: a repeated submission of the same attempt returns the
    // original order rather than creating a duplicate.
    final existing = _orders[idempotencyKey];
    if (existing != null) {
      return CheckoutResult(order: existing);
    }

    for (final item in items) {
      final stock = item.availableStock;
      if (_backend.outOfStockProductIds.contains(item.productId) ||
          (stock != null && item.quantity > stock)) {
        throw AppException(
          '${item.productName} is no longer available in that quantity.',
          kind: AppErrorKind.conflict,
          statusCode: 409,
        );
      }
    }

    if (_backend.declinePayments) {
      throw const AppException(
        'Your payment was declined by the provider. No order was created.',
        kind: AppErrorKind.validation,
        statusCode: 422,
      );
    }

    final totals = CartTotals.fromItems(items, taxRate: 0.05);
    final now = DateTime.now();
    final orderId =
        'ord_${now.millisecondsSinceEpoch.toRadixString(36)}${items.length}';

    final order = Order(
      id: orderId,
      items: items
          .map(
            (item) => OrderItem(
              productId: item.productId,
              productName: item.productName,
              unitPrice: item.unitPrice,
              quantity: item.quantity,
              variantId: item.variantId,
              variantName: item.variantName,
              currency: item.currency,
              imageUrl: item.imageUrl,
            ),
          )
          .toList(),
      subtotal: totals.subtotal,
      tax: totals.tax,
      shipping: totals.shipping,
      discount: totals.discount,
      total: totals.total,
      currency: totals.currency,
      status: OrderStatus.confirmed,
      paymentStatus: PaymentStatus.paid,
      paymentReference: 'MOCKPAY-$orderId',
      createdAt: now,
    );

    _orders[idempotencyKey] = order;

    return CheckoutResult(
      order: order,
      receipt: Receipt(
        orderId: order.id,
        receiptNumber: 'RCPT-${order.id.toUpperCase()}',
        issuedAt: now,
        total: order.total,
        currency: order.currency,
      ),
    );
  }

  @override
  Future<Order> order(String orderId) async {
    await _backend.tick();
    final order = _firstWhereOrNull(_orders.values, (o) => o.id == orderId);
    if (order == null) {
      throw const AppException(
        'That order could not be found.',
        kind: AppErrorKind.notFound,
        statusCode: 404,
      );
    }
    return order;
  }

  @override
  Future<Receipt> receipt(String orderId) async {
    final order = await this.order(orderId);
    return Receipt(
      orderId: order.id,
      receiptNumber: 'RCPT-${order.id.toUpperCase()}',
      issuedAt: order.createdAt ?? DateTime.now(),
      total: order.total,
      currency: order.currency,
    );
  }
}

// -----------------------------------------------------------------------------
// Scoring
// -----------------------------------------------------------------------------

class MockScoringRepository implements ScoringRepository {
  MockScoringRepository({required MockBackend backend})
    : _backend = backend,
      _events = [...MockData.events];

  final MockBackend _backend;
  final List<MatchEvent> _events;
  int _sequence = 100;

  @override
  Future<List<MatchEvent>> events(String matchId) async {
    await _backend.tick();
    final events = _events.where((e) => e.matchId == matchId).toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    return events;
  }

  @override
  Future<MatchEvent> submitEvent(ScoringAction action) async {
    await _backend.tick();
    _backend.requireOnline();
    return _append(action, EventStatus.confirmed);
  }

  @override
  Future<MatchEvent> correctEvent({
    required String matchId,
    required String eventId,
    required MatchEventType type,
    int? points,
    String? note,
  }) async {
    await _backend.tick();
    _backend.requireOnline();

    final target = _firstWhereOrNull(_events, (e) => e.id == eventId);
    if (target == null) {
      throw const AppException(
        'That event could not be found.',
        kind: AppErrorKind.notFound,
        statusCode: 404,
      );
    }

    // Corrections are compensating events — the original is never edited.
    return _append(
      ScoringAction(
        id: 'correction_${DateTime.now().microsecondsSinceEpoch}',
        matchId: matchId,
        type: MatchEventType.correction,
        teamId: target.teamId ?? '',
        teamName: target.teamName,
        playerName: target.playerName,
        points: points,
        note: note ?? 'Correction for ${target.type.label}',
      ),
      EventStatus.corrected,
    );
  }

  MatchEvent _append(ScoringAction action, EventStatus status) {
    final event = MatchEvent(
      id: 'ev_${_sequence++}',
      matchId: action.matchId,
      type: action.type,
      sequence: _sequence,
      teamId: action.teamId,
      teamName: action.teamName,
      playerId: action.playerId,
      playerName: action.playerName,
      points: action.points ?? (action.type == MatchEventType.goal ? 1 : null),
      minute: action.minute,
      period: action.period,
      description: action.note,
      status: status,
      createdAt: DateTime.now(),
      clientActionId: action.id,
    );
    _events.add(event);
    return event;
  }
}
