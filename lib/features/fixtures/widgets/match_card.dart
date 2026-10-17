import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../models/fixture.dart';

/// Maps a match status onto the shared badge tones.
StatusTone toneForMatchStatus(MatchStatus status) => switch (status) {
  MatchStatus.live => StatusTone.danger,
  MatchStatus.completed => StatusTone.success,
  MatchStatus.scheduled => StatusTone.info,
  MatchStatus.postponed => StatusTone.warning,
  MatchStatus.cancelled => StatusTone.neutral,
  MatchStatus.unknown => StatusTone.neutral,
};

/// A fixture summary card used in the Fixtures list and Home.
class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.fixture, required this.onTap});

  final Fixture fixture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return CustomCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StatusBadge(
                label: fixture.status.label,
                tone: toneForMatchStatus(fixture.status),
                dense: true,
                icon: fixture.isLive ? Icons.circle : null,
              ),
              const Spacer(),
              Text(
                _kickoffLabel(fixture),
                style: AppTextStyles.helper.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _TeamColumn(
                  team: fixture.homeTeam,
                  alignEnd: false,
                  trailingScore: fixture.hasScore ? fixture.homeScore : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'VS',
                  style: AppTextStyles.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: _TeamColumn(
                  team: fixture.awayTeam,
                  alignEnd: true,
                  trailingScore: fixture.hasScore ? fixture.awayScore : null,
                ),
              ),
            ],
          ),
          if (fixture.venue != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: AppSizes.iconSm,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    fixture.venue!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.helper.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: AppSizes.iconMd,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _kickoffLabel(Fixture fixture) {
    final local = fixture.kickoff.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${months[local.month - 1]} • $hour:$minute';
  }
}

class _TeamColumn extends StatelessWidget {
  const _TeamColumn({
    required this.team,
    required this.alignEnd,
    this.trailingScore,
  });

  final TeamRef team;
  final bool alignEnd;
  final int? trailingScore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary.withValues(alpha: 0.1),
            border: Border.all(color: scheme.outline),
          ),
          child: Center(
            child: Text(
              team.initials,
              style: AppTextStyles.label.copyWith(color: scheme.primary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          team.displayName,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
        if (trailingScore != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$trailingScore',
            style: AppTextStyles.h2.copyWith(color: AppColors.primary),
          ),
        ],
      ],
    );
  }
}
