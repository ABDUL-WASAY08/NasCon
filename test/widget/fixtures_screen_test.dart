import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nescom/core/errors/error_mapper.dart';
import 'package:nescom/features/fixtures/fixtures_screen.dart';
import 'package:nescom/features/fixtures/widgets/match_card.dart';
import 'package:nescom/repositories/mock/mock_repositories.dart';

import '../helpers/test_harness.dart';

/// A tall surface so every fixture card is built (the list is lazy).
void _tallPhone(WidgetTester tester) =>
    setTestViewport(tester, height: 2600);

void main() {
  testWidgets('fixtures list renders every match by default', (tester) async {
    final container = testContainer();
    _tallPhone(tester);
    await tester.pumpWidget(wrapScreen(const FixturesScreen(), container));
    await tester.pumpAndSettle();

    expect(find.byType(MatchCard), findsNWidgets(10));
  });

  testWidgets('the Live filter actually changes the list', (tester) async {
    final container = testContainer();
    _tallPhone(tester);
    await tester.pumpWidget(wrapScreen(const FixturesScreen(), container));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Live'));
    await tester.pumpAndSettle();

    expect(find.byType(MatchCard), findsOneWidget);
    expect(find.text('Live'), findsWidgets);
  });

  testWidgets('the Upcoming filter excludes live and completed matches', (
    tester,
  ) async {
    final container = testContainer();
    _tallPhone(tester);
    await tester.pumpWidget(wrapScreen(const FixturesScreen(), container));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Upcoming'));
    await tester.pumpAndSettle();

    // 4 scheduled + 1 postponed.
    expect(find.byType(MatchCard), findsNWidgets(5));
  });

  testWidgets('an empty result shows the empty state, not a blank list', (
    tester,
  ) async {
    final backend = MockBackend(latency: Duration.zero)..fixturesEmpty = true;
    final container = testContainer(backend: backend);

    await tester.pumpWidget(wrapScreen(const FixturesScreen(), container));
    await tester.pumpAndSettle();

    expect(find.text('No fixtures'), findsOneWidget);
    expect(find.byType(MatchCard), findsNothing);
  });

  testWidgets('a network failure with no cache shows a retry affordance', (
    tester,
  ) async {
    final backend = MockBackend(latency: Duration.zero)..offline = true;
    final container = testContainer(backend: backend);

    await tester.pumpWidget(wrapScreen(const FixturesScreen(), container));
    await tester.pumpAndSettle();

    // The repository's network failure is mapped to the user-facing message.
    expect(find.text(ErrorMapper.offlineMessage), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
