import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/receipt.dart';
import 'repository_types.dart';

/// Order placement and receipts.
///
/// Implementations must be idempotent for a repeated submission of the same
/// cart (the client sends a stable idempotency key) and must return a clear
/// [AppException] for out-of-stock, declined payment and network interruption —
/// never a fabricated success.
abstract interface class OrdersRepository {
  /// Places the order. [idempotencyKey] is generated once per checkout attempt
  /// and reused if the user retries the same cart.
  Future<CheckoutResult> placeOrder({
    required List<CartItem> items,
    required String idempotencyKey,
  });

  Future<Order> order(String orderId);

  Future<Receipt> receipt(String orderId);
}
