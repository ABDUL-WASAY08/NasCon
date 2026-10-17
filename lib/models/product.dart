import 'package:flutter/foundation.dart';

import 'product_variant.dart';

/// A purchasable product in the club store.
@immutable
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.imageUrl,
    this.category,
    this.currency = 'PKR',
    this.variants = const [],
    this.stockQuantity,
  });

  final String id;
  final String name;

  /// Base price, used when a variant does not override it.
  final double price;

  final String? description;
  final String? imageUrl;
  final String? category;
  final String currency;
  final List<ProductVariant> variants;

  /// Aggregate stock when the product has no variants.
  final int? stockQuantity;

  bool get hasVariants => variants.isNotEmpty;

  bool get isInStock {
    if (hasVariants) return variants.any((v) => v.stockQuantity > 0);
    final stock = stockQuantity;
    return stock == null || stock > 0;
  }

  /// Total units available (variants summed, or the flat stock).
  int get availableQuantity {
    if (hasVariants) {
      return variants.fold(0, (sum, v) => sum + v.stockQuantity);
    }
    return stockQuantity ?? 0;
  }

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0,
    description: json['description'] as String?,
    imageUrl: json['image_url'] as String?,
    category: json['category'] as String?,
    currency: json['currency'] as String? ?? 'PKR',
    variants: (json['variants'] as List?)
            ?.whereType<Map>()
            .map((v) => ProductVariant.fromJson(v.cast<String, dynamic>()))
            .toList() ??
        const [],
    stockQuantity: (json['stock_quantity'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'description': description,
    'image_url': imageUrl,
    'category': category,
    'currency': currency,
    'variants': variants.map((v) => v.toJson()).toList(),
    'stock_quantity': stockQuantity,
  };
}
