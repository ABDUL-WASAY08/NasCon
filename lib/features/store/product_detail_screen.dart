import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/product.dart';
import '../../../models/product_variant.dart';
import '../../../repositories/repository_providers.dart';
import '../../../repositories/repository_types.dart';
import 'cart_controller.dart';

/// Screen 06b — Product detail.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  ProductVariant? _variant;
  int _quantity = 1;
  bool _adding = false;

  ProductVariant? get _effectiveVariant {
    final variants = _product?.variants ?? const <ProductVariant>[];
    if (variants.isEmpty) return null;
    return _variant;
  }

  Product? _product;

  int? get _availableStock {
    final product = _product;
    if (product == null) return null;
    final variant = _effectiveVariant;
    return variant?.stockQuantity ?? product.stockQuantity;
  }

  bool get _canAdd {
    final product = _product;
    if (product == null) return false;
    if (!product.isInStock) return false;
    if (product.hasVariants && _effectiveVariant == null) return false;
    final stock = _availableStock;
    if (stock != null && stock <= 0) return false;
    return true;
  }

  String? get _blockingReason {
    final product = _product;
    if (product == null) return 'Loading…';
    if (!product.isInStock) return 'This item is currently sold out.';
    if (product.hasVariants && _effectiveVariant == null) {
      return 'Choose an option to continue.';
    }
    return null;
  }

  Future<void> _addToCart() async {
    final product = _product;
    if (product == null || !_canAdd || _adding) return;

    setState(() => _adding = true);
    final added = await ref
        .read(cartProvider.notifier)
        .addProduct(product, variant: _effectiveVariant, quantity: _quantity);
    if (!mounted) return;
    setState(() => _adding = false);

    if (added == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('That item is not available.')),
        );
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Added ${added.productName} to your cart.'),
          action: SnackBarAction(
            label: 'View cart',
            onPressed: () => context.push('/cart'),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Product'),
      body: FutureBuilder<Cached<Product>>(
        future: ref.read(storeRepositoryProvider).product(widget.productId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(message: 'Loading product…');
          }
          if (snapshot.hasError) {
            return ErrorView(error: snapshot.error!);
          }

          final product = snapshot.data?.data;
          if (product == null) {
            return const EmptyStateView(
              icon: Icons.search_off_rounded,
              title: 'Product not found',
            );
          }
          _product = product;

          final stock = _availableStock;
          final maxQuantity = stock == null || stock < 1 ? 1 : stock;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xxxl,
            ),
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  color: scheme.primary.withValues(alpha: 0.08),
                ),
                child: Icon(
                  Icons.checkroom_rounded,
                  size: 64,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(product.name, style: AppTextStyles.h2),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    '${product.currency} '
                    '${(_effectiveVariant?.price ?? product.price).toStringAsFixed(0)}',
                    style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  StatusBadge(
                    label: product.isInStock ? 'In stock' : 'Sold out',
                    tone: product.isInStock
                        ? StatusTone.success
                        : StatusTone.danger,
                    dense: true,
                  ),
                ],
              ),
              if (product.description != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  product.description!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (product.hasVariants) ...[
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'Options'),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final variant in product.variants)
                      ChoiceChip(
                        label: Text(
                          variant.isInStock
                              ? variant.name
                              : '${variant.name} (sold out)',
                        ),
                        selected: _effectiveVariant?.id == variant.id,
                        onSelected: variant.isInStock
                            ? (_) => setState(() {
                                _variant = variant;
                                _quantity = 1;
                              })
                            : null,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Text('Quantity', style: AppTextStyles.label),
                  const Spacer(),
                  _Stepper(
                    value: _quantity,
                    max: maxQuantity,
                    onChanged: (value) => setState(() => _quantity = value),
                  ),
                ],
              ),
              if (stock != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$stock available',
                  style: AppTextStyles.helper.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              CustomButton(
                text: 'Add to Cart',
                icon: Icons.add_shopping_cart_rounded,
                isLoading: _adding,
                onPressed: _canAdd ? _addToCart : null,
              ),
              if (_blockingReason != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _blockingReason!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.helper.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Decrease quantity',
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline_rounded),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: AppTextStyles.button,
          ),
        ),
        IconButton(
          tooltip: 'Increase quantity',
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline_rounded),
        ),
      ],
    );
  }
}
