import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/product.dart';
import '../../../repositories/repository_providers.dart';
import '../../../repositories/repository_types.dart';
import 'cart_controller.dart';

/// Screen 06 — Store (catalogue).
class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  final _searchController = TextEditingController();
  String? _category;
  String _query = '';
  late Future<Cached<List<Product>>> _future;
  late Future<List<String>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _categoriesFuture = ref.read(storeRepositoryProvider).categories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Cached<List<Product>>> _load({bool forceRefresh = false}) =>
      ref
          .read(storeRepositoryProvider)
          .products(
            category: _category,
            query: _query,
            forceRefresh: forceRefresh,
          );

  Future<void> _refresh() async {
    final future = _load(forceRefresh: true);
    setState(() => _future = future);
    await future.catchError((Object _) => const Cached<List<Product>>(data: []));
  }

  void _setCategory(String? category) {
    if (_category == category) return;
    setState(() {
      _category = category;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Club Store', style: AppTextStyles.h3),
            Text(
              'Official league merchandise',
              style: AppTextStyles.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cart',
            onPressed: () => context.push('/cart'),
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(116),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) => setState(() {
                    _query = value.trim();
                    _future = _load();
                  }),
                  decoration: InputDecoration(
                    hintText: 'Search products',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _query = '';
                                _future = _load();
                              });
                            },
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _CategoryChips(
                  future: _categoriesFuture,
                  selected: _category,
                  onChanged: _setCategory,
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<Cached<List<Product>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView(message: 'Loading products…');
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.6,
                    child: ErrorView(
                      error: snapshot.error!,
                      onRetry: () => setState(() => _future = _load()),
                    ),
                  ),
                ],
              );
            }

            final result = snapshot.data;
            final products = result?.data ?? const <Product>[];

            if (products.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.6,
                    child: EmptyStateView(
                      icon: Icons.storefront_outlined,
                      title: 'No products found',
                      message: _query.isNotEmpty
                          ? 'Nothing matches "$_query".'
                          : 'Try another category.',
                      actionLabel: 'Clear filters',
                      onAction: () {
                        _searchController.clear();
                        setState(() {
                          _query = '';
                          _category = null;
                          _future = _load();
                        });
                      },
                    ),
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xxxl,
              ),
              children: [
                if (result != null && result.fromCache) ...[
                  const InfoBanner(
                    message: 'Showing cached products.',
                    tone: InfoBannerTone.warning,
                    icon: Icons.cloud_off_rounded,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                for (final product in products)
                  _ProductCard(
                    product: product,
                    onView: () => context.push('/store/product/${product.id}'),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.future,
    required this.selected,
    required this.onChanged,
  });

  final Future<List<String>> future;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: future,
      builder: (context, snapshot) {
        final categories = snapshot.data ?? const <String>[];
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All Products'),
                selected: selected == null,
                onSelected: (_) => onChanged(null),
              ),
              for (final category in categories) ...[
                const SizedBox(width: AppSpacing.sm),
                ChoiceChip(
                  label: Text(category),
                  selected: selected == category,
                  onSelected: (_) => onChanged(category),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onView});

  final Product product;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      onTap: onView,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.input),
              color: scheme.primary.withValues(alpha: 0.08),
            ),
            child: Icon(
              Icons.checkroom_rounded,
              color: scheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.currency} ${product.price.toStringAsFixed(0)}',
                  style: AppTextStyles.price,
                ),
                const SizedBox(height: AppSpacing.xs),
                StatusBadge(
                  label: product.isInStock ? 'In stock' : 'Sold out',
                  tone: product.isInStock
                      ? StatusTone.success
                      : StatusTone.danger,
                  dense: true,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
