import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/fixture.dart';
import '../../../models/match_event.dart';
import '../../../models/scoring_action.dart';
import '../../../models/sync_queue_entry.dart';
import '../../../repositories/repository_providers.dart';
import '../../../repositories/repository_types.dart';

/// Screen 08 — Scoring Entry.
///
/// The form is driven entirely by the match's advertised scoring configuration,
/// so it is not tied to one sport. Offline submissions are queued durably and
/// shown as pending; a queued event is never presented as officially committed.
class ScoringScreen extends ConsumerStatefulWidget {
  const ScoringScreen({super.key, required this.matchId});

  final String matchId;

  @override
  ConsumerState<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends ConsumerState<ScoringScreen> {
  final _playerController = TextEditingController();
  final _minuteController = TextEditingController();
  final _noteController = TextEditingController();

  late Future<ScoringConfig> _configFuture;
  late Future<List<MatchEvent>> _eventsFuture;
  late Future<Cached<Fixture>> _fixtureFuture;

  ScoringEventTypeConfig? _eventType;
  String? _teamId;
  String? _period;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _configFuture = ref
        .read(fixturesRepositoryProvider)
        .scoringConfig(widget.matchId);
    _eventsFuture = ref.read(scoringRepositoryProvider).events(widget.matchId);
    _fixtureFuture = ref
        .read(fixturesRepositoryProvider)
        .fixture(widget.matchId);
  }

  @override
  void dispose() {
    _playerController.dispose();
    _minuteController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Validates the form and asks for explicit confirmation before submitting.
  Future<void> _review(Fixture fixture, ScoringConfig config) async {
    final eventType = _eventType;
    if (eventType == null) {
      _snack('Choose an event type.');
      return;
    }
    if (eventType.requiresPlayer && _playerController.text.trim().isEmpty) {
      _snack('A player is required for this event.');
      return;
    }
    if (eventType.requiresPeriod && (_period == null || _period!.isEmpty)) {
      _snack('Select a period for this event.');
      return;
    }
    if (_teamId == null) {
      _snack('Select the team this event belongs to.');
      return;
    }

    final confirmed = await showConfirmDialog(
      context,
      title: 'Confirm entry',
      message:
          'Add "${eventType.displayLabel}" for '
          '${_teamName(fixture, _teamId!)}'
          '${_playerController.text.trim().isEmpty ? '' : ' (${_playerController.text.trim()})'}?',
      confirmLabel: 'Confirm',
    );
    if (!confirmed || !mounted) return;

    await _submit(fixture, config, eventType);
  }

  Future<void> _submit(
    Fixture fixture,
    ScoringConfig config,
    ScoringEventTypeConfig eventType,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);

    final minute = int.tryParse(_minuteController.text.trim());
    final action = ScoringAction(
      id: const Uuid().v4(),
      matchId: widget.matchId,
      type: eventType.type,
      teamId: _teamId!,
      teamName: _teamName(fixture, _teamId!),
      playerName: _playerController.text.trim().isEmpty
          ? null
          : _playerController.text.trim(),
      points: eventType.defaultPoints,
      period: _period,
      minute: minute,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    try {
      final online = await ref.read(connectivityServiceProvider).isOnline();

      if (!online) {
        await ref
            .read(syncQueueProvider.notifier)
            .enqueue(
              actionType: SyncActionTypes.scoringEvent,
              entityId: widget.matchId,
              payload: action.toPayload(),
            );
        if (!mounted) return;
        _snack('Saved on this device — pending sync.');
        _clearForm();
        return;
      }

      await ref.read(scoringRepositoryProvider).submitEvent(action);
      if (!mounted) return;
      _snack('Event recorded.');
      _clearForm();
      setState(_reload);
    } catch (error) {
      if (!mounted) return;
      _snack(ErrorMapper.messageFor(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _clearForm() {
    _playerController.clear();
    _minuteController.clear();
    _noteController.clear();
    setState(() {
      _eventType = null;
      _period = null;
    });
  }

  static String _teamName(Fixture fixture, String teamId) =>
      teamId == fixture.homeTeam.id
      ? fixture.homeTeam.name
      : fixture.awayTeam.name;

  Future<void> _correct(MatchEvent event) async {
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Correct event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'A compensating correction is added; the original event is '
                'never edited or deleted.',
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Reason (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Submit correction'),
            ),
          ],
        );
      },
    );
    if (note == null || !mounted) return;

    try {
      await ref
          .read(scoringRepositoryProvider)
          .correctEvent(
            matchId: widget.matchId,
            eventId: event.id,
            type: event.type,
            note: note.isEmpty ? null : note,
          );
      if (!mounted) return;
      _snack('Correction recorded.');
      setState(_reload);
    } catch (error) {
      if (!mounted) return;
      _snack(ErrorMapper.messageFor(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Scoring Entry',
        subtitle: 'Match ${widget.matchId}',
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _busy ? null : () => setState(_reload),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<Cached<Fixture>>(
        future: _fixtureFuture,
        builder: (context, fixtureSnapshot) {
          return FutureBuilder<ScoringConfig>(
            future: _configFuture,
            builder: (context, configSnapshot) {
              if (fixtureSnapshot.connectionState == ConnectionState.waiting ||
                  configSnapshot.connectionState == ConnectionState.waiting) {
                return const LoadingView(message: 'Loading match setup…');
              }
              if (fixtureSnapshot.hasError) {
                return ErrorView(
                  error: fixtureSnapshot.error!,
                  onRetry: () => setState(_reload),
                );
              }
              if (configSnapshot.hasError) {
                return ErrorView(
                  error: configSnapshot.error!,
                  onRetry: () => setState(_reload),
                );
              }

              final fixture = fixtureSnapshot.data?.data;
              final config = configSnapshot.data;
              if (fixture == null || config == null) {
                return const EmptyStateView(
                  icon: Icons.sports_outlined,
                  title: 'Match unavailable',
                );
              }
              if (config.isEmpty) {
                return const EmptyStateView(
                  icon: Icons.tune_rounded,
                  title: 'Scoring not configured',
                  message:
                      'The backend has not supplied scoring rules for this '
                      'match.',
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.xxxl,
                ),
                children: [
                  if (fixture.hasScore)
                    CustomCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Confirmed score',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                          Text(
                            '${fixture.homeScore} – ${fixture.awayScore}',
                            style: AppTextStyles.h3,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(title: 'New event'),
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Event type', style: AppTextStyles.label),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final option in config.eventTypes)
                              ChoiceChip(
                                label: Text(option.displayLabel),
                                selected: _eventType?.type == option.type,
                                onSelected: (_) =>
                                    setState(() => _eventType = option),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text('Team', style: AppTextStyles.label),
                        const SizedBox(height: AppSpacing.sm),
                        SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                              value: fixture.homeTeam.id,
                              label: Text(
                                fixture.homeTeam.displayName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ButtonSegment(
                              value: fixture.awayTeam.id,
                              label: Text(
                                fixture.awayTeam.displayName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          selected: _teamId == null ? const {} : {_teamId!},
                          emptySelectionAllowed: true,
                          onSelectionChanged: (selection) => setState(
                            () => _teamId = selection.isEmpty
                                ? null
                                : selection.first,
                          ),
                        ),
                        if (config.periods.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.lg),
                          DropdownButtonFormField<String>(
                            initialValue: _period,
                            decoration: const InputDecoration(
                              labelText: 'Period',
                            ),
                            items: [
                              for (final period in config.periods)
                                DropdownMenuItem(
                                  value: period,
                                  child: Text(period),
                                ),
                            ],
                            onChanged: (value) =>
                                setState(() => _period = value),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          controller: _playerController,
                          decoration: InputDecoration(
                            labelText: _eventType?.requiresPlayer == true
                                ? 'Player (required)'
                                : 'Player (optional)',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          controller: _minuteController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Minute (optional)',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          controller: _noteController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Note (optional)',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        CustomButton(
                          text: 'Review & Confirm',
                          icon: Icons.fact_check_outlined,
                          isLoading: _busy,
                          onPressed: _busy
                              ? null
                              : () => _review(fixture, config),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader(title: 'Event history'),
                  FutureBuilder<List<MatchEvent>>(
                    future: _eventsFuture,
                    builder: (context, eventsSnapshot) {
                      if (eventsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const LoadingView();
                      }
                      if (eventsSnapshot.hasError) {
                        return ErrorView(error: eventsSnapshot.error!);
                      }
                      final events = eventsSnapshot.data ?? const <MatchEvent>[];
                      if (events.isEmpty) {
                        return const EmptyStateView(
                          icon: Icons.timeline_rounded,
                          title: 'No events yet',
                        );
                      }
                      return Column(
                        children: [
                          for (final event in events.reversed)
                            _EventRow(
                              event: event,
                              canCorrect: config.allowsCorrection &&
                                  event.status == EventStatus.confirmed,
                              onCorrect: () => _correct(event),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    config.allowsCorrection
                        ? 'Corrections are recorded as compensating events; '
                              'committed history is never edited.'
                        : 'This competition does not support corrections.',
                    style: AppTextStyles.helper.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.canCorrect,
    required this.onCorrect,
  });

  final MatchEvent event;
  final bool canCorrect;
  final VoidCallback onCorrect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.type.label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  [
                    event.teamName,
                    event.playerName,
                    event.period,
                    event.description,
                  ].whereType<String>().where((v) => v.isNotEmpty).join(' • '),
                  style: AppTextStyles.helper.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(
            label: event.status.label,
            tone: event.status == EventStatus.confirmed
                ? StatusTone.success
                : StatusTone.warning,
            dense: true,
          ),
          if (canCorrect)
            IconButton(
              tooltip: 'Correct this event',
              onPressed: onCorrect,
              icon: const Icon(Icons.edit_outlined, size: AppSizes.iconMd),
            ),
        ],
      ),
    );
  }
}
