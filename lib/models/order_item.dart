import 'package:flutter/foundation.dart';

/// A purchased line inside an [Order].
@immutable
class OrderItem {
  const OrderItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.variantId,
    this.variantName,
    this.currency = 'PKR',
    this.imageUrl,
  });

  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final String? variantId;
  final String? variantName;
  final String currency;
  final String? imageUrl;

  double get lineTotal => unitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productId: json['product_id'] as String? ?? '',
    productName: json['product_name'] as String? ?? '',
    unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    variantId: json['variant_id'] as String?,
    variantName: json['variant_name'] as String?,
    currency: json['currency'] as String? ?? 'PKR',
    imageUrl: json['image_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'product_name': productName,
    'unit_price': unitPrice,
    'quantity': quantity,
    'variant_id': variantId,
    'variant_name': variantName,
    'currency': currency,
    'image_url': imageUrl,
  };
}
