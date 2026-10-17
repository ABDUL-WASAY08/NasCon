import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nescom/core/widgets/empty_state_view.dart';
import 'package:nescom/core/widgets/loading_view.dart';
import 'package:nescom/features/match_detail/match_detail_screen.dart';
import 'package:nescom/features/notifications/notifications_screen.dart';
import 'package:nescom/features/store/cart_controller.dart';
import 'package:nescom/features/store/cart_screen.dart';
import 'package:nescom/features/store/product_detail_screen.dart';
import 'package:nescom/models/cart_item.dart';
import 'package:nescom/models/product.dart';
import 'package:nescom/repositories/repository_providers.dart';

import '../helpers/test_harness.dart';

const _jersey = Product(
  id: 'p1',
  name: 'Home Jersey',
  price: 1000,
  stockQuantity: 3,
  currency: 'PKR',
);

void main() {
  test('mock checkout applies the accepted cart promo code', () async {
    final container = testContainer();
    final result = await container
        .read(ordersRepositoryProvider)
        .placeOrder(
          items: const [
            CartItem(
              productId: 'p1',
              productName: 'Home Jersey',
              unitPrice: 1000,
              quantity: 1,
              availableStock: 3,
            ),
          ],
          idempotencyKey: 'promo-test',
          promoCode: 'NASCON10',
        );

    expect(result.order.discount, 100);
    expect(result.order.total, 945);
  });

  testWidgets('match detail exposes lineup, stats, and summary tabs', (
    tester,
  ) async {
    final container = testContainer();
    setTestViewport(tester, height: 1400);
    await tester.pumpWidget(
      wrapScreen(const MatchDetailScreen(matchId: 'fx_01'), container),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lineups'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Match Summary'), findsOneWidget);
    expect(find.text('Starting lineups'), findsOneWidget);
    expect(find.text('Bilal Ahmed'), findsOneWidget);

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.text('Match statistics'), findsOneWidget);
    expect(find.text('Possession'), findsOneWidget);

    await tester.tap(find.text('Match Summary'));
    await tester.pumpAndSettle();
    expect(find.text('Match information'), findsOneWidget);
    expect(find.text('Match events'), findsOneWidget);
  });

  testWidgets('product details show a gallery, size choices, and sticky cart', (
    tester,
  ) async {
    final container = testContainer();
    setTestViewport(tester, height: 1000);
    await tester.pumpWidget(
      wrapScreen(
        const ProductDetailScreen(productId: 'pr_jersey_home'),
        container,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PageView), findsOneWidget);
    expect(find.text('Home Jersey 2026'), findsOneWidget);
    expect(find.text('Small'), findsOneWidget);
    expect(find.text('Add to Cart'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Medium'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to Cart'));
    await tester.pumpAndSettle();
    expect(container.read(cartProvider), hasLength(1));
    expect(container.read(cartProvider).single.variantName, 'Medium');
  });

  testWidgets('cart promo code discounts totals and appears in summary', (
    tester,
  ) async {
    final container = testContainer();
    setTestViewport(tester, height: 1400);
    await container.read(cartProvider.notifier).addProduct(_jersey);
    await tester.pumpWidget(wrapScreen(const CartScreen(), container));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'nascon10');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Discount'), findsOneWidget);
    expect(find.text('PKR 945.00'), findsOneWidget);
    expect(container.read(cartTotalsProvider).discount, 100);
  });

  testWidgets('notifications have unread states and can be marked read', (
    tester,
  ) async {
    final container = testContainer();
    setTestViewport(tester, height: 1200);
    await tester.pumpWidget(wrapScreen(const NotificationsScreen(), container));
    await tester.pumpAndSettle();

    expect(find.text('2 unread updates'), findsOneWidget);
    expect(find.text('Match is underway'), findsOneWidget);
    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();

    expect(find.text('You’re all caught up'), findsOneWidget);
  });

  testWidgets('shared shimmer and empty-state widgets render', (tester) async {
    final container = testContainer();
    await tester.pumpWidget(
      wrapScreen(
        const Scaffold(
          body: Column(
            children: [
              ShimmerLoadingWidgets(
                layout: ShimmerLayout.matchCard,
                itemCount: 2,
              ),
              Expanded(
                child: EmptyStateWidget(
                  icon: Icons.inbox_outlined,
                  title: 'Nothing here',
                  message: 'Check back later.',
                ),
              ),
            ],
          ),
        ),
        container,
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(ShimmerLoadingWidgets), findsOneWidget);
    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Check back later.'), findsOneWidget);
  });
}
