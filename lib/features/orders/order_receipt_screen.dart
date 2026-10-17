import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/order.dart';
import '../../../repositories/repository_providers.dart';
import 'receipt_pdf.dart';

/// Screen 06e — Order receipt.
class OrderReceiptScreen extends ConsumerStatefulWidget {
  const OrderReceiptScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderReceiptScreen> createState() =>
      _OrderReceiptScreenState();
}

class _OrderReceiptScreenState extends ConsumerState<OrderReceiptScreen> {
  bool _generating = false;

  /// Builds the PDF and hands it to the platform. Reports real failures — it
  /// never claims a download succeeded when it did not.
  Future<void> _downloadPdf(Order order) async {
    if (_generating) return;
    setState(() => _generating = true);
    try {
      final bytes = await ReceiptPdf.build(order);
      await Printing.layoutPdf(
        name: 'nascon-receipt-${order.id}.pdf',
        onLayout: (_) => bytes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Receipt PDF ready (${bytes.length} bytes).')),
        );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(ErrorMapper.messageFor(error))),
        );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Order Receipt',
        showBackButton: false,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<Order>(
        future: ref.read(ordersRepositoryProvider).order(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(message: 'Retrieving your order…');
          }
          if (snapshot.hasError) {
            return ErrorView(
              error: snapshot.error!,
              onRetry: () => setState(() {}),
            );
          }

          final order = snapshot.data;
          if (order == null) {
            return const EmptyStateView(
              icon: Icons.receipt_long_outlined,
              title: 'Order not found',
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
              CustomCard(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.semantic.successContainer,
                      ),
                      child: Icon(
                        order.isConfirmed
                            ? Icons.check_rounded
                            : Icons.hourglass_bottom_rounded,
                        color: context.semantic.onSuccessContainer,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      order.isConfirmed
                          ? 'Order confirmed'
                          : 'Order ${order.status.label.toLowerCase()}',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Order ${order.id}',
                      style: AppTextStyles.helper.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    StatusBadge(
                      label: order.paymentStatus.label,
                      tone: order.paymentStatus == PaymentStatus.paid
                          ? StatusTone.success
                          : StatusTone.warning,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Items'),
              CustomCard(
                child: Column(
                  children: [
                    for (final item in order.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.variantName == null
                                    ? item.productName
                                    : '${item.productName} '
                                          '(${item.variantName})',
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
                              '${item.currency} '
                              '${item.lineTotal.toStringAsFixed(2)}',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    const Divider(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(child: Text('Total', style: AppTextStyles.h3)),
                        Text(
                          '${order.currency} ${order.total.toStringAsFixed(2)}',
                          style: AppTextStyles.h3,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              CustomButton(
                text: 'Download PDF Receipt',
                icon: Icons.download_rounded,
                isOutlined: true,
                isLoading: _generating,
                onPressed: () => _downloadPdf(order),
              ),
              const SizedBox(height: AppSpacing.md),
              CustomButton(
                text: 'Continue Shopping',
                icon: Icons.storefront_rounded,
                onPressed: () => context.go('/store'),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(
                  'Payment reference: ${order.paymentReference ?? '—'}',
                  style: AppTextStyles.helper.copyWith(
                    color: AppColors.lightTextMuted,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
