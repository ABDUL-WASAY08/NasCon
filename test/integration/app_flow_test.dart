import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nescom/app/app_router.dart';
import 'package:nescom/core/theme/app_theme.dart';
import 'package:nescom/features/auth/login_screen.dart';
import 'package:nescom/features/fixtures/widgets/match_card.dart';

import '../helpers/test_harness.dart';

/// End-to-end flows against the real router and the mock repositories.
///
/// These exercise navigation and session state as the app actually wires them,
/// with no network and no platform channels.
void main() {
  Future<void> pumpApp(WidgetTester tester, ProviderContainer container) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: container.read(routerProvider),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('startup → login → home → fixtures → match detail', (
    tester,
  ) async {
    final container = testContainer();
    await pumpApp(tester, container);

    // Unauthenticated startup lands on Login.
    expect(find.byType(LoginScreen), findsOneWidget);

    // Sign in with a documented demo account.
    await tester.tap(find.text('Club Manager'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // Redirected to Home.
    expect(find.text('Jump to'), findsOneWidget);

    // Navigate to Fixtures through the bottom navigation bar.
    await tester.tap(find.byIcon(Icons.sports_soccer_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(MatchCard), findsWidgets);

    // Open the first match.
    await tester.tap(find.byType(MatchCard).first);
    await tester.pumpAndSettle();
    expect(find.text('Match Details'), findsOneWidget);
  });

  testWidgets('signing out returns to login', (tester) async {
    final container = testContainer();
    await pumpApp(tester, container);

    await tester.tap(find.text('Club Manager'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    container.read(routerProvider).go('/profile');
    await tester.pumpAndSettle();

    expect(find.text('Sign out'), findsOneWidget);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    // Confirm the destructive dialog.
    await tester.tap(find.text('Sign out').last);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('an invalid sign-in shows an error and stays on login', (
    tester,
  ) async {
    final container = testContainer();
    await pumpApp(tester, container);

    await tester.enterText(
      find.byType(TextFormField).first,
      'nobody@nascon.example',
    );
    await tester.enterText(find.byType(TextFormField).last, 'WrongPass123');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
