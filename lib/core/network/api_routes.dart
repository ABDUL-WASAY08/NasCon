/// Centralised API route table.
///
/// **Every route below is `PENDING BACKEND CONTRACT`.** No endpoint has been
/// specified by the NaSCon backend team yet, so these paths are a proposal, not
/// a verified contract — see `mobile/FRONTEND_BACKEND_CONTRACT.md`. The default
/// build runs against mock repositories and never calls these.
abstract final class ApiRoutes {
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  static const String leagues = '/leagues';
  static String standings(String leagueId) => '/leagues/$leagueId/standings';

  static const String fixtures = '/fixtures';
  static String fixture(String matchId) => '/fixtures/$matchId';
  static String matchEvents(String matchId) => '/fixtures/$matchId/events';
  static String scoringEvents(String matchId) =>
      '/fixtures/$matchId/scoring-events';
  static String matchScoringConfig(String matchId) =>
      '/fixtures/$matchId/scoring-config';

  static const String clubs = '/clubs';
  static String club(String clubId) => '/clubs/$clubId';
  static String clubRoster(String clubId) => '/clubs/$clubId/roster';
  static String rosterAction(String clubId) => '/clubs/$clubId/roster/actions';

  static const String products = '/products';
  static String product(String productId) => '/products/$productId';

  static const String orders = '/orders';
  static String order(String orderId) => '/orders/$orderId';
  static String orderReceipt(String orderId) => '/orders/$orderId/receipt';

  /// Batch endpoint for draining the offline queue.
  static const String syncBatch = '/sync/batch';
}
