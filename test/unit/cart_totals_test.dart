import 'package:flutter_test/flutter_test.dart';

import 'package:nescom/models/cart_item.dart';
import 'package:nescom/models/cart_totals.dart';

CartItem _item({
  required double price,
  required int quantity,
  String id = 'p1',
  int? stock,
}) => CartItem(
  productId: id,
  productName: 'Item $id',
  unitPrice: price,
  quantity: quantity,
  availableStock: stock,
);

void main() {
  group('CartTotals', () {
    test('empty cart has zero totals', () {
      final totals = CartTotals.fromItems(const []);
      expect(totals.isEmpty, isTrue);
      expect(totals.subtotal, 0);
      expect(totals.total, 0);
    });

    test('sums lines and counts units', () {
      final totals = CartTotals.fromItems([
        _item(price: 4500, quantity: 2),
        _item(id: 'p2', price: 1500, quantity: 3),
      ]);
      expect(totals.itemCount, 5);
      expect(totals.subtotal, 13500);
      expect(totals.tax, 0);
      expect(totals.total, 13500);
    });

    test('applies tax to the discounted subtotal', () {
      final totals = CartTotals.fromItems(
        [_item(price: 1000, quantity: 1)],
        taxRate: 0.05,
        discount: 200,
      );
      expect(totals.subtotal, 1000);
      expect(totals.discount, 200);
      expect(totals.tax, 40);
      expect(totals.total, 840);
    });

    test('clamps a discount larger than the subtotal', () {
      final totals = CartTotals.fromItems(
        [_item(price: 100, quantity: 1)],
        discount: 500,
      );
      expect(totals.discount, 100);
      expect(totals.total, 0);
      expect(totals.total, greaterThanOrEqualTo(0));
    });

    test('ignores a negative shipping value', () {
      final totals = CartTotals.fromItems(
        [_item(price: 100, quantity: 1)],
        shipping: -50,
      );
      expect(totals.shipping, 0);
      expect(totals.total, 100);
    });

    test('rounds money to two decimals', () {
      final totals = CartTotals.fromItems(
        [_item(price: 33.333, quantity: 3)],
        taxRate: 0.05,
      );
      expect(totals.subtotal, 100.0);
      expect(totals.tax, 5.0);
      expect(totals.total, 105.0);
    });
  });

  group('CartItem quantity guards', () {
    test('maxQuantity defaults when stock is unknown', () {
      expect(_item(price: 10, quantity: 1).maxQuantity, 99);
    });

    test('detects the stock limit', () {
      final item = _item(price: 10, quantity: 4, stock: 4);
      expect(item.isAtStockLimit, isTrue);
    });

    test('line total follows the quantity', () {
      expect(_item(price: 250, quantity: 3).lineTotal, 750);
    });
  });
}
