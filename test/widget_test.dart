import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nescom/core/theme/app_theme.dart';
import 'package:nescom/core/widgets/widgets.dart';
import 'package:nescom/features/auth/presentation/screens/auth_screen.dart';
import 'package:nescom/features/auth/presentation/screens/splash_screen.dart';
import 'package:nescom/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:nescom/main.dart';

/// Advances the clock in fixed steps (avoids `pumpAndSettle`, which would wait
/// forever on the splash's repeating pulse/wave controllers).
Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  const step = Duration(milliseconds: 100);
  var elapsed = Duration.zero;
  while (elapsed < duration) {
    await tester.pump(step);
    elapsed += step;
  }
}

Widget _host(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

Finder _fieldWithLabel(String label) => find.descendant(
  of: find.widgetWithText(CustomTextField, label),
  matching: find.byType(TextFormField),
);

void main() {
  testWidgets('splash hands off to the auth screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: NescomApp()));

    expect(find.byType(SplashScreen), findsOneWidget);

    await _pumpFor(tester, const Duration(seconds: 3));
    await _pumpFor(tester, const Duration(milliseconds: 700));

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.text('Welcome Back!'), findsOneWidget);
  });

  testWidgets('auth switches between Login and Sign Up tabs', (tester) async {
    await tester.pumpWidget(_host(AuthScreen(onAuthenticated: () {})));

    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Create Account'), findsNothing);

    await tester.tap(find.text('Sign Up').first);
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsWidgets);
    expect(find.text('Welcome Back!'), findsNothing);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.text('I agree to the Terms & Conditions'), findsOneWidget);
  });

  testWidgets('valid credentials open the dashboard', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(const AuthScreen()));
    // Let the entrance (animate_do) settle before interacting.
    await _pumpFor(tester, const Duration(milliseconds: 800));

    await tester.enterText(
      _fieldWithLabel('Email address'),
      'alex@nescom.app',
    );
    await tester.enterText(_fieldWithLabel('Password'), 'password123');

    // The button is wrapped in an AnimatedScale (a Transform), which trips the
    // tap hit-test warning even though the tap lands — hence warnIfMissed.
    await tester.tap(
      find.widgetWithText(CustomButton, 'Login'),
      warnIfMissed: false,
    );
    await _pumpFor(tester, const Duration(milliseconds: 1600));

    expect(find.text('Alex Morgan'), findsWidgets);
    expect(find.text('Total bookings'), findsOneWidget);
    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.text('Dental Checkup'), findsOneWidget);
  });

  testWidgets('dashboard renders the curved navigation bar on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(const DashboardScreen()));
    await tester.pump();

    expect(find.byType(CurvedNavigationBar), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Total bookings'), findsOneWidget);
  });
}
