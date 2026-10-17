import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nescom/features/store/cart_screen.dart';
import 'package:nescom/features/store/cart_controller.dart';
import 'package:nescom/models/product.dart';

import '../helpers/test_harness.dart';

const _jersey = Product(
  id: 'p1',
  name: 'Home Jersey',
  price: 1000,
  stockQuantity: 3,
  currency: 'PKR',
);

void main() {
  testWidgets('an empty cart shows the empty state', (tester) async {
    final container = testContainer();
    await tester.pumpWidget(wrapScreen(const CartScreen(), container));
    await tester.pumpAndSettle();

    expect(find.text('Your cart is empty'), findsOneWidget);
  });

  testWidgets('quantity changes update the line and grand total', (
    tester,
  ) async {
    final container = testContainer();
    await container.read(cartProvider.notifier).addProduct(_jersey, quantity: 1);

    await tester.pumpWidget(wrapScreen(const CartScreen(), container));
    await tester.pumpAndSettle();

    expect(find.text('PKR 1000.00'), findsWidgets);

    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pumpAndSettle();

    // 2 × 1000 + 5% tax = 2100
    expect(find.text('PKR 2100.00'), findsOneWidget);
  });

  testWidgets('quantity cannot exceed the available stock', (tester) async {
    final container = testContainer();
    await container.read(cartProvider.notifier).addProduct(_jersey, quantity: 3);

    await tester.pumpWidget(wrapScreen(const CartScreen(), container));
    await tester.pumpAndSettle();

    expect(find.text('Maximum available quantity reached.'), findsOneWidget);

    final increase = tester.widget<IconButton>(
      find.byTooltip('Increase quantity'),
    );
    expect(increase.onPressed, isNull);
  });

  testWidgets('removing the last line returns to the empty state', (
    tester,
  ) async {
    final container = testContainer();
    await container.read(cartProvider.notifier).addProduct(_jersey);

    await tester.pumpWidget(wrapScreen(const CartScreen(), container));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Remove Home Jersey'));
    await tester.pumpAndSettle();

    expect(find.text('Your cart is empty'), findsOneWidget);
  });
}
