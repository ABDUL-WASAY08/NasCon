import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Centred progress indicator with an optional message.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 220,
              child: ShimmerLoadingWidgets(
                layout: ShimmerLayout.listTile,
                itemCount: 2,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum ShimmerLayout { listTile, matchCard, productCard, lineupRow }

/// Animated, theme-aware skeletons for loading lists and cards.
class ShimmerLoadingWidgets extends StatefulWidget {
  const ShimmerLoadingWidgets({
    super.key,
    this.layout = ShimmerLayout.listTile,
    this.itemCount = 3,
  }) : assert(itemCount > 0);

  final ShimmerLayout layout;
  final int itemCount;

  @override
  State<ShimmerLoadingWidgets> createState() => _ShimmerLoadingWidgetsState();
}

class _ShimmerLoadingWidgetsState extends State<ShimmerLoadingWidgets>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.onSurface.withValues(alpha: .055);
    final highlight = AppColors.primary.withValues(alpha: .12);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) {
          final shift = _controller.value * 2 - 1;
          return LinearGradient(
            begin: Alignment(shift - 1, 0),
            end: Alignment(shift + 1, 0),
            colors: [base, highlight, base],
            stops: const [0.25, 0.5, 0.75],
          ).createShader(bounds);
        },
        child: Column(
          children: [
            for (var index = 0; index < widget.itemCount; index++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: index == widget.itemCount - 1 ? 0 : AppSpacing.md,
                ),
                child: _skeleton(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _skeleton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget bar({double? width, double height = 12}) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );

    switch (widget.layout) {
      case ShimmerLayout.matchCard:
        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.onSurface.withValues(alpha: .08),
                  ),
                  const Spacer(),
                  bar(width: 58),
                  const Spacer(),
                  CircleAvatar(
                    backgroundColor: scheme.onSurface.withValues(alpha: .08),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              bar(width: 142, height: 18),
              const SizedBox(height: AppSpacing.sm),
              bar(width: 95, height: 10),
            ],
          ),
        );
      case ShimmerLayout.productCard:
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 126,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              bar(width: 130),
              const SizedBox(height: AppSpacing.sm),
              bar(width: 78),
            ],
          ),
        );
      case ShimmerLayout.lineupRow:
        return Row(
          children: [
            CircleAvatar(
              backgroundColor: scheme.onSurface.withValues(alpha: .08),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(width: 120),
                  const SizedBox(height: AppSpacing.sm),
                  bar(width: 74, height: 9),
                ],
              ),
            ),
            bar(width: 24),
          ],
        );
      case ShimmerLayout.listTile:
        return Row(
          children: [
            CircleAvatar(
              backgroundColor: scheme.onSurface.withValues(alpha: .08),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(width: 135),
                  const SizedBox(height: AppSpacing.sm),
                  bar(width: 90, height: 9),
                ],
              ),
            ),
            bar(width: 42),
          ],
        );
    }
  }
}
