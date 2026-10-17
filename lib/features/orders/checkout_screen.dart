import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/cart_totals.dart';
import '../../../repositories/repository_providers.dart';
import '../store/cart_controller.dart';

/// Screen 06d — Checkout.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  /// Generated once per checkout attempt so a retry of the same cart is
  /// idempotent and cannot create a duplicate order.
  final String _idempotencyKey = const Uuid().v4();

  bool _submitting = false;
  String? _error;

  Future<void> _placeOrder() async {
    if (_submitting) return;

    final items = ref.read(cartProvider);
    if (items.isEmpty) {
      setState(() => _error = 'Your cart is empty.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await ref
          .read(ordersRepositoryProvider)
          .placeOrder(
            items: items,
            idempotencyKey: _idempotencyKey,
            promoCode: ref.read(cartPromoCodeProvider),
          );

      await ref.read(cartProvider.notifier).clear();
      ref.read(cartPromoCodeProvider.notifier).state = null;
      if (!mounted) return;
      context.pushReplacement('/orders/${result.order.id}/receipt');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = ErrorMapper.messageFor(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = ref.watch(cartProvider);
    final totals = ref.watch(cartTotalsProvider);
    final online = ref.watch(connectivityStatusProvider).valueOrNull ?? true;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Checkout'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xxxl,
        ),
        children: [
          if (!online) ...[
            const InfoBanner(
              message:
                  'You are offline. Connect to the internet to place your order.',
              tone: InfoBannerTone.warning,
              icon: Icons.cloud_off_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const SectionHeader(title: 'Order summary'),
          CustomCard(
            child: Column(
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.variantName == null
                                ? item.productName
                                : '${item.productName} (${item.variantName})',
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                        Text(
                          '×${item.quantity}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          '${item.currency} ${item.lineTotal.toStringAsFixed(0)}',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Payment'),
          CustomCard(
            child: Row(
              children: [
                Icon(
                  Icons.credit_card_rounded,
                  color: scheme.primary,
                  size: AppSizes.iconLg,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mock payment', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 2),
                      Text(
                        'A simulated provider — no real card details are '
                        'collected or transmitted.',
                        style: AppTextStyles.helper.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _Totals(totals: totals),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.lg),
            InfoBanner(
              message: _error!,
              tone: InfoBannerTone.warning,
              icon: Icons.error_outline_rounded,
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          CustomButton(
            text: 'Place Order',
            icon: Icons.lock_rounded,
            isLoading: _submitting,
            onPressed: (totals.isEmpty || !online || _submitting)
                ? null
                : _placeOrder,
          ),
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.totals});

  final CartTotals totals;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomCard(
      child: Column(
        children: [
          _line(context, 'Subtotal', totals.subtotal, scheme),
          _line(context, 'Tax (5%)', totals.tax, scheme),
          if (totals.shipping > 0)
            _line(context, 'Shipping', totals.shipping, scheme),
          const Divider(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(child: Text('Total', style: AppTextStyles.h3)),
              Text(
                '${totals.currency} ${totals.total.toStringAsFixed(2)}',
                style: AppTextStyles.h3,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(
    BuildContext context,
    String label,
    double value,
    ColorScheme scheme,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          '${totals.currency} ${value.toStringAsFixed(2)}',
          style: AppTextStyles.bodyMedium,
        ),
      ],
    ),
  );
}
