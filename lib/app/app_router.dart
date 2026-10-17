import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../features/auth/login_screen.dart';
import '../features/club_profile/club_profile_screen.dart';
import '../features/fixtures/fixtures_screen.dart';
import '../features/home/home_screen.dart';
import '../features/match_detail/match_detail_screen.dart';
import '../features/orders/checkout_screen.dart';
import '../features/orders/order_receipt_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/roster/roster_screen.dart';
import '../features/scoring/scoring_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/standings/standings_screen.dart';
import '../features/store/cart_screen.dart';
import '../features/store/product_detail_screen.dart';
import '../features/store/store_screen.dart';
import '../features/sync_status/sync_status_screen.dart';
import '../repositories/repository_providers.dart';

/// Route paths, referenced by screens so navigation never uses magic strings
/// in more than one place.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';

  static const String home = '/home';
  static const String fixtures = '/fixtures';
  static const String standings = '/standings';
  static const String store = '/store';
  static const String profile = '/profile';

  static const String syncStatus = '/sync-status';
  static const String cart = '/cart';
  static const String checkout = '/checkout';

  static String match(String matchId) => '/matches/$matchId';
  static String scoring(String matchId) => '/matches/$matchId/scoring';
  static String club(String clubId) => '/clubs/$clubId';
  static String roster(String clubId) => '/clubs/$clubId/roster';
  static String product(String productId) => '/store/product/$productId';
  static String receipt(String orderId) => '/orders/$orderId/receipt';
}

/// The app router.
///
/// Redirects unauthenticated users to Login and keeps privileged screens behind
/// the permission layer. Hiding a control is not authorisation — the backend
/// must still enforce every rule.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final sessionState = ref.read(sessionProvider);
      final location = state.matchedLocation;
      final atSplash = location == AppRoutes.splash;
      final atLogin = location == AppRoutes.login;

      if (sessionState.isLoading) return atSplash ? null : AppRoutes.splash;

      final session = sessionState.value;
      if (session == null) {
        // Not signed in: the only reachable screen is Login. Splash must not
        // redirect to itself, or the app would never leave the spinner.
        return atLogin ? null : AppRoutes.login;
      }

      if (atSplash || atLogin) return AppRoutes.home;

      final permissions = ref.read(permissionsProvider);
      if (location.endsWith('/roster') && !permissions.canManageRoster) {
        return AppRoutes.home;
      }
      if (location.endsWith('/scoring') && !permissions.canEnterScore) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.fixtures,
                builder: (context, state) => const FixturesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.standings,
                builder: (context, state) => const StandingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.store,
                builder: (context, state) => const StoreScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/matches/:matchId',
        builder: (context, state) =>
            MatchDetailScreen(matchId: state.pathParameters['matchId']!),
        routes: [
          GoRoute(
            path: 'scoring',
            builder: (context, state) =>
                ScoringScreen(matchId: state.pathParameters['matchId']!),
          ),
        ],
      ),
      GoRoute(
        path: '/clubs/:clubId',
        builder: (context, state) =>
            ClubProfileScreen(clubId: state.pathParameters['clubId']!),
        routes: [
          GoRoute(
            path: 'roster',
            builder: (context, state) =>
                RosterScreen(clubId: state.pathParameters['clubId']!),
          ),
        ],
      ),
      GoRoute(
        path: '/store/product/:productId',
        builder: (context, state) => ProductDetailScreen(
          productId: state.pathParameters['productId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.cart,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/orders/:orderId/receipt',
        builder: (context, state) =>
            OrderReceiptScreen(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
        path: AppRoutes.syncStatus,
        builder: (context, state) => const SyncStatusScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('That page does not exist.'),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Back to home'),
            ),
          ],
        ),
      ),
    ),
  );
});

class _AppShell extends StatelessWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = <(String, IconData, IconData)>[
    ('Home', Icons.home_outlined, Icons.home_rounded),
    ('Fixtures', Icons.sports_soccer_outlined, Icons.sports_soccer_rounded),
    ('Standings', Icons.leaderboard_outlined, Icons.leaderboard_rounded),
    ('Store', Icons.storefront_outlined, Icons.storefront_rounded),
    ('Profile', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  void _go(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _go,
              labelType: NavigationRailLabelType.all,
              backgroundColor: theme.cardColor,
              destinations: [
                for (final (label, icon, selectedIcon) in _destinations)
                  NavigationRailDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selectedIcon),
                    label: Text(label),
                  ),
              ],
            ),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: CurvedNavigationBar(
        index: navigationShell.currentIndex,
        height: 62,
        color: scheme.primary,
        buttonBackgroundColor: scheme.primary,
        backgroundColor: theme.scaffoldBackgroundColor,
        animationCurve: Curves.easeOutCubic,
        animationDuration: const Duration(milliseconds: 300),
        onTap: _go,
        items: [
          // The bar itself highlights the active destination, so a single icon
          // set is enough here.
          for (final (_, icon, _) in _destinations)
            Icon(icon, size: 26, color: Colors.white),
        ],
      ),
    );
  }
}
