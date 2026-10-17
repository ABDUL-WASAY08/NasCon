import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../errors/error_mapper.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A recoverable error state with a retry affordance.
///
/// The raw exception is never shown — [ErrorMapper] decides the message.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.retryLabel = 'Try again',
  });

  final Object error;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canRetry = onRetry != null && ErrorMapper.isRetryable(error);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.semantic.dangerContainer,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 34,
                color: context.semantic.onDangerContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              ErrorMapper.messageFor(error),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (canRetry) ...[
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: AppSizes.iconMd),
                label: Text(retryLabel),
              ),
            ] else if (ErrorMapper.isSessionExpired(error)) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Please sign in again to continue.',
                style: AppTextStyles.helper.copyWith(color: AppColors.warning),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
