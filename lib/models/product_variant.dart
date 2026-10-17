import 'package:flutter/foundation.dart';

/// A purchasable variant of a [Product] (size, colour, …).
@immutable
class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.name,
    this.productId,
    this.price,
    this.stockQuantity = 0,
    this.sku,
  });

  final String id;
  final String name;
  final String? productId;

  /// Overrides the parent product's price when present.
  final double? price;

  final int stockQuantity;
  final String? sku;

  bool get isInStock => stockQuantity > 0;

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    productId: json['product_id'] as String?,
    price: (json['price'] as num?)?.toDouble(),
    stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 0,
    sku: json['sku'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'product_id': productId,
    'price': price,
    'stock_quantity': stockQuantity,
    'sku': sku,
  };
}
