import '../models/league.dart';
import '../models/standings_row.dart';
import 'repository_types.dart';

/// League tables.
abstract interface class StandingsRepository {
  Future<Cached<List<League>>> leagues({bool forceRefresh = false});

  /// [leagueId] `null` means "the default/only league".
  Future<Cached<List<StandingsRow>>> standings(
    String? leagueId, {
    bool forceRefresh = false,
  });
}
