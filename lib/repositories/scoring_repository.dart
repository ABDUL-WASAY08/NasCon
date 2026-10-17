import '../models/match_event.dart';
import '../models/scoring_action.dart';

/// Scoring entry for a match.
///
/// Live push (WebSocket/SSE) is intentionally **not** implemented: the backend
/// has not specified a real-time contract, and the app must not simulate live
/// updates. A subscription boundary is documented in the backend contract.
abstract interface class ScoringRepository {
  Future<List<MatchEvent>> events(String matchId);

  /// Submits a scoring event online. Offline submissions go through the sync
  /// queue instead.
  Future<MatchEvent> submitEvent(ScoringAction action);

  /// Compensating correction of a previously committed event.
  Future<MatchEvent> correctEvent({
    required String matchId,
    required String eventId,
    required MatchEventType type,
    int? points,
    String? note,
  });
}
