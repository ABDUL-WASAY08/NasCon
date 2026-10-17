import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_database.dart';
import '../../models/cart_item.dart';
import '../../models/cart_totals.dart';
import '../../models/product.dart';
import '../../models/product_variant.dart';
import '../../repositories/repository_providers.dart';

/// The single source of truth for the cart.
///
/// Persisted through [LocalDatabase], so totals survive a restart and are never
/// recomputed anywhere else.
class CartController extends StateNotifier<List<CartItem>> {
  CartController(this._database) : super(const []) {
    _initialLoad = _restore();
  }

  final LocalDatabase _database;

  /// Completes when the persisted cart has been read. Every mutation awaits it
  /// first, so a load that resolves late can never clobber a user's change.
  late final Future<void> _initialLoad;

  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> _restore() async {
    final items = await _database.loadCart();
    if (!mounted) return;
    state = items;
    _loaded = true;
  }

  Future<void> _persist() => _database.saveCart(state);

  /// Adds a product (with the chosen variant) or increments the existing line.
  Future<CartItem?> addProduct(
    Product product, {
    ProductVariant? variant,
    int quantity = 1,
  }) async {
    await _initialLoad;
    if (quantity < 1) return null;

    final variantId = variant?.id;
    final stock = variant?.stockQuantity ?? product.stockQuantity;
    final unitPrice = variant?.price ?? product.price;

    if (stock != null && stock <= 0) return null;

    final lineId = '${product.id}::${variantId ?? '-'}';
    final index = state.indexWhere((item) => item.lineId == lineId);

    if (index >= 0) {
      final existing = state[index];
      final maxQuantity = stock ?? existing.maxQuantity;
      final nextQuantity = (existing.quantity + quantity).clamp(1, maxQuantity);
      if (nextQuantity == existing.quantity) return existing;
      final updated = existing.copyWith(quantity: nextQuantity);
      state = [...state]..[index] = updated;
      await _persist();
      return updated;
    }

    final maxQuantity = stock ?? 99;
    final item = CartItem(
      productId: product.id,
      productName: product.name,
      variantId: variantId,
      variantName: variant?.name,
      imageUrl: product.imageUrl,
      unitPrice: unitPrice,
      currency: product.currency,
      quantity: quantity.clamp(1, maxQuantity),
      availableStock: stock,
    );
    state = [...state, item];
    await _persist();
    return item;
  }

  /// Sets an absolute quantity, clamped to `[1, maxQuantity]`.
  ///
  /// Returns `false` when the requested quantity is above the known stock, so
  /// the UI can explain why nothing changed.
  Future<bool> setQuantity(String lineId, int quantity) async {
    await _initialLoad;
    final index = state.indexWhere((item) => item.lineId == lineId);
    if (index < 0) return false;
    final item = state[index];

    if (quantity < 1) {
      await remove(lineId);
      return true;
    }
    if (quantity > item.maxQuantity) return false;

    state = [...state]..[index] = item.copyWith(quantity: quantity);
    await _persist();
    return true;
  }

  Future<void> increment(String lineId) async {
    final item = _find(lineId);
    if (item == null) return;
    await setQuantity(lineId, item.quantity + 1);
  }

  Future<void> decrement(String lineId) async {
    final item = _find(lineId);
    if (item == null) return;
    await setQuantity(lineId, item.quantity - 1);
  }

  Future<void> remove(String lineId) async {
    await _initialLoad;
    state = state.where((item) => item.lineId != lineId).toList();
    await _persist();
  }

  Future<void> clear() async {
    await _initialLoad;
    state = const [];
    await _persist();
  }

  CartItem? _find(String lineId) {
    for (final item in state) {
      if (item.lineId == lineId) return item;
    }
    return null;
  }
}

final cartProvider = StateNotifierProvider<CartController, List<CartItem>>(
  (ref) => CartController(ref.watch(localDatabaseProvider)),
);

/// Mock campaign code shared by the cart and checkout review.
final cartPromoCodeProvider = StateProvider<String?>((ref) => null);

/// Live totals for the current cart.
final cartTotalsProvider = Provider<CartTotals>((ref) {
  final items = ref.watch(cartProvider);
  final promoCode = ref.watch(cartPromoCodeProvider);
  final subtotal = items.fold<double>(
    0,
    (total, item) => total + item.lineTotal,
  );
  final discount = promoCode == 'NASCON10' ? subtotal * .10 : 0.0;
  return CartTotals.fromItems(items, taxRate: 0.05, discount: discount);
});

/// Number of individual units in the cart (drives the badge).
final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartTotalsProvider).itemCount,
);
