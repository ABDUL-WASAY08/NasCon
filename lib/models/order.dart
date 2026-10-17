import 'package:flutter/foundation.dart';

import 'order_item.dart';

/// Lifecycle of an order.
enum OrderStatus {
  pending('pending', 'Pending'),
  confirmed('confirmed', 'Confirmed'),
  failed('failed', 'Failed'),
  cancelled('cancelled', 'Cancelled'),
  unknown('unknown', 'Unknown');

  const OrderStatus(this.wire, this.label);

  final String wire;
  final String label;

  static OrderStatus fromWire(Object? value) {
    if (value is! String) return OrderStatus.unknown;
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return OrderStatus.unknown;
  }
}

/// Payment outcome reported by the (mock) payment flow.
enum PaymentStatus {
  pending('pending', 'Pending'),
  paid('paid', 'Paid'),
  declined('declined', 'Declined'),
  failed('failed', 'Failed'),
  unknown('unknown', 'Unknown');

  const PaymentStatus(this.wire, this.label);

  final String wire;
  final String label;

  static PaymentStatus fromWire(Object? value) {
    if (value is! String) return PaymentStatus.unknown;
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return PaymentStatus.unknown;
  }
}

/// A placed order.
@immutable
class Order {
  const Order({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.total,
    this.status = OrderStatus.pending,
    this.paymentStatus = PaymentStatus.pending,
    this.tax = 0,
    this.shipping = 0,
    this.discount = 0,
    this.currency = 'PKR',
    this.createdAt,
    this.paymentReference,
  });

  final String id;
  final List<OrderItem> items;
  final double subtotal;
  final double total;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final double tax;
  final double shipping;
  final double discount;
  final String currency;
  final DateTime? createdAt;
  final String? paymentReference;

  bool get isConfirmed => status == OrderStatus.confirmed;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as String? ?? '',
    items: (json['items'] as List?)
            ?.whereType<Map>()
            .map((i) => OrderItem.fromJson(i.cast<String, dynamic>()))
            .toList() ??
        const [],
    subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
    total: (json['total'] as num?)?.toDouble() ?? 0,
    status: OrderStatus.fromWire(json['status']),
    paymentStatus: PaymentStatus.fromWire(json['payment_status']),
    tax: (json['tax'] as num?)?.toDouble() ?? 0,
    shipping: (json['shipping'] as num?)?.toDouble() ?? 0,
    discount: (json['discount'] as num?)?.toDouble() ?? 0,
    currency: json['currency'] as String? ?? 'PKR',
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal(),
    paymentReference: json['payment_reference'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'items': items.map((i) => i.toJson()).toList(),
    'subtotal': subtotal,
    'total': total,
    'status': status.wire,
    'payment_status': paymentStatus.wire,
    'tax': tax,
    'shipping': shipping,
    'discount': discount,
    'currency': currency,
    'created_at': createdAt?.toUtc().toIso8601String(),
    'payment_reference': paymentReference,
  };
}
