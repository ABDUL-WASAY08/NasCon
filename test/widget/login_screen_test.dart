import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nescom/features/auth/login_screen.dart';

import '../helpers/test_harness.dart';

void main() {
  testWidgets('login shows inline validation for empty input', (tester) async {
    final container = testContainer();
    await tester.pumpWidget(wrapScreen(const LoginScreen(), container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('login validates email format', (tester) async {
    final container = testContainer();
    await tester.pumpWidget(wrapScreen(const LoginScreen(), container));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'not-an-email',
    );
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });

  testWidgets('password visibility can be toggled', (tester) async {
    final container = testContainer();
    await tester.pumpWidget(wrapScreen(const LoginScreen(), container));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsNothing);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);
  });

  testWidgets('a demo account fills the form in mock mode', (tester) async {
    final container = testContainer();
    await tester.pumpWidget(wrapScreen(const LoginScreen(), container));
    await tester.pumpAndSettle();

    expect(find.text('Demo accounts (mock backend)'), findsOneWidget);

    await tester.tap(find.text('Club Manager'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(field.controller?.text, 'manager@nascon.example');
  });
}
