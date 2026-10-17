import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../models/user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// The dashboard's header: profile avatar (with an active-status badge), the
/// greeting, a notification bell carrying a badge, and a settings action.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.user,
    required this.greeting,
    required this.subtitle,
    required this.notificationCount,
    required this.onNotifications,
    required this.onSettings,
    required this.onAvatarTap,
  });

  final User user;
  final String greeting;
  final String subtitle;
  final int notificationCount;
  final VoidCallback onNotifications;
  final VoidCallback onSettings;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        GestureDetector(
          onTap: onAvatarTap,
          child: _AvatarWithStatus(initials: user.initials),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        _HeaderIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notifications',
          badgeCount: notificationCount,
          onTap: onNotifications,
        ),
        const SizedBox(width: AppSpacing.sm),
        _HeaderIconButton(
          icon: Icons.settings_outlined,
          tooltip: 'Settings',
          onTap: onSettings,
        ),
      ],
    );
  }
}

class _AvatarWithStatus extends StatelessWidget {
  const _AvatarWithStatus({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 54,
          height: 54,
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
              style: AppTextStyles.button.copyWith(color: Colors.white),
            ),
          ),
        ),
        Positioned(
          right: 2,
          bottom: 2,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.scaffoldBackgroundColor,
            ),
            child: Center(
              child: Container(
                width: 11,
                height: 11,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(14);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
            side: BorderSide(color: scheme.outline),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(icon, size: 22, color: scheme.onSurface),
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            top: 5,
            right: 5,
            child: Container(
              constraints: const BoxConstraints(minWidth: 17),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.scaffoldBackgroundColor,
                  width: 1.5,
                ),
              ),
              child: Text(
                '$badgeCount',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontSize: 9,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
