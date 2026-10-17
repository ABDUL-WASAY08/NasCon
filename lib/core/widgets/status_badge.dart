import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Semantic meaning of a status badge.
enum StatusTone { neutral, success, warning, danger, info }

/// A small pill communicating a status.
///
/// Colour is never the only signal — the [label] (and optional [icon]) always
/// carry the meaning.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
    this.dense = false,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _colorsFor(context, tone);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.md,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.status.copyWith(
              color: foreground,
              fontSize: dense ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }

  static (Color, Color) _colorsFor(BuildContext context, StatusTone tone) {
    final semantic = context.semantic;
    return switch (tone) {
      StatusTone.success => (
        semantic.successContainer,
        semantic.onSuccessContainer,
      ),
      StatusTone.warning => (
        semantic.warningContainer,
        semantic.onWarningContainer,
      ),
      StatusTone.danger => (semantic.dangerContainer, semantic.onDangerContainer),
      StatusTone.info => (semantic.infoContainer, semantic.onInfoContainer),
      StatusTone.neutral => (semantic.neutralContainer, AppColors.lightTextSecondary),
    };
  }
}
