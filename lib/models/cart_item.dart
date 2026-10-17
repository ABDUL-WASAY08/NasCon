import 'package:flutter/foundation.dart';

/// A line in the local cart.
///
/// The cart is the single source of truth for totals; nothing recomputes a
/// price anywhere else.
@immutable
class CartItem {
  const CartItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.variantId,
    this.variantName,
    this.imageUrl,
    this.currency = 'PKR',
    this.availableStock,
  });

  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final String? variantId;
  final String? variantName;
  final String? imageUrl;
  final String currency;

  /// Stock known at the time the item was added — a client-side guard only.
  /// The server remains authoritative at checkout.
  final int? availableStock;

  /// Stable identity for a cart line (product + variant).
  String get lineId => '$productId::${variantId ?? '-'}';

  double get lineTotal => unitPrice * quantity;

  /// Highest quantity this line may hold, given known stock.
  int get maxQuantity {
    final stock = availableStock;
    if (stock == null) return 99;
    return stock < 1 ? 1 : stock;
  }

  bool get isAtStockLimit => availableStock != null && quantity >= availableStock!;

  CartItem copyWith({int? quantity, double? unitPrice, int? availableStock}) =>
      CartItem(
        productId: productId,
        productName: productName,
        unitPrice: unitPrice ?? this.unitPrice,
        quantity: quantity ?? this.quantity,
        variantId: variantId,
        variantName: variantName,
        imageUrl: imageUrl,
        currency: currency,
        availableStock: availableStock ?? this.availableStock,
      );

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    productId: json['product_id'] as String? ?? '',
    productName: json['product_name'] as String? ?? '',
    unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    variantId: json['variant_id'] as String?,
    variantName: json['variant_name'] as String?,
    imageUrl: json['image_url'] as String?,
    currency: json['currency'] as String? ?? 'PKR',
    availableStock: (json['available_stock'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'product_name': productName,
    'unit_price': unitPrice,
    'quantity': quantity,
    'variant_id': variantId,
    'variant_name': variantName,
    'image_url': imageUrl,
    'currency': currency,
    'available_stock': availableStock,
  };
}
