import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/widgets.dart';
import '../../../models/fixture.dart';
import '../../../models/match_event.dart';
import '../../../models/player.dart';
import '../../../models/product.dart';
import '../../../repositories/mock/mock_data.dart';
import '../../../repositories/repository_providers.dart';
import '../../../repositories/repository_types.dart';
import '../fixtures/widgets/match_card.dart' show toneForMatchStatus;

/// Screen 03 — Match Detail.
class MatchDetailScreen extends ConsumerStatefulWidget {
  const MatchDetailScreen({super.key, required this.matchId});

  final String matchId;

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

typedef MatchDetailsScreen = MatchDetailScreen;

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late Future<Cached<Fixture>> _fixtureFuture;
  late Future<Cached<List<MatchEvent>>> _timelineFuture;
  late Future<Cached<List<Product>>> _merchFuture;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _reload();
  }

  void _reload() {
    final repo = ref.read(fixturesRepositoryProvider);
    _fixtureFuture = repo.fixture(widget.matchId, forceRefresh: true);
    _timelineFuture = repo.timeline(widget.matchId);
    _merchFuture = ref.read(storeRepositoryProvider).products();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canScore = ref.watch(permissionsProvider).canEnterScore;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Match Details',
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Lineups'),
            Tab(text: 'Stats'),
            Tab(text: 'Match Summary'),
          ],
        ),
      ),
      body: FutureBuilder<Cached<Fixture>>(
        future: _fixtureFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(message: 'Loading match…');
          }
          if (snapshot.hasError) {
            return ErrorView(
              error: snapshot.error!,
              onRetry: () => setState(_reload),
            );
          }

          final result = snapshot.data;
          final fixture = result?.data;
          if (fixture == null) {
            return const EmptyStateView(
              icon: Icons.search_off_rounded,
              title: 'Match not found',
              message: 'This match is no longer available.',
            );
          }

          return Column(
            children: [
              _Scoreboard(fixture: fixture, fromCache: result!.fromCache),
              if (canScore)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    AppSpacing.md,
                  ),
                  child: CustomButton(
                    text: 'Enter Score',
                    icon: Icons.edit_note_rounded,
                    onPressed: () =>
                        context.push('/matches/${fixture.id}/scoring'),
                  ),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _LineupsTab(fixture: fixture),
                    _StatsTab(fixture: fixture),
                    _MatchSummaryTab(
                      fixture: fixture,
                      timelineFuture: _timelineFuture,
                    ),
                  ],
                ),
              ),
              _FeaturedMerchandise(future: _merchFuture),
            ],
          );
        },
      ),
    );
  }
}

class _Scoreboard extends StatelessWidget {
  const _Scoreboard({required this.fixture, required this.fromCache});

  final Fixture fixture;
  final bool fromCache;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: CustomCard(
        child: Column(
          children: [
            Row(
              children: [
                StatusBadge(
                  label: fixture.status.label,
                  tone: toneForMatchStatus(fixture.status),
                  dense: true,
                ),
                const Spacer(),
                if (fromCache)
                  StatusBadge(
                    label: 'Cached',
                    tone: StatusTone.warning,
                    dense: true,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(child: _Team(team: fixture.homeTeam)),
                if (fixture.hasScore)
                  Text(
                    '${fixture.homeScore} – ${fixture.awayScore}',
                    style: AppTextStyles.score,
                  )
                else
                  Text(
                    'VS',
                    style: AppTextStyles.h1.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                Expanded(child: _Team(team: fixture.awayTeam)),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              fixture.kickoff.toLocal().toString().split('.').first,
              style: AppTextStyles.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (fixture.venue != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                fixture.venue!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (fixture.isLive && fixture.minute != null) ...[
              const SizedBox(height: AppSpacing.md),
              StatusBadge(
                label: "${fixture.minute}'",
                tone: StatusTone.danger,
                icon: Icons.timer_outlined,
                dense: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Team extends StatelessWidget {
  const _Team({required this.team});

  final TeamRef team;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary.withValues(alpha: 0.1),
            border: Border.all(color: scheme.outline),
          ),
          child: Center(
            child: Text(
              team.initials,
              style: AppTextStyles.label.copyWith(color: scheme.primary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          team.name,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _LineupsTab extends StatelessWidget {
  const _LineupsTab({required this.fixture});

  final Fixture fixture;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final homePlayers = MockData.players
        .where((player) => player.clubId == fixture.homeTeam.id)
        .toList();
    final awayPlayers = MockData.players
        .where((player) => player.clubId == fixture.awayTeam.id)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      children: [
        const SectionHeader(
          title: 'Starting lineups',
          subtitle: 'Demo lineups · final team sheets may change',
        ),
        _TeamLineup(teamName: fixture.homeTeam.name, players: homePlayers),
        const SizedBox(height: AppSpacing.md),
        _TeamLineup(teamName: fixture.awayTeam.name, players: awayPlayers),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Player data shown for preview only.',
          textAlign: TextAlign.center,
          style: AppTextStyles.helper.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _TeamLineup extends StatelessWidget {
  const _TeamLineup({required this.teamName, required this.players});

  final String teamName;
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(teamName, style: AppTextStyles.h3)),
              StatusBadge(label: 'XI', tone: StatusTone.info, dense: true),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (players.isEmpty)
            Text(
              'Lineup not announced',
              style: AppTextStyles.bodySmall.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            for (final player in players)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: scheme.primary.withValues(alpha: .1),
                      child: Text(
                        '${player.jerseyNumber ?? '—'}',
                        style: AppTextStyles.caption.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        player.name,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      player.position ?? 'Player',
                      style: AppTextStyles.helper.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab({required this.fixture});

  final Fixture fixture;

  static const _footballStats = <(String, int, int)>[
    ('Possession', 58, 42),
    ('Shots', 12, 8),
    ('Shots on target', 6, 3),
    ('Corners', 7, 4),
    ('Fouls', 9, 13),
    ('Pass accuracy', 86, 79),
  ];

  static const _cricketStats = <(String, int, int)>[
    ('Runs', 142, 138),
    ('Wickets', 7, 8),
    ('Overs', 20, 20),
    ('Boundaries', 18, 16),
    ('Extras', 9, 12),
    ('Run rate', 7, 6),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stats = fixture.leagueId == 'lg_cricket'
        ? _cricketStats
        : _footballStats;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      children: [
        const SectionHeader(
          title: 'Match statistics',
          subtitle: 'Illustrative sample stats for the match preview',
        ),
        CustomCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'HOME',
                      style: AppTextStyles.caption.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text('MATCH', style: AppTextStyles.caption),
                  Expanded(
                    child: Text(
                      'AWAY',
                      textAlign: TextAlign.end,
                      style: AppTextStyles.caption.copyWith(
                        color: scheme.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final (label, home, away) in stats)
                _StatComparison(label: label, home: home, away: away),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatComparison extends StatelessWidget {
  const _StatComparison({
    required this.label,
    required this.home,
    required this.away,
  });

  final String label;
  final int home;
  final int away;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = (home + away).toDouble();
    final homeShare = total == 0 ? .5 : home / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 38,
                child: Text('$home', style: AppTextStyles.label),
              ),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(
                width: 38,
                child: Text(
                  '$away',
                  textAlign: TextAlign.end,
                  style: AppTextStyles.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: SizedBox(
              height: 7,
              child: Row(
                children: [
                  Expanded(
                    flex: (homeShare * 100).round(),
                    child: ColoredBox(color: scheme.primary),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    flex: 100 - (homeShare * 100).round(),
                    child: ColoredBox(color: scheme.secondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchSummaryTab extends StatelessWidget {
  const _MatchSummaryTab({required this.fixture, required this.timelineFuture});

  final Fixture fixture;
  final Future<Cached<List<MatchEvent>>> timelineFuture;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = <(String, String)>[
      ('Status', fixture.status.label),
      ('Round', fixture.round ?? '—'),
      ('Venue', fixture.venue ?? '—'),
      ('Kick-off', fixture.kickoff.toLocal().toString().split('.').first),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      children: [
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Match information'),
              for (final (label, value) in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 88,
                        child: Text(
                          label,
                          style: AppTextStyles.helper.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(value, style: AppTextStyles.bodyMedium),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Match events'),
        _SummaryTimeline(future: timelineFuture),
      ],
    );
  }
}

class _SummaryTimeline extends StatelessWidget {
  const _SummaryTimeline({required this.future});

  final Future<Cached<List<MatchEvent>>> future;

  @override
  Widget build(BuildContext context) => FutureBuilder<Cached<List<MatchEvent>>>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const ShimmerLoadingWidgets(
          layout: ShimmerLayout.lineupRow,
          itemCount: 3,
        );
      }
      if (snapshot.hasError) return ErrorView(error: snapshot.error!);
      final events = [...?snapshot.data?.data]
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
      if (events.isEmpty) {
        return const EmptyStateWidget(
          icon: Icons.timeline_rounded,
          title: 'No match events yet',
          message: 'Match highlights and events will appear here.',
        );
      }
      return Column(
        children: [for (final event in events) _EventTile(event: event)],
      );
    },
  );
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final MatchEvent event;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = switch (event.status) {
      EventStatus.confirmed => StatusTone.success,
      EventStatus.pending => StatusTone.info,
      EventStatus.corrected => StatusTone.warning,
      EventStatus.rejected => StatusTone.danger,
      EventStatus.unknown => StatusTone.neutral,
    };

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              event.minute == null ? '—' : "${event.minute}'",
              style: AppTextStyles.label.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.type.label, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  [event.teamName, event.playerName, event.description]
                      .whereType<String>()
                      .where((value) => value.isNotEmpty)
                      .join(' • '),
                  style: AppTextStyles.helper.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(label: event.status.label, tone: tone, dense: true),
        ],
      ),
    );
  }
}

/// Featured merchandise — real products; tapping one opens it in the Store.
class _FeaturedMerchandise extends StatelessWidget {
  const _FeaturedMerchandise({required this.future});

  final Future<Cached<List<Product>>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Cached<List<Product>>>(
      future: future,
      builder: (context, snapshot) {
        final products = (snapshot.data?.data ?? const <Product>[])
            .where((product) => product.isInStock)
            .take(4)
            .toList();
        if (products.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Featured Merchandise'),
              SizedBox(
                height: 168,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return SizedBox(
                      width: 168,
                      child: CustomCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        onTap: () =>
                            context.push('/store/product/${product.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 44,
                              width: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                color: AppColors.primary.withValues(alpha: 0.1),
                              ),
                              child: const Icon(
                                Icons.checkroom_rounded,
                                size: 20,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${product.currency} ${product.price.toStringAsFixed(0)}',
                              style: AppTextStyles.price,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
