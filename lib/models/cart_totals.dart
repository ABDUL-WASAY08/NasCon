import 'package:flutter/foundation.dart';

import 'cart_item.dart';

/// Pure, testable cart maths. Every money value is rounded to 2 decimals and
/// clamped at zero, so no screen ever shows a stale or negative total.
@immutable
class CartTotals {
  const CartTotals({
    required this.itemCount,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.shipping,
    required this.total,
    required this.currency,
  });

  final int itemCount;
  final double subtotal;
  final double discount;
  final double tax;
  final double shipping;
  final double total;
  final String currency;

  static const CartTotals empty = CartTotals(
    itemCount: 0,
    subtotal: 0,
    discount: 0,
    tax: 0,
    shipping: 0,
    total: 0,
    currency: 'PKR',
  );

  bool get isEmpty => itemCount == 0;

  /// Computes totals from cart lines.
  ///
  /// [taxRate] is a fraction (0.05 = 5%) applied to the discounted subtotal.
  static CartTotals fromItems(
    List<CartItem> items, {
    double taxRate = 0,
    double discount = 0,
    double shipping = 0,
  }) {
    if (items.isEmpty) {
      return CartTotals(
        itemCount: 0,
        subtotal: 0,
        discount: 0,
        tax: 0,
        shipping: _round2(shipping < 0 ? 0 : shipping),
        total: _round2(shipping < 0 ? 0 : shipping),
        currency: 'PKR',
      );
    }

    var subtotal = 0.0;
    var count = 0;
    for (final item in items) {
      subtotal += item.unitPrice * item.quantity;
      count += item.quantity;
    }

    final safeDiscount = _clamp(discount, 0, subtotal);
    final taxable = subtotal - safeDiscount;
    final tax = _round2(taxable * (taxRate < 0 ? 0 : taxRate));
    final safeShipping = _round2(shipping < 0 ? 0 : shipping);
    final total = _round2(taxable + tax + safeShipping);

    return CartTotals(
      itemCount: count,
      subtotal: _round2(subtotal),
      discount: _round2(safeDiscount),
      tax: tax,
      shipping: safeShipping,
      total: total,
      currency: items.first.currency,
    );
  }

  static double _round2(double value) => (value * 100).roundToDouble() / 100;

  static double _clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
