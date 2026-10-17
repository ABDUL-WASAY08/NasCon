import 'package:flutter/foundation.dart';

/// A single recent-item / activity entry (used by the Home tab).
@immutable
class Activity {
  const Activity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.status = ActivityStatus.completed,
    this.amount,
  });

  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final ActivityStatus status;
  final double? amount;

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    subtitle: json['subtitle'] as String? ?? '',
    timestamp:
        DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    status: ActivityStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => ActivityStatus.completed,
    ),
    amount: (json['amount'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'timestamp': timestamp.toIso8601String(),
    'status': status.name,
    'amount': amount,
  };
}

/// Lifecycle of an activity entry.
enum ActivityStatus { completed, pending, failed }
