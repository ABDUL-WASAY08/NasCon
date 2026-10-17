import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../profile/presentation/widgets/profile_view.dart';
import '../../data/dashboard_mock_data.dart';
import '../widgets/activity_tile.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/summary_card.dart';

/// The signed-in dashboard.
///
/// Frontend only, driven by dummy data. Navigation adapts to the viewport: a
/// [CurvedNavigationBar] + drawer on phones, a [NavigationRail] on wide
/// screens. The body is a scrollable `ListView` with a responsive `Wrap` for
/// the KPI cards.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const User _user = User(
    id: 'u_01',
    fullName: 'Alex Morgan',
    email: 'alex@nescom.app',
    role: 'admin',
  );

  static const List<_NavItem> _destinations = [
    _NavItem(label: 'Home', icon: Icons.grid_view_rounded),
    _NavItem(label: 'Activity', icon: Icons.receipt_long_rounded),
    _NavItem(label: 'Insights', icon: Icons.insights_rounded),
    _NavItem(label: 'Profile', icon: Icons.person_outline_rounded),
  ];

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  int _index = 0;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  void _onDestinationSelected(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
    );
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        title: 'Dashboard',
        subtitle: _greeting,
        showBackButton: false,
        automaticallyImplyLeading: false,
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Open navigation',
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
            onPressed: () => _notify('You have no new notifications.'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: GestureDetector(
              onTap: _openProfile,
              child: const _Avatar(initials: 'AM'),
            ),
          ),
        ],
      ),
      drawer: isWide ? null : _drawer(),
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              backgroundColor: theme.cardColor,
              destinations: [
                for (final item in _destinations)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    label: Text(item.label),
                  ),
              ],
            ),
          Expanded(child: IndexedStack(index: _index, children: _views())),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : CurvedNavigationBar(
              index: _index,
              height: 62,
              color: scheme.primary,
              buttonBackgroundColor: scheme.primary,
              backgroundColor: theme.scaffoldBackgroundColor,
              animationCurve: Curves.easeOutCubic,
              animationDuration: const Duration(milliseconds: 300),
              onTap: _onDestinationSelected,
              items: [
                for (final item in _destinations)
                  Icon(item.icon, size: 26, color: Colors.white),
              ],
            ),
    );
  }

  List<Widget> _views() => [
    _DashboardHome(
      user: _user,
      greeting: _greeting,
      onQuickAction: (action) => _notify('${action.label} tapped'),
    ),
    const _PlaceholderView(
      icon: Icons.receipt_long_rounded,
      title: 'Activity',
      message: 'Your full activity history will appear here.',
    ),
    const _PlaceholderView(
      icon: Icons.insights_rounded,
      title: 'Insights',
      message: 'Charts and analytics will appear here.',
    ),
    const ProfileView(),
  ];

  Widget _drawer() {
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  const _Avatar(initials: 'AM', size: 48),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_user.fullName, style: AppTextStyles.button),
                        Text(
                          _user.email,
                          overflow: TextOverflow.ellipsis,
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
            Divider(color: scheme.outline),
            for (var i = 0; i < _destinations.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                child: ListTile(
                  leading: Icon(
                    _destinations[i].icon,
                    color: i == _index
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                  title: Text(
                    _destinations[i].label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: i == _index ? scheme.primary : scheme.onSurface,
                      fontWeight: i == _index
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  selected: i == _index,
                  selectedTileColor: scheme.primary.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () => _onDestinationSelected(i),
                ),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: CustomButton(
                text: 'Sign out',
                icon: Icons.logout_rounded,
                isOutlined: true,
                height: 46,
                onPressed: () {
                  Navigator.of(context).pop();
                  _notify('Signed out (demo).');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome({
    required this.user,
    required this.greeting,
    required this.onQuickAction,
  });

  final User user;
  final String greeting;
  final ValueChanged<QuickAction> onQuickAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
            AppSpacing.xxl,
          ),
          children: [
            DashboardHeader(
              user: user,
              greeting: greeting,
              onQuickAction: onQuickAction,
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionTitle(title: 'Overview'),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final stat in kSummaryStats)
                  SizedBox(width: cardWidth, child: SummaryCard(stat: stat)),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionTitle(
              title: 'Recent activity',
              actionLabel: 'See all',
              onAction: () {},
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final activity in kRecentActivities)
              ActivityTile(activity: activity),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTextStyles.h3)),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _PlaceholderView extends StatelessWidget {
  const _PlaceholderView({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.1),
              ),
              child: Icon(icon, size: 34, color: scheme.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, this.size = 40});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
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
          style: AppTextStyles.label.copyWith(
            color: Colors.white,
            fontSize: size * 0.36,
          ),
        ),
      ),
    );
  }
}
