import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/cart_item.dart';
import '../../../models/cart_totals.dart';
import 'cart_controller.dart';

/// Screen 06c — Cart.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

typedef CartAndCheckoutScreen = CartScreen;

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _promoController = TextEditingController();
  String? _promoError;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    ref.listen(cartProvider, (previous, next) {
      if (previous?.isNotEmpty == true && next.isEmpty) {
        ref.read(cartPromoCodeProvider.notifier).state = null;
      }
    });
    final items = ref.watch(cartProvider);
    final totals = ref.watch(cartTotalsProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Your Cart'),
      body: items.isEmpty
          ? EmptyStateView(
              icon: Icons.shopping_bag_outlined,
              title: 'Your cart is empty',
              message: 'Browse the club store to add merchandise.',
              actionLabel: 'Go to store',
              onAction: () => context.go('/store'),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.lg,
                    ),
                    itemCount: items.length + 1,
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        return _promoBox(totals.subtotal);
                      }
                      return _CartTile(
                        item: items[index],
                        onQuantityChanged: (lineId, quantity) =>
                            _setQuantity(context, ref, lineId, quantity),
                        onRemove: (lineId) =>
                            ref.read(cartProvider.notifier).remove(lineId),
                      );
                    },
                  ),
                ),
                _TotalsBar(
                  totals: totals,
                  onCheckout: () => context.push('/checkout'),
                ),
              ],
            ),
    );
  }

  Widget _promoBox(double subtotal) {
    final appliedCode = ref.watch(cartPromoCodeProvider);
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Promo code', style: AppTextStyles.bodyMedium),
                    Text(
                      'Try NASCON10 for 10% off',
                      style: AppTextStyles.helper.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (appliedCode != null)
                TextButton(
                  onPressed: () {
                    ref.read(cartPromoCodeProvider.notifier).state = null;
                    _promoController.clear();
                    setState(() => _promoError = null);
                  },
                  child: const Text('Remove'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  textCapitalization: TextCapitalization.characters,
                  enabled: appliedCode == null,
                  decoration: InputDecoration(
                    hintText: 'Enter promo code',
                    errorText: _promoError,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: appliedCode == null
                    ? () {
                        final code = _promoController.text.trim().toUpperCase();
                        if (code == 'NASCON10' && subtotal > 0) {
                          ref.read(cartPromoCodeProvider.notifier).state = code;
                          setState(() => _promoError = null);
                          FocusScope.of(context).unfocus();
                        } else {
                          setState(
                            () => _promoError = subtotal <= 0
                                ? 'Add an item before applying a code.'
                                : 'That promo code is not valid.',
                          );
                        }
                      }
                    : null,
                child: Text(appliedCode == null ? 'Apply' : 'Applied'),
              ),
            ],
          ),
          if (appliedCode != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$appliedCode applied · ${(subtotal * .1).toStringAsFixed(2)} $itemsCurrency',
              style: AppTextStyles.helper.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get itemsCurrency {
    final items = ref.read(cartProvider);
    return items.isEmpty ? 'PKR' : items.first.currency;
  }

  Future<void> _setQuantity(
    BuildContext context,
    WidgetRef ref,
    String lineId,
    int quantity,
  ) async {
    final ok = await ref
        .read(cartProvider.notifier)
        .setQuantity(lineId, quantity);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('That is the most we have available right now.'),
          ),
        );
    }
  }
}

class _CartTile extends StatelessWidget {
  const _CartTile({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final CartItem item;
  final void Function(String lineId, int quantity) onQuantityChanged;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.variantName != null)
                      Text(
                        item.variantName!,
                        style: AppTextStyles.helper.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${item.currency} ${item.unitPrice.toStringAsFixed(0)} each',
                      style: AppTextStyles.helper.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove ${item.productName}',
                onPressed: () => onRemove(item.lineId),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _QtyButton(
                icon: Icons.remove_rounded,
                tooltip: 'Decrease quantity',
                onPressed: item.quantity > 1
                    ? () => onQuantityChanged(item.lineId, item.quantity - 1)
                    : null,
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '${item.quantity}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.button,
                ),
              ),
              _QtyButton(
                icon: Icons.add_rounded,
                tooltip: 'Increase quantity',
                onPressed: item.isAtStockLimit
                    ? null
                    : () => onQuantityChanged(item.lineId, item.quantity + 1),
              ),
              const Spacer(),
              Text(
                '${item.currency} ${item.lineTotal.toStringAsFixed(0)}',
                style: AppTextStyles.price,
              ),
            ],
          ),
          if (item.isAtStockLimit) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Maximum available quantity reached.',
              style: AppTextStyles.helper.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, size: AppSizes.iconMd),
      ),
    );
  }
}

class _TotalsBar extends StatelessWidget {
  const _TotalsBar({required this.totals, required this.onCheckout});

  final CartTotals totals;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _line(context, 'Subtotal', totals.subtotal),
              if (totals.discount > 0)
                _line(context, 'Discount', -totals.discount),
              _line(context, 'Tax (5%)', totals.tax),
              const Divider(height: AppSpacing.lg),
              _line(context, 'Total', totals.total, emphasise: true),
              const SizedBox(height: AppSpacing.lg),
              CustomButton(
                text: 'Proceed to Checkout',
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: totals.isEmpty ? null : onCheckout,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(
    BuildContext context,
    String label,
    double value, {
    bool emphasise = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final style = emphasise
        ? AppTextStyles.h3
        : AppTextStyles.bodyMedium.copyWith(color: scheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(
            '${totals.currency} ${value.toStringAsFixed(2)}',
            style: emphasise ? AppTextStyles.h3 : AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
