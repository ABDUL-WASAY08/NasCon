import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final List<_NotificationItem> _items = _seedNotifications();
  bool _unreadOnly = false;

  int get _unreadCount => _items.where((item) => !item.read).length;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visible = _items.where((item) => !_unreadOnly || !item.read).toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Notifications',
        subtitle: _unreadCount == 0
            ? 'You’re all caught up'
            : '$_unreadCount unread updates',
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: () => setState(() {
                for (final item in _items) {
                  item.read = true;
                }
              }),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xxxl,
        ),
        children: [
          CustomCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            gradient: [
              scheme.primary.withValues(alpha: .13),
              scheme.secondary.withValues(alpha: .08),
            ],
            elevated: false,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(AppRadius.input),
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('League activity', style: AppTextStyles.label),
                      const SizedBox(height: 3),
                      Text(
                        'Match, club, and order updates in one place.',
                        style: AppTextStyles.helper.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: Text('Recent activity', style: AppTextStyles.h3)),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('All')),
                  ButtonSegment(value: true, label: Text('Unread')),
                ],
                selected: {_unreadOnly},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    setState(() => _unreadOnly = selection.first),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (visible.isEmpty)
            EmptyStateWidget(
              icon: Icons.mark_email_read_outlined,
              title: _unreadOnly ? 'All caught up' : 'No notifications yet',
              message: _unreadOnly
                  ? 'You have read all your updates.'
                  : 'New match and order updates will appear here.',
            )
          else
            for (final item in visible)
              _NotificationTile(
                key: ValueKey(item.id),
                item: item,
                onTap: () => setState(() => item.read = true),
              ),
        ],
      ),
    );
  }

  List<_NotificationItem> _seedNotifications() {
    final now = DateTime.now();
    return [
      _NotificationItem(
        id: 'activity-match-live',
        title: 'Match is underway',
        message: 'Quetta Bears vs Multan Sultans is live now.',
        time: now.subtract(const Duration(minutes: 8)),
        icon: Icons.sports_soccer_rounded,
        color: AppColors.error,
      ),
      _NotificationItem(
        id: 'activity-order',
        title: 'Order confirmed',
        message: 'Your NaSCon store order has been confirmed.',
        time: now.subtract(const Duration(hours: 2)),
        icon: Icons.shopping_bag_outlined,
        color: AppColors.secondary,
      ),
      _NotificationItem(
        id: 'activity-fixture',
        title: 'Upcoming fixture',
        message: 'Karachi Falcons take on Lahore Lions in Round 15.',
        time: now.subtract(const Duration(hours: 5)),
        icon: Icons.calendar_month_rounded,
        color: AppColors.primary,
        read: true,
      ),
      _NotificationItem(
        id: 'activity-standings',
        title: 'Standings updated',
        message: 'Karachi Falcons remain at the top of the table.',
        time: now.subtract(const Duration(days: 1)),
        icon: Icons.leaderboard_rounded,
        color: const Color(0xFFD97706),
        read: true,
      ),
    ];
  }
}

class _NotificationItem {
  _NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.color,
    this.read = false,
  });

  final String id;
  final String title;
  final String message;
  final DateTime time;
  final IconData icon;
  final Color color;
  bool read;
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({super.key, required this.item, required this.onTap});

  final _NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final elapsed = DateTime.now().difference(item.time);
    final timestamp = elapsed.inMinutes < 60
        ? '${elapsed.inMinutes} min ago'
        : elapsed.inHours < 24
        ? '${elapsed.inHours} hr ago'
        : '${elapsed.inDays} day${elapsed.inDays == 1 ? '' : 's'} ago';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        decoration: BoxDecoration(
          color: item.read
              ? Theme.of(context).cardColor
              : scheme.primary.withValues(alpha: .045),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: item.read
                ? scheme.outlineVariant
                : scheme.primary.withValues(alpha: .2),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(AppRadius.input),
                    ),
                    child: Icon(item.icon, color: item.color, size: 21),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: item.read
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                ),
                              ),
                            ),
                            if (!item.read)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: scheme.primary.withValues(
                                        alpha: .28,
                                      ),
                                      blurRadius: 7,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          item.message,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          timestamp,
                          style: AppTextStyles.caption.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
