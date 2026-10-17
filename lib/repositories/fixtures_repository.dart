import '../models/fixture.dart';
import '../models/league.dart';
import '../models/match_event.dart';
import 'repository_types.dart';

/// Fixtures, their timelines, and the scoring configuration for a match.
abstract interface class FixturesRepository {
  Future<Cached<List<League>>> leagues({bool forceRefresh = false});

  /// When the network fails and a cache exists, returns the cache with
  /// [Cached.fromCache] set — it never silently pretends cached data is live.
  Future<Cached<List<Fixture>>> fixtures({
    String? leagueId,
    FixtureFilter filter = FixtureFilter.all,
    bool forceRefresh = false,
  });

  Future<Cached<Fixture>> fixture(String matchId, {bool forceRefresh = false});

  Future<Cached<List<MatchEvent>>> timeline(
    String matchId, {
    bool forceRefresh = false,
  });

  Future<ScoringConfig> scoringConfig(String matchId);
}
