import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../repositories/repository_providers.dart';

/// Supporting screen — Profile & Account.
///
/// Every value shown comes from the authenticated session; nothing is invented.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final permissions = ref.watch(permissionsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMock = ref.watch(appConfigProvider).useMockBackend;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Profile',
        showBackButton: false,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xxxl,
        ),
        children: [
          if (user == null)
            const EmptyStateView(
              icon: Icons.person_off_outlined,
              title: 'Not signed in',
              message: 'Sign in to view your profile.',
            )
          else ...[
            _IdentityCard(
              name: user.fullName,
              email: user.email,
              initials: user.initials,
              roleLabel: user.role.label,
              clubId: user.clubId,
              leagueId: user.leagueId,
            ),
            if (isMock) ...[
              const SizedBox(height: AppSpacing.md),
              const InfoBanner(
                message: 'Demo session — mock backend is active.',
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Capabilities'),
            CustomCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                children: [
                  _capability(context, 'Manage league', permissions.canManageLeague),
                  _capability(context, 'Manage roster', permissions.canManageRoster),
                  _capability(context, 'Enter scores', permissions.canEnterScore),
                  _capability(context, 'Manage store', permissions.canManageStore),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Preferences'),
            CustomCard(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                children: [
                  SwitchListTile(
                    value: isDark,
                    onChanged: (value) => ref
                        .read(themeModeProvider.notifier)
                        .setMode(value ? ThemeMode.dark : ThemeMode.light),
                    secondary: Icon(
                      Icons.dark_mode_outlined,
                      color: scheme.primary,
                    ),
                    title: Text('Dark mode', style: AppTextStyles.bodyMedium),
                    subtitle: Text(
                      themeMode == ThemeMode.system
                          ? 'Following the system setting'
                          : 'Set manually',
                      style: AppTextStyles.helper.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.cloud_sync_outlined,
                      color: scheme.primary,
                    ),
                    title: Text(
                      'Sync status',
                      style: AppTextStyles.bodyMedium,
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                    onTap: () => context.push('/sync-status'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            CustomButton(
              text: 'Sign out',
              isOutlined: true,
              icon: Icons.logout_rounded,
              onPressed: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  title: 'Sign out?',
                  message:
                      'You will need to sign in again. Any unsynced changes '
                      'stay on this device.',
                  confirmLabel: 'Sign out',
                  isDestructive: true,
                );
                if (!confirmed || !context.mounted) return;
                await ref.read(sessionProvider.notifier).signOut();
                if (context.mounted) context.go('/login');
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Text(
                'Version ${AppConstants.appVersion}',
                style: AppTextStyles.helper.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _capability(BuildContext context, String label, bool granted) => ListTile(
    dense: true,
    leading: Icon(
      granted ? Icons.check_circle_outline_rounded : Icons.lock_outline_rounded,
      color: granted ? AppColors.success : context.semantic.muted,
      size: AppSizes.iconMd,
    ),
    title: Text(label, style: AppTextStyles.bodyMedium),
    trailing: Text(
      granted ? 'Granted' : 'Not permitted',
      style: AppTextStyles.helper,
    ),
  );
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.name,
    required this.email,
    required this.initials,
    required this.roleLabel,
    this.clubId,
    this.leagueId,
  });

  final String name;
  final String email;
  final String initials;
  final String roleLabel;
  final String? clubId;
  final String? leagueId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomCard(
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.primaryGradient,
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTextStyles.h1.copyWith(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(name, style: AppTextStyles.h3, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(
            email,
            style: AppTextStyles.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          StatusBadge(label: roleLabel, tone: StatusTone.info),
          if (clubId != null || leagueId != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              [
                if (leagueId != null) 'League: $leagueId',
                if (clubId != null) 'Club: $clubId',
              ].join('   •   '),
              textAlign: TextAlign.center,
              style: AppTextStyles.helper.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
