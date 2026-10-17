import '../models/club.dart';
import '../models/player.dart';
import '../models/roster_action.dart';
import 'repository_types.dart';

/// Club profile and squad management.
abstract interface class ClubsRepository {
  /// All clubs — used for roster destination pickers.
  Future<List<Club>> clubs({bool forceRefresh = false});

  Future<Cached<Club>> club(String clubId, {bool forceRefresh = false});

  Future<Cached<List<Player>>> roster(String clubId, {bool forceRefresh = false});

  Future<RosterLimits> rosterLimits(String clubId);

  /// Applies a roster action. Only called by the online path — offline actions
  /// go through the sync queue instead.
  Future<Player> applyRosterAction(RosterAction action);
}
