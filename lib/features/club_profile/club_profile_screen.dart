import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/club.dart';
import '../../../models/player.dart';
import '../../../repositories/repository_providers.dart';
import '../../../repositories/repository_types.dart';

/// Screen 05 — Club Profile.
class ClubProfileScreen extends ConsumerWidget {
  const ClubProfileScreen({super.key, required this.clubId});

  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage = ref.watch(permissionsProvider).canManageRoster;
    final repo = ref.read(clubsRepositoryProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Club Profile'),
      body: FutureBuilder<Cached<Club>>(
        future: repo.club(clubId),
        builder: (context, clubSnapshot) {
          if (clubSnapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(message: 'Loading club…');
          }
          if (clubSnapshot.hasError) {
            return ErrorView(error: clubSnapshot.error!);
          }

          final result = clubSnapshot.data;
          final club = result?.data;
          if (club == null) {
            return const EmptyStateView(
              icon: Icons.shield_outlined,
              title: 'Club not found',
              message: 'This club is not available.',
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
                  message: 'Showing cached club information.',
                  tone: InfoBannerTone.warning,
                  icon: Icons.cloud_off_rounded,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              CustomCard(
                child: Column(
                  children: [
                    Container(
                      width: AppSizes.avatarLg,
                      height: AppSizes.avatarLg,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primary.withValues(alpha: 0.1),
                        border: Border.all(color: scheme.outline),
                      ),
                      child: Center(
                        child: Text(
                          club.initials,
                          style: AppTextStyles.h2.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      club.name,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h3,
                    ),
                    if (club.leagueId != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'League: ${club.leagueId}',
                        style: AppTextStyles.helper.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (club.description != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        club.description!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (club.stats != null) ...[
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'Statistics'),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    _Stat(
                      label: 'Played',
                      value: club.stats!.played?.toString(),
                    ),
                    _Stat(label: 'Won', value: club.stats!.won?.toString()),
                    _Stat(label: 'Lost', value: club.stats!.lost?.toString()),
                    _Stat(
                      label: 'Points',
                      value: club.stats!.points?.toString(),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (canManage)
                CustomButton(
                  text: 'Manage Roster',
                  icon: Icons.groups_2_outlined,
                  onPressed: () => context.push('/clubs/$clubId/roster'),
                ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Squad preview'),
              FutureBuilder<Cached<List<Player>>>(
                future: repo.roster(clubId),
                builder: (context, squadSnapshot) {
                  if (squadSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const LoadingView();
                  }
                  if (squadSnapshot.hasError) {
                    return ErrorView(error: squadSnapshot.error!);
                  }
                  final squad = squadSnapshot.data?.data ?? const <Player>[];
                  if (squad.isEmpty) {
                    return const EmptyStateView(
                      icon: Icons.person_off_outlined,
                      title: 'No squad listed',
                      message: 'The squad has not been published yet.',
                    );
                  }
                  return Column(
                    children: [
                      for (final player in squad)
                        _PlayerTile(player: player),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 104,
      child: CustomCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Text(value ?? '—', style: AppTextStyles.h3),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.helper.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = switch (player.status) {
      PlayerStatus.active => StatusTone.success,
      PlayerStatus.injured => StatusTone.danger,
      PlayerStatus.suspended => StatusTone.warning,
      PlayerStatus.unavailable => StatusTone.neutral,
      PlayerStatus.unknown => StatusTone.neutral,
    };

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text(
                player.jerseyNumber?.toString() ?? '–',
                style: AppTextStyles.label.copyWith(color: scheme.primary),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name, style: AppTextStyles.bodyMedium),
                Text(
                  [
                    player.position,
                    if (player.isOnLoan) 'On loan',
                  ].whereType<String>().join(' • '),
                  style: AppTextStyles.helper.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(label: player.status.label, tone: tone, dense: true),
        ],
      ),
    );
  }
}
