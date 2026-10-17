import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';

/// The profile content, shared by the standalone [ProfileScreen] and the
/// dashboard's Profile tab. Frontend only — no data layer.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key, this.user = _demoUser});

  static const User _demoUser = User(
    id: 'u_01',
    fullName: 'Alex Morgan',
    email: 'alex@nescom.app',
    role: 'admin',
  );

  final User user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomCard(
          gradient: AppColors.primaryGradient,
          borderColor: Colors.transparent,
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: Center(
                  child: Text(
                    user.initials,
                    style: AppTextStyles.h3.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: AppTextStyles.h3.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                tooltip: 'Edit profile',
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: const [
            Expanded(
              child: _Stat(label: 'Bookings', value: '128'),
            ),
            SizedBox(width: AppSpacing.lg),
            Expanded(child: _Stat(label: 'Reviews', value: '32')),
            SizedBox(width: AppSpacing.lg),
            Expanded(child: _Stat(label: 'Points', value: '2.4k')),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        CustomCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            children: [
              _settingTile(
                context,
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
              ),
              Divider(color: scheme.outline, height: 1),
              _settingTile(
                context,
                icon: Icons.palette_outlined,
                label: 'Appearance',
              ),
              Divider(color: scheme.outline, height: 1),
              _settingTile(
                context,
                icon: Icons.lock_outline_rounded,
                label: 'Privacy & security',
              ),
              Divider(color: scheme.outline, height: 1),
              _settingTile(
                context,
                icon: Icons.help_outline_rounded,
                label: 'Help & support',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        CustomButton(
          text: 'Sign out',
          isOutlined: true,
          icon: Icons.logout_rounded,
          onPressed: () {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text('Signed out (demo).')),
              );
          },
        ),
      ],
    );
  }

  Widget _settingTile(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.primary),
      title: Text(label, style: AppTextStyles.bodyMedium),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: scheme.onSurfaceVariant,
      ),
      onTap: () {},
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.h3),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
