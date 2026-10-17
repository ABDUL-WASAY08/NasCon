import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/fixture.dart';
import '../../../models/league.dart';
import '../../../repositories/repository_providers.dart';
import '../../../repositories/repository_types.dart';
import 'widgets/match_card.dart';

/// Screen 02 — Fixtures.
class FixturesScreen extends ConsumerStatefulWidget {
  const FixturesScreen({super.key});

  @override
  ConsumerState<FixturesScreen> createState() => _FixturesScreenState();
}

class _FixturesScreenState extends ConsumerState<FixturesScreen> {
  FixtureFilter _filter = FixtureFilter.all;
  String? _leagueId;
  late Future<Cached<List<Fixture>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Cached<List<Fixture>>> _load({bool forceRefresh = false}) =>
      ref
          .read(fixturesRepositoryProvider)
          .fixtures(
            leagueId: _leagueId,
            filter: _filter,
            forceRefresh: forceRefresh,
          );

  Future<void> _refresh() async {
    final future = _load(forceRefresh: true);
    setState(() => _future = future);
    await future.catchError((Object _) => const Cached<List<Fixture>>(data: []));
  }

  void _setFilter(FixtureFilter filter) {
    if (_filter == filter) return;
    setState(() {
      _filter = filter;
      _future = _load();
    });
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
        title: 'Fixtures',
        subtitle: 'Follow every match',
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
          preferredSize: const Size.fromHeight(108),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Filters(
                  selected: _filter,
                  onChanged: _setFilter,
                ),
                const SizedBox(height: AppSpacing.sm),
                _LeagueSelector(
                  selected: _leagueId,
                  onChanged: _setLeague,
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<Cached<List<Fixture>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView(message: 'Loading fixtures…');
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
            final fixtures = result?.data ?? const <Fixture>[];

            if (fixtures.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.6,
                    child: EmptyStateView(
                      icon: Icons.event_busy_rounded,
                      title: _emptyTitle,
                      message: _filter == FixtureFilter.all
                          ? 'No fixtures have been published yet.'
                          : 'Try a different filter.',
                      actionLabel: _filter == FixtureFilter.all
                          ? null
                          : 'Show all',
                      onAction: _filter == FixtureFilter.all
                          ? null
                          : () => _setFilter(FixtureFilter.all),
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
                  InfoBanner(
                    message: result.updatedAt == null
                        ? 'Showing cached fixtures.'
                        : 'Showing cached fixtures from '
                              '${_timeLabel(result.updatedAt!)}.',
                    tone: InfoBannerTone.warning,
                    icon: Icons.cloud_off_rounded,
                    actionLabel: 'Retry',
                    onAction: _refresh,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                for (final fixture in fixtures)
                  MatchCard(
                    fixture: fixture,
                    onTap: () => context.push('/matches/${fixture.id}'),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String get _emptyTitle => switch (_filter) {
    FixtureFilter.upcoming => 'No upcoming matches',
    FixtureFilter.live => 'Nothing live right now',
    FixtureFilter.completed => 'No completed matches',
    FixtureFilter.all => 'No fixtures',
  };

  static String _timeLabel(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.selected, required this.onChanged});

  final FixtureFilter selected;
  final ValueChanged<FixtureFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in FixtureFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(filter.label),
                selected: selected == filter,
                onSelected: (_) => onChanged(filter),
              ),
            ),
        ],
      ),
    );
  }
}

class _LeagueSelector extends ConsumerWidget {
  const _LeagueSelector({required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Cached<List<League>>>(
      future: ref.read(fixturesRepositoryProvider).leagues(),
      builder: (context, snapshot) {
        final leagues = snapshot.data?.data ?? const <League>[];
        if (leagues.length < 2) return const SizedBox.shrink();
        return SizedBox(
          height: 40,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: selected,
              isExpanded: true,
              hint: Text('All leagues', style: AppTextStyles.bodySmall),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All leagues', style: AppTextStyles.bodySmall),
                ),
                for (final league in leagues)
                  DropdownMenuItem<String?>(
                    value: league.id,
                    child: Text(
                      league.name,
                      style: AppTextStyles.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }
}
