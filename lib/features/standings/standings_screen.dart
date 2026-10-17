import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/league.dart';
import '../../../models/standings_row.dart';
import '../../../repositories/repository_providers.dart';
import '../../../repositories/repository_types.dart';

/// Screen 04 — Standings.
class StandingsScreen extends ConsumerStatefulWidget {
  const StandingsScreen({super.key});

  @override
  ConsumerState<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends ConsumerState<StandingsScreen> {
  String? _leagueId;
  late Future<Cached<List<StandingsRow>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Cached<List<StandingsRow>>> _load({bool forceRefresh = false}) => ref
      .read(standingsRepositoryProvider)
      .standings(_leagueId, forceRefresh: forceRefresh);

  Future<void> _refresh() async {
    final future = _load(forceRefresh: true);
    setState(() => _future = future);
    await future.catchError(
      (Object _) => const Cached<List<StandingsRow>>(data: []),
    );
  }

  void _setLeague(String? leagueId) {
    if (_leagueId == leagueId) return;
    setState(() {
      _leagueId = leagueId;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'League Standings',
        subtitle: "Track your team's progress",
        showBackButton: false,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
            child: _LeagueDropdown(
              selected: _leagueId,
              onChanged: _setLeague,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<Cached<List<StandingsRow>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView(message: 'Loading standings…');
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.6,
                    child: ErrorView(
                      error: snapshot.error!,
                      onRetry: () => setState(() => _future = _load()),
                    ),
                  ),
                ],
              );
            }

            final result = snapshot.data;
            final rows = result?.data ?? const <StandingsRow>[];

            if (rows.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.6,
                    child: const EmptyStateView(
                      icon: Icons.leaderboard_outlined,
                      title: 'No standings yet',
                      message:
                          'The table will appear once results are published.',
                    ),
                  ),
                ],
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
                if (result != null && result.fromCache) ...[
                  const InfoBanner(
                    message: 'Showing cached standings.',
                    tone: InfoBannerTone.warning,
                    icon: Icons.cloud_off_rounded,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (result?.updatedAt != null) ...[
                  Text(
                    'Last updated ${_timeLabel(result!.updatedAt!)}',
                    style: AppTextStyles.helper.copyWith(
                      color: context.semantic.muted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _StandingsTable(rows: rows),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _timeLabel(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month} $hour:$minute';
  }
}

class _LeagueDropdown extends ConsumerWidget {
  const _LeagueDropdown({required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Cached<List<League>>>(
      future: ref.read(standingsRepositoryProvider).leagues(),
      builder: (context, snapshot) {
        final leagues = snapshot.data?.data ?? const <League>[];
        if (leagues.isEmpty) return const SizedBox.shrink();
        return DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: selected,
            isExpanded: true,
            hint: Text('Select league', style: AppTextStyles.bodySmall),
            items: [
              for (final league in leagues)
                DropdownMenuItem<String?>(
                  value: league.id,
                  child: Text(league.name, style: AppTextStyles.bodySmall),
                ),
            ],
            onChanged: onChanged,
          ),
        );
      },
    );
  }
}

class _StandingsTable extends StatelessWidget {
  const _StandingsTable({required this.rows});

  final List<StandingsRow> rows;

  static const double _posWidth = 44;
  static const double _teamWidth = 168;
  static const double _statWidth = 56;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return CustomCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                _headerCell('POS', _posWidth, scheme.onSurfaceVariant),
                _headerCell('TEAM', _teamWidth, scheme.onSurfaceVariant),
                _headerCell('P', _statWidth, scheme.onSurfaceVariant),
                _headerCell('W', _statWidth, scheme.onSurfaceVariant),
                _headerCell('L', _statWidth, scheme.onSurfaceVariant),
                _headerCell('PTS', _statWidth, scheme.onSurfaceVariant),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final row in rows) _row(context, row),
        ],
      ),
    );
  }

  Widget _headerCell(String label, double width, Color color) => SizedBox(
    width: width,
    child: Text(
      label,
      style: AppTextStyles.tableHeading.copyWith(color: color),
    ),
  );

  Widget _row(BuildContext context, StandingsRow row) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.push('/clubs/${row.teamId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Semantics(
          label:
              'Position ${row.position}, ${row.teamName}, '
              'played ${row.played ?? '-'}, won ${row.won ?? '-'}, '
              'lost ${row.lost ?? '-'}, points ${row.points ?? '-'}',
          button: true,
          child: Row(
            children: [
              SizedBox(
                width: _posWidth,
                child: Text('${row.position}', style: AppTextStyles.label),
              ),
              SizedBox(
                width: _teamWidth,
                child: Row(
                  children: [
                    if (row.qualification != null) ...[
                      _QualificationDot(status: row.qualification!),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: Text(
                        row.teamName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _stat(row.played),
              _stat(row.won),
              _stat(row.lost),
              SizedBox(
                width: _statWidth,
                child: Text(
                  '${row.points ?? '-'}',
                  style: AppTextStyles.label.copyWith(color: scheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(int? value) => SizedBox(
    width: _statWidth,
    child: Text('${value ?? '-'}', style: AppTextStyles.bodyMedium),
  );
}

/// A colour + tooltip cue for a qualification state. Never the only signal —
/// the tooltip carries the meaning.
class _QualificationDot extends StatelessWidget {
  const _QualificationDot({required this.status});

  final QualificationStatus status;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final color = switch (status) {
      QualificationStatus.qualified => semantic.onSuccessContainer,
      QualificationStatus.inContention => semantic.onWarningContainer,
      QualificationStatus.eliminated => semantic.onDangerContainer,
      QualificationStatus.unknown => semantic.muted,
    };
    return Tooltip(
      message: status.label,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
