import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/user.dart';
import '../../../repositories/repository_providers.dart';
import '../dashboard/data/dashboard_mock_data.dart';
import '../dashboard/presentation/widgets/activity_tile.dart';
import '../dashboard/presentation/widgets/dashboard_header.dart';
import '../dashboard/presentation/widgets/summary_card.dart';

/// The Home tab — the retained at-a-glance dashboard.
///
/// Rendered as a tab body (no Scaffold of its own): the app shell owns the
/// navigation chrome. Figures come from the retained dashboard demo dataset and
/// are labelled as demo data while the mock backend is active.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isMock = ref.watch(appConfigProvider).useMockBackend;

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const gap = AppSpacing.lg;
          final available = constraints.maxWidth - AppSpacing.xl * 2;
          final columns = constraints.maxWidth >= 1080
              ? 4
              : constraints.maxWidth >= 680
              ? 2
              : 1;
          final cardWidth = columns == 1
              ? available
              : (available - gap * (columns - 1)) / columns;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xxxl,
            ),
            children: [
              DashboardHeader(
                user: user ??
                    const User(
                      id: 'guest',
                      fullName: 'Guest',
                      email: '',
                      role: UserRole.viewer,
                    ),
                greeting: 'Hello, ${_firstName(user)} 👋',
                subtitle: 'Here is your league overview',
                notificationCount: 0,
                onNotifications: () => _notify(
                  context,
                  'You have no new notifications.',
                ),
                onSettings: () => context.go('/profile'),
                onAvatarTap: () => context.go('/profile'),
              ),
              if (isMock) ...[
                const SizedBox(height: AppSpacing.lg),
                const InfoBanner(
                  message:
                      'Demo data — the NaSCon backend is not connected yet.',
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Jump to'),
              Row(
                children: [
                  _QuickTile(
                    icon: Icons.sports_soccer_rounded,
                    label: 'Fixtures',
                    onTap: () => context.go('/fixtures'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _QuickTile(
                    icon: Icons.leaderboard_rounded,
                    label: 'Standings',
                    onTap: () => context.go('/standings'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _QuickTile(
                    icon: Icons.storefront_rounded,
                    label: 'Store',
                    onTap: () => context.go('/store'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _QuickTile(
                    icon: Icons.cloud_sync_rounded,
                    label: 'Sync',
                    onTap: () => context.push('/sync-status'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Overview'),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final stat in kSummaryStats)
                    SizedBox(
                      width: cardWidth,
                      child: SummaryCard(stat: stat),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Recent Activity'),
              for (final activity in kRecentActivities)
                ActivityTile(activity: activity),
            ],
          );
        },
      ),
    );
  }

  static String _firstName(User? user) {
    final name = user?.fullName.trim() ?? '';
    if (name.isEmpty) return 'there';
    return name.split(RegExp(r'\s+')).first;
  }

  static void _notify(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: CustomCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.xs,
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.input),
                color: scheme.primary.withValues(alpha: 0.12),
              ),
              child: Icon(icon, size: 21, color: scheme.primary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}
