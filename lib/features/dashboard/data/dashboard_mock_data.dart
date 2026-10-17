import 'package:flutter/material.dart';

import '../../../core/models/activity.dart';
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

/// A quick action shown in the dashboard header.
@immutable
class QuickAction {
  const QuickAction({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Dummy overview KPIs.
const List<SummaryStat> kSummaryStats = [
  SummaryStat(
    label: 'Total bookings',
    value: '128',
    icon: Icons.calendar_month_rounded,
    delta: '+12%',
    color: AppColors.primary,
  ),
  SummaryStat(
    label: 'Active services',
    value: '24',
    icon: Icons.bolt_rounded,
    delta: '+4%',
    color: AppColors.secondary,
  ),
  SummaryStat(
    label: 'Revenue',
    value: r'$8.4k',
    icon: Icons.trending_up_rounded,
    delta: '+18%',
    color: AppColors.success,
  ),
  SummaryStat(
    label: 'Open tickets',
    value: '6',
    icon: Icons.confirmation_number_rounded,
    delta: '-3%',
    color: AppColors.warning,
    isPositive: false,
  ),
];

/// Dummy quick actions.
const List<QuickAction> kQuickActions = [
  QuickAction(label: 'Book', icon: Icons.add_rounded),
  QuickAction(label: 'Scan', icon: Icons.qr_code_scanner_rounded),
  QuickAction(label: 'Send', icon: Icons.send_rounded),
  QuickAction(label: 'More', icon: Icons.more_horiz_rounded),
];

/// Dummy recent-activity feed.
final List<Activity> kRecentActivities = [
  Activity(
    id: '1',
    title: 'Dental Checkup',
    subtitle: 'Dr. Reyes • Clinic A',
    timestamp: DateTime.now().subtract(const Duration(minutes: 42)),
    status: ActivityStatus.completed,
    amount: 120,
  ),
  Activity(
    id: '2',
    title: 'Car Service & Inspection',
    subtitle: 'Northgate Motors',
    timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    status: ActivityStatus.pending,
    amount: 340,
  ),
  Activity(
    id: '3',
    title: 'Home Cleaning',
    subtitle: 'BrightNest Team',
    timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    status: ActivityStatus.completed,
    amount: 85,
  ),
  Activity(
    id: '4',
    title: 'Gym Membership',
    subtitle: 'PulseFit Monthly',
    timestamp: DateTime.now().subtract(const Duration(days: 2)),
    status: ActivityStatus.failed,
    amount: 49,
  ),
  Activity(
    id: '5',
    title: 'Airport Transfer',
    subtitle: 'SwiftRide',
    timestamp: DateTime.now().subtract(const Duration(days: 3)),
    status: ActivityStatus.completed,
    amount: 60,
  ),
];
