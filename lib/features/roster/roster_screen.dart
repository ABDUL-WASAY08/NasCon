import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/club.dart';
import '../../../models/player.dart';
import '../../../models/roster_action.dart';
import '../../../models/sync_queue_entry.dart';
import '../../../repositories/repository_providers.dart';
import '../../../repositories/repository_types.dart';

/// Screen 07 — Roster Management.
///
/// Only offered to users the permission layer authorises. Actions are validated,
/// confirmed and reported honestly; when the device is offline they are queued
/// durably and shown as pending rather than reported as done.
class RosterScreen extends ConsumerStatefulWidget {
  const RosterScreen({super.key, required this.clubId});

  final String clubId;

  @override
  ConsumerState<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends ConsumerState<RosterScreen> {
  late Future<Cached<List<Player>>> _rosterFuture;
  late Future<RosterLimits> _limitsFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final repo = ref.read(clubsRepositoryProvider);
    _rosterFuture = repo.roster(widget.clubId, forceRefresh: true);
    _limitsFuture = repo.rosterLimits(widget.clubId);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _release(Player player) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Release ${player.name}?',
      message:
          'This removes ${player.name} from the squad. This cannot be undone '
          'from the app.',
      confirmLabel: 'Release',
      isDestructive: true,
    );
    if (!confirmed) return;

    await _submit(
      RosterAction(
        id: const Uuid().v4(),
        type: RosterActionType.release,
        clubId: widget.clubId,
        playerId: player.id,
        playerName: player.name,
      ),
    );
  }

  Future<void> _move(Player player, RosterActionType type) async {
    final destination = await showModalBottomSheet<Club>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _DestinationPicker(),
    );
    if (destination == null) return;
    if (!mounted) return;

    if (destination.id == widget.clubId) {
      _snack('Choose a different destination club.');
      return;
    }

    DateTime? returnDate;
    if (type == RosterActionType.loan) {
      returnDate = await showDatePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 730)),
        helpText: 'Select the loan return date',
      );
      if (returnDate == null) return;
    }

    await _submit(
      RosterAction(
        id: const Uuid().v4(),
        type: type,
        clubId: widget.clubId,
        playerId: player.id,
        playerName: player.name,
        destinationClubId: destination.id,
        returnDate: returnDate,
      ),
    );
  }

  Future<void> _submit(RosterAction action) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final online = await ref.read(connectivityServiceProvider).isOnline();

      if (!online) {
        await ref
            .read(syncQueueProvider.notifier)
            .enqueue(
              actionType: _actionType(action.type),
              entityId: action.clubId,
              payload: action.toPayload(),
            );
        if (!mounted) return;
        _snack('Saved on this device — ${action.summary} is pending sync.');
        return;
      }

      await ref.read(clubsRepositoryProvider).applyRosterAction(action);
      if (!mounted) return;
      _snack('${action.summary} applied.');
      setState(_reload);
    } catch (error) {
      if (!mounted) return;
      _snack(ErrorMapper.messageFor(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _actionType(RosterActionType type) => switch (type) {
    RosterActionType.add => SyncActionTypes.rosterAdd,
    RosterActionType.transfer => SyncActionTypes.rosterTransfer,
    RosterActionType.loan => SyncActionTypes.rosterLoan,
    RosterActionType.release => SyncActionTypes.rosterRelease,
  };

  @override
  Widget build(BuildContext context) {
    final canManage = ref.watch(permissionsProvider).canManageRoster;
    final scheme = Theme.of(context).colorScheme;

    if (!canManage) {
      return const Scaffold(
        body: SafeArea(
          child: EmptyStateView(
            icon: Icons.lock_outline_rounded,
            title: 'Not permitted',
            message: 'You do not have permission to manage this roster.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Roster Management',
        subtitle: 'Club squad',
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _busy ? null : () => setState(_reload),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          FutureBuilder<RosterLimits>(
            future: _limitsFuture,
            builder: (context, snapshot) {
              final limits = snapshot.data;
              if (limits == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  0,
                ),
                child: CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Squad ${limits.squadSize ?? '—'}'
                              '${limits.maxSquadSize != null ? ' / ${limits.maxSquadSize}' : ''}',
                              style: AppTextStyles.h3,
                            ),
                          ),
                          StatusBadge(
                            label: limits.canModifySquad
                                ? 'Transfer window open'
                                : 'Window closed',
                            tone: limits.canModifySquad
                                ? StatusTone.success
                                : StatusTone.warning,
                            dense: true,
                          ),
                        ],
                      ),
                      if (limits.positionRequirements.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          limits.positionRequirements.entries
                              .map((e) => '${e.key}: ${e.value}')
                              .join('  •  '),
                          style: AppTextStyles.helper.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (!limits.canModifySquad) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Squad changes are disabled until the transfer '
                          'window reopens.',
                          style: AppTextStyles.helper.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: FutureBuilder<Cached<List<Player>>>(
              future: _rosterFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingView(message: 'Loading squad…');
                }
                if (snapshot.hasError) {
                  return ErrorView(
                    error: snapshot.error!,
                    onRetry: () => setState(_reload),
                  );
                }
                final squad = snapshot.data?.data ?? const <Player>[];
                if (squad.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.groups_outlined,
                    title: 'No players',
                    message: 'This squad has no registered players.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.xxxl,
                  ),
                  itemCount: squad.length,
                  itemBuilder: (context, index) => _PlayerRow(
                    player: squad[index],
                    enabled: !_busy,
                    onTransfer: () =>
                        _move(squad[index], RosterActionType.transfer),
                    onLoan: () => _move(squad[index], RosterActionType.loan),
                    onRelease: () => _release(squad[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.enabled,
    required this.onTransfer,
    required this.onLoan,
    required this.onRelease,
  });

  final Player player;
  final bool enabled;
  final VoidCallback onTransfer;
  final VoidCallback onLoan;
  final VoidCallback onRelease;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text(
                player.jerseyNumber?.toString() ?? '–',
                style: AppTextStyles.label.copyWith(color: scheme.primary),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name, style: AppTextStyles.bodyMedium),
                Text(
                  [
                    player.position,
                    player.status.label,
                    if (player.isOnLoan) 'On loan',
                  ].whereType<String>().join(' • '),
                  style: AppTextStyles.helper.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            enabled: enabled && !player.isOnLoan,
            tooltip: 'Actions for ${player.name}',
            onSelected: (value) => switch (value) {
              'transfer' => onTransfer(),
              'loan' => onLoan(),
              'release' => onRelease(),
              _ => null,
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'transfer', child: Text('Transfer')),
              const PopupMenuItem(value: 'loan', child: Text('Loan')),
              PopupMenuItem(
                value: 'release',
                child: Text(
                  'Release',
                  style: TextStyle(color: scheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DestinationPicker extends ConsumerWidget {
  const _DestinationPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubs = ref.watch(clubsListProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Select destination club', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.md),
            if (clubs.isLoading)
              const LoadingView()
            else if (clubs.hasError)
              ErrorView(error: clubs.error!)
            else
              ...(clubs.value ?? const <Club>[]).map(
                (club) => ListTile(
                  title: Text(club.name, style: AppTextStyles.bodyMedium),
                  onTap: () => Navigator.of(context).pop(club),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
