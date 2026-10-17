import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/sync_queue_entry.dart';
import '../../../repositories/repository_providers.dart';

/// Screen 09 — Sync Status.
///
/// Reflects the real persisted queue and the real result of each sync attempt.
/// Connectivity is shown separately from sync success.
class SyncStatusScreen extends ConsumerStatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  ConsumerState<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends ConsumerState<SyncStatusScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncQueueProvider.notifier).load();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _syncNow() => _run(() async {
    final summary = await ref.read(syncQueueProvider.notifier).syncNow();
    if (!mounted || summary == null) return;
    final suffix = summary.hadFailures ? ' — some need attention.' : '.';
    _snack(
      summary.attempted == 0
          ? 'Nothing to sync.'
          : 'Synced ${summary.succeeded} of ${summary.attempted}$suffix',
    );
  });

  Future<void> _retryFailed() => _run(() async {
    final summary = await ref.read(syncQueueProvider.notifier).retryFailed();
    if (!mounted || summary == null) return;
    _snack(
      summary.attempted == 0
          ? 'Nothing safe to retry.'
          : 'Retried ${summary.attempted}; ${summary.succeeded} succeeded.',
    );
  });

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(syncQueueProvider);
    final online = ref.watch(connectivityStatusProvider).valueOrNull ?? true;
    final entries = queue.value ?? const <SyncQueueEntry>[];

    final pending = entries.where((e) => e.state == SyncState.pending).length;
    final syncing = entries.where((e) => e.state == SyncState.syncing).length;
    final synced = entries.where((e) => e.state == SyncState.synced).length;
    final failed = entries.where((e) => e.state == SyncState.failed).length;
    final needsHuman = entries.where((e) => e.state.needsHuman).length;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Sync Status',
        subtitle: 'Manage offline changes',
        showBackButton: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: queue.isLoading
                ? null
                : () => ref.read(syncQueueProvider.notifier).load(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(syncQueueProvider.notifier).load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xxxl,
          ),
          children: [
            _ConnectionCard(
              online: online,
              busy: _busy,
              pending: pending + failed,
              lastSyncedAt: ref.read(syncQueueProvider.notifier).lastSyncedAt,
              onSyncNow: pending + failed == 0 ? null : _syncNow,
              onRetryFailed: failed == 0 ? null : _retryFailed,
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Queue summary'),
            _SummaryGrid(
              pending: pending,
              syncing: syncing,
              synced: synced,
              failed: failed,
              needsReview: needsHuman,
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(
              title: 'Queued actions',
              subtitle: entries.isEmpty
                  ? null
                  : '${entries.length} total, newest last',
            ),
            if (queue.isLoading && entries.isEmpty)
              const LoadingView(message: 'Reading the queue…')
            else if (entries.isEmpty)
              const EmptyStateView(
                icon: Icons.cloud_done_outlined,
                title: 'Nothing queued',
                message: 'Offline scoring and roster changes appear here.',
              )
            else
              for (final entry in entries.reversed)
                _QueueTile(
                  entry: entry,
                  onDetails: () => _showDetails(entry),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDetails(SyncQueueEntry entry) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _QueueDetails(entry: entry),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.online,
    required this.busy,
    required this.pending,
    required this.lastSyncedAt,
    required this.onSyncNow,
    required this.onRetryFailed,
  });

  final bool online;
  final bool busy;
  final int pending;
  final DateTime? lastSyncedAt;
  final VoidCallback? onSyncNow;
  final VoidCallback? onRetryFailed;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final (label, tone, icon) = !online
        ? ('Offline', StatusTone.warning, Icons.cloud_off_rounded)
        : pending > 0
        ? ('Pending changes', StatusTone.info, Icons.sync_problem_rounded)
        : ('Up to date', StatusTone.success, Icons.cloud_done_rounded);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: context.colorOf(tone), size: AppSizes.iconLg),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.h3),
                    const SizedBox(height: 2),
                    Text(
                      online
                          ? 'Device is online'
                          : 'Changes are stored on this device',
                      style: AppTextStyles.helper.copyWith(
                        color: semantic.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            lastSyncedAt == null
                ? 'No successful sync yet.'
                : 'Last successful sync: ${lastSyncedAt!.toLocal()}',
            style: AppTextStyles.helper.copyWith(color: semantic.muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Sync Now',
                  icon: Icons.sync_rounded,
                  isLoading: busy,
                  onPressed: onSyncNow,
                  height: AppSizes.buttonHeightSmall,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: CustomButton(
                  text: 'Retry Failed',
                  isOutlined: true,
                  onPressed: busy ? null : onRetryFailed,
                  height: AppSizes.buttonHeightSmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension on BuildContext {
  Color colorOf(StatusTone tone) => switch (tone) {
    StatusTone.success => AppColors.success,
    StatusTone.warning => AppColors.warning,
    StatusTone.danger => AppColors.error,
    StatusTone.info => AppColors.info,
    StatusTone.neutral => semantic.muted,
  };
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.pending,
    required this.syncing,
    required this.synced,
    required this.failed,
    required this.needsReview,
  });

  final int pending;
  final int syncing;
  final int synced;
  final int failed;
  final int needsReview;

  @override
  Widget build(BuildContext context) {
    final counts = <(String, int, StatusTone)>[
      ('Pending', pending, StatusTone.info),
      ('Syncing', syncing, StatusTone.info),
      ('Synced', synced, StatusTone.success),
      ('Failed', failed, StatusTone.danger),
      ('Needs review', needsReview, StatusTone.warning),
    ];

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final (label, value, tone) in counts)
          SizedBox(
            width: 112,
            child: CustomCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$value', style: AppTextStyles.h3),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: AppTextStyles.helper.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  StatusBadge(label: label, tone: tone, dense: true),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({required this.entry, required this.onDetails});

  final SyncQueueEntry entry;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final tone = switch (entry.state) {
      SyncState.synced => StatusTone.success,
      SyncState.failed => StatusTone.danger,
      SyncState.conflict || SyncState.needsReview => StatusTone.warning,
      _ => StatusTone.info,
    };

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      onTap: onDetails,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.description, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  '${entry.createdAt.toLocal()}'
                  '${entry.attempts > 0 ? ' • ${entry.attempts} attempt(s)' : ''}',
                  style: AppTextStyles.helper.copyWith(
                    color: context.semantic.muted,
                  ),
                ),
                if (entry.lastError != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    entry.lastError!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.helper.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusBadge(label: entry.state.label, tone: tone, dense: true),
        ],
      ),
    );
  }
}

class _QueueDetails extends StatelessWidget {
  const _QueueDetails({required this.entry});

  final SyncQueueEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(entry.description, style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.lg),
            _row(context, 'Action id', entry.id),
            _row(context, 'Entity', entry.entityId),
            _row(context, 'State', entry.state.label),
            _row(context, 'Created', entry.createdAt.toLocal().toString()),
            _row(context, 'Attempts', '${entry.attempts}'),
            if (entry.baseVersion != null)
              _row(context, 'Base version', entry.baseVersion!),
            if (entry.lastError != null)
              _row(context, 'Last error', entry.lastError!),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Payload',
              style: AppTextStyles.label.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.semantic.neutralContainer,
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
              child: Text(
                entry.payload.entries
                    .map((e) => '${e.key}: ${e.value}')
                    .join('\n'),
                style: AppTextStyles.helper,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: Text(
            label,
            style: AppTextStyles.helper.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value, style: AppTextStyles.bodySmall)),
      ],
    ),
  );
}
