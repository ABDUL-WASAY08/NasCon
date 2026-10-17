import 'package:flutter/material.dart';

import '../../../models/activity.dart';
import '../../../core/theme/app_colors.dart';

/// A single KPI shown in the dashboard overview.
@immutable
class SummaryStat {
  const SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.delta,
    required this.color,
    this.isPositive = true,
  });

  final String label;
  final String value;
  final IconData icon;
  final String delta;
  final Color color;
  final bool isPositive;
}

/// A quick action shown in the dashboard.
@immutable
class QuickAction {
  const QuickAction({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

/// Dummy overview KPIs.
const List<SummaryStat> kSummaryStats = [
  SummaryStat(
    label: 'Active Tasks',
    value: '12',
    icon: Icons.checklist_rounded,
    delta: '+12%',
    color: AppColors.primary,
  ),
  SummaryStat(
    label: 'Total Balance',
    value: r'$8,420',
    icon: Icons.account_balance_wallet_rounded,
    delta: '+8.4%',
    color: AppColors.secondary,
  ),
  SummaryStat(
    label: 'Completed Items',
    value: '86',
    icon: Icons.task_alt_rounded,
    delta: '+3.2%',
    color: AppColors.success,
  ),
  SummaryStat(
    label: 'System Metrics',
    value: '99.9%',
    icon: Icons.speed_rounded,
    delta: '-0.4%',
    color: AppColors.warning,
    isPositive: false,
  ),
];

/// Dummy quick actions.
const List<QuickAction> kQuickActions = [
  QuickAction(
    label: 'Add New',
    icon: Icons.add_rounded,
    color: AppColors.primary,
  ),
  QuickAction(
    label: 'Analytics',
    icon: Icons.bar_chart_rounded,
    color: AppColors.secondary,
  ),
  QuickAction(
    label: 'Transfer',
    icon: Icons.swap_horiz_rounded,
    color: AppColors.info,
  ),
  QuickAction(
    label: 'Reports',
    icon: Icons.description_rounded,
    color: AppColors.warning,
  ),
];

/// Dummy recent-activity feed.
final List<Activity> kRecentActivities = [
  Activity(
    id: '1',
    title: 'Payment received',
    subtitle: 'From Acme Corp',
    timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
    status: ActivityStatus.completed,
    amount: 1200,
  ),
  Activity(
    id: '2',
    title: 'New task assigned',
    subtitle: 'Design review',
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    status: ActivityStatus.pending,
  ),
  Activity(
    id: '3',
    title: 'Transfer failed',
    subtitle: 'Insufficient funds',
    timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    status: ActivityStatus.failed,
    amount: 340,
  ),
  Activity(
    id: '4',
    title: 'Report generated',
    subtitle: 'Q3 analytics',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    status: ActivityStatus.completed,
  ),
  Activity(
    id: '5',
    title: 'Profile updated',
    subtitle: 'Security settings',
    timestamp: DateTime.now().subtract(const Duration(days: 2)),
    status: ActivityStatus.completed,
  ),
  Activity(
    id: '6',
    title: 'Invoice paid',
    subtitle: 'Northgate Motors',
    timestamp: DateTime.now().subtract(const Duration(days: 3)),
    status: ActivityStatus.pending,
    amount: 85,
  ),
];
