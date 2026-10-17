import '../../models/club.dart';
import '../../models/fixture.dart';
import '../../models/league.dart';
import '../../models/match_event.dart';
import '../../models/player.dart';
import '../../models/product.dart';
import '../../models/product_variant.dart';
import '../../models/standings_row.dart';
import '../../models/user.dart';

/// A demo account for mock mode.
///
/// These credentials are **development data only**. They exist so the app is
/// usable before the backend exists and are documented in `mobile/README.md`.
/// They are not a production authentication path.
class DemoAccount {
  const DemoAccount({
    required this.email,
    required this.password,
    required this.user,
  });

  final String email;
  final String password;
  final User user;
}

/// Realistic, clearly-labelled development data.
abstract final class MockData {
  static final DateTime _now = DateTime.now();

  // ---------------------------------------------------------------------------
  // Leagues
  // ---------------------------------------------------------------------------
  static const List<League> leagues = [
    League(
      id: 'lg_football',
      name: 'NaSCon Football League',
      season: '2026',
      sport: 'football',
      teamCount: 8,
    ),
    League(
      id: 'lg_cricket',
      name: 'NaSCon Cricket Cup',
      season: '2026',
      sport: 'cricket',
      teamCount: 4,
    ),
  ];

  // ---------------------------------------------------------------------------
  // Clubs
  // ---------------------------------------------------------------------------
  static const List<Club> clubs = [
    Club(
      id: 'cl_falcons',
      name: 'Karachi Falcons',
      shortName: 'KAR',
      leagueId: 'lg_football',
      description:
          'Founded in 2019, the Falcons are the league\'s most consistent '
          'performer, with a possession-based style and the strongest academy '
          'pipeline in the competition.',
      stats: ClubStats(
        played: 14,
        won: 10,
        drawn: 2,
        lost: 2,
        points: 32,
        differential: 18,
      ),
    ),
    Club(
      id: 'cl_lions',
      name: 'Lahore Lions',
      shortName: 'LHR',
      leagueId: 'lg_football',
      description: 'Attacking side with the league\'s highest goal tally.',
      stats: ClubStats(
        played: 14,
        won: 9,
        drawn: 3,
        lost: 2,
        points: 30,
        differential: 15,
      ),
    ),
    Club(
      id: 'cl_eagles',
      name: 'Islamabad Eagles',
      shortName: 'ISB',
      leagueId: 'lg_football',
      stats: ClubStats(
        played: 14,
        won: 8,
        drawn: 3,
        lost: 3,
        points: 27,
        differential: 9,
      ),
    ),
    Club(
      id: 'cl_panthers',
      name: 'Peshawar Panthers',
      shortName: 'PSH',
      leagueId: 'lg_football',
      stats: ClubStats(
        played: 14,
        won: 7,
        drawn: 4,
        lost: 3,
        points: 25,
        differential: 6,
      ),
    ),
    Club(
      id: 'cl_bears',
      name: 'Quetta Bears',
      shortName: 'QTA',
      leagueId: 'lg_football',
      stats: ClubStats(
        played: 14,
        won: 6,
        drawn: 3,
        lost: 5,
        points: 21,
        differential: 1,
      ),
    ),
    Club(
      id: 'cl_sultans',
      name: 'Multan Sultans',
      shortName: 'MUL',
      leagueId: 'lg_football',
      stats: ClubStats(
        played: 14,
        won: 5,
        drawn: 4,
        lost: 5,
        points: 19,
        differential: -3,
      ),
    ),
    Club(
      id: 'cl_royals',
      name: 'Pindi Royals',
      shortName: 'RWP',
      leagueId: 'lg_football',
      stats: ClubStats(
        played: 14,
        won: 4,
        drawn: 3,
        lost: 7,
        points: 15,
        differential: -9,
      ),
    ),
    Club(
      id: 'cl_hawks',
      name: 'Hyderabad Hawks',
      shortName: 'HYD',
      leagueId: 'lg_football',
      stats: ClubStats(
        played: 14,
        won: 2,
        drawn: 2,
        lost: 10,
        points: 8,
        differential: -20,
      ),
    ),
    Club(
      id: 'cl_strikers',
      name: 'Sialkot Strikers',
      shortName: 'SKT',
      leagueId: 'lg_cricket',
      stats: ClubStats(played: 6, won: 4, drawn: 0, lost: 2, points: 12),
    ),
    Club(
      id: 'cl_titans',
      name: 'Faisalabad Titans',
      shortName: 'FSD',
      leagueId: 'lg_cricket',
      stats: ClubStats(played: 6, won: 3, drawn: 0, lost: 3, points: 9),
    ),
    Club(
      id: 'cl_warriors',
      name: 'Gwadar Warriors',
      shortName: 'GWD',
      leagueId: 'lg_cricket',
      stats: ClubStats(played: 6, won: 2, drawn: 0, lost: 4, points: 6),
    ),
    Club(
      id: 'cl_kings',
      name: 'Abbottabad Kings',
      shortName: 'ABT',
      leagueId: 'lg_cricket',
      stats: ClubStats(played: 6, won: 1, drawn: 0, lost: 5, points: 3),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Players
  // ---------------------------------------------------------------------------
  static const List<Player> players = [
    Player(
      id: 'pl_01',
      name: 'Bilal Ahmed',
      clubId: 'cl_falcons',
      position: 'Goalkeeper',
      jerseyNumber: 1,
    ),
    Player(
      id: 'pl_02',
      name: 'Hamza Riaz',
      clubId: 'cl_falcons',
      position: 'Defender',
      jerseyNumber: 4,
    ),
    Player(
      id: 'pl_03',
      name: 'Usman Tariq',
      clubId: 'cl_falcons',
      position: 'Defender',
      jerseyNumber: 5,
      status: PlayerStatus.injured,
    ),
    Player(
      id: 'pl_04',
      name: 'Danish Iqbal',
      clubId: 'cl_falcons',
      position: 'Midfielder',
      jerseyNumber: 8,
    ),
    Player(
      id: 'pl_05',
      name: 'Ahsan Malik',
      clubId: 'cl_falcons',
      position: 'Midfielder',
      jerseyNumber: 10,
    ),
    Player(
      id: 'pl_06',
      name: 'Zain Abbas',
      clubId: 'cl_falcons',
      position: 'Forward',
      jerseyNumber: 9,
    ),
    Player(
      id: 'pl_07',
      name: 'Fahad Sheikh',
      clubId: 'cl_falcons',
      position: 'Forward',
      jerseyNumber: 11,
      status: PlayerStatus.suspended,
    ),
    Player(
      id: 'pl_08',
      name: 'Imran Yousaf',
      clubId: 'cl_falcons',
      position: 'Midfielder',
      jerseyNumber: 17,
      loanClubId: 'cl_hawks',
    ),
    Player(
      id: 'pl_11',
      name: 'Saad Rehman',
      clubId: 'cl_lions',
      position: 'Goalkeeper',
      jerseyNumber: 1,
    ),
    Player(
      id: 'pl_12',
      name: 'Kashif Nadeem',
      clubId: 'cl_lions',
      position: 'Defender',
      jerseyNumber: 3,
    ),
    Player(
      id: 'pl_13',
      name: 'Waqar Hassan',
      clubId: 'cl_lions',
      position: 'Midfielder',
      jerseyNumber: 6,
    ),
    Player(
      id: 'pl_14',
      name: 'Talha Javed',
      clubId: 'cl_lions',
      position: 'Forward',
      jerseyNumber: 9,
    ),
    Player(
      id: 'pl_15',
      name: 'Noman Aslam',
      clubId: 'cl_lions',
      position: 'Forward',
      jerseyNumber: 10,
      status: PlayerStatus.injured,
    ),
  ];

  static TeamRef team(String clubId) {
    final club = clubs.firstWhere((c) => c.id == clubId);
    return TeamRef(
      id: club.id,
      name: club.name,
      shortName: club.shortName,
    );
  }

  // ---------------------------------------------------------------------------
  // Fixtures
  // ---------------------------------------------------------------------------
  static final List<Fixture> fixtures = [
    Fixture(
      id: 'fx_01',
      leagueId: 'lg_football',
      homeTeam: team('cl_falcons'),
      awayTeam: team('cl_lions'),
      kickoff: _now.add(const Duration(days: 2, hours: 3)),
      venue: 'National Stadium, Karachi',
      status: MatchStatus.scheduled,
      round: 'Round 15',
    ),
    Fixture(
      id: 'fx_02',
      leagueId: 'lg_football',
      homeTeam: team('cl_eagles'),
      awayTeam: team('cl_panthers'),
      kickoff: _now.add(const Duration(days: 3)),
      venue: 'Jinnah Stadium, Islamabad',
      status: MatchStatus.scheduled,
      round: 'Round 15',
    ),
    Fixture(
      id: 'fx_03',
      leagueId: 'lg_football',
      homeTeam: team('cl_bears'),
      awayTeam: team('cl_sultans'),
      kickoff: _now.subtract(const Duration(minutes: 38)),
      venue: 'Ayub Stadium, Quetta',
      status: MatchStatus.live,
      homeScore: 2,
      awayScore: 1,
      minute: 38,
      round: 'Round 15',
    ),
    Fixture(
      id: 'fx_04',
      leagueId: 'lg_football',
      homeTeam: team('cl_royals'),
      awayTeam: team('cl_hawks'),
      kickoff: _now.add(const Duration(hours: 6)),
      venue: 'Army Stadium, Rawalpindi',
      status: MatchStatus.scheduled,
      round: 'Round 15',
    ),
    Fixture(
      id: 'fx_05',
      leagueId: 'lg_football',
      homeTeam: team('cl_lions'),
      awayTeam: team('cl_eagles'),
      kickoff: _now.subtract(const Duration(days: 1)),
      venue: 'Gaddafi Stadium, Lahore',
      status: MatchStatus.completed,
      homeScore: 3,
      awayScore: 2,
      round: 'Round 14',
    ),
    Fixture(
      id: 'fx_06',
      leagueId: 'lg_football',
      homeTeam: team('cl_panthers'),
      awayTeam: team('cl_bears'),
      kickoff: _now.subtract(const Duration(days: 2)),
      venue: 'Arbab Niaz Stadium, Peshawar',
      status: MatchStatus.completed,
      homeScore: 1,
      awayScore: 1,
      round: 'Round 14',
    ),
    Fixture(
      id: 'fx_07',
      leagueId: 'lg_football',
      homeTeam: team('cl_sultans'),
      awayTeam: team('cl_falcons'),
      kickoff: _now.subtract(const Duration(days: 4)),
      venue: 'Multan Cricket Stadium',
      status: MatchStatus.completed,
      homeScore: 0,
      awayScore: 2,
      round: 'Round 14',
    ),
    Fixture(
      id: 'fx_08',
      leagueId: 'lg_football',
      homeTeam: team('cl_hawks'),
      awayTeam: team('cl_royals'),
      kickoff: _now.add(const Duration(days: 1, hours: 4)),
      venue: 'Niaz Stadium, Hyderabad',
      status: MatchStatus.postponed,
      round: 'Round 15',
    ),
    Fixture(
      id: 'fx_09',
      leagueId: 'lg_cricket',
      homeTeam: team('cl_strikers'),
      awayTeam: team('cl_titans'),
      kickoff: _now.add(const Duration(days: 1)),
      venue: 'Jinnah Stadium, Sialkot',
      status: MatchStatus.scheduled,
      round: 'Match 7',
    ),
    Fixture(
      id: 'fx_10',
      leagueId: 'lg_cricket',
      homeTeam: team('cl_warriors'),
      awayTeam: team('cl_kings'),
      kickoff: _now.subtract(const Duration(hours: 30)),
      venue: 'Gwadar Cricket Ground',
      status: MatchStatus.completed,
      homeScore: 142,
      awayScore: 138,
      round: 'Match 6',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Match timeline (for the live fixture)
  // ---------------------------------------------------------------------------
  static final List<MatchEvent> events = [
    MatchEvent(
      id: 'ev_01',
      matchId: 'fx_03',
      type: MatchEventType.periodStart,
      sequence: 1,
      description: 'Kick-off',
      minute: 0,
      period: '1H',
      createdAt: _now.subtract(const Duration(minutes: 38)),
    ),
    MatchEvent(
      id: 'ev_02',
      matchId: 'fx_03',
      type: MatchEventType.goal,
      sequence: 2,
      teamId: 'cl_bears',
      teamName: 'Quetta Bears',
      playerId: 'pl_06',
      playerName: 'Zain Abbas',
      points: 1,
      minute: 12,
      period: '1H',
      createdAt: _now.subtract(const Duration(minutes: 26)),
    ),
    MatchEvent(
      id: 'ev_03',
      matchId: 'fx_03',
      type: MatchEventType.card,
      sequence: 3,
      teamId: 'cl_sultans',
      teamName: 'Multan Sultans',
      playerName: 'Noman Aslam',
      description: 'Yellow card — dissent',
      minute: 21,
      period: '1H',
      createdAt: _now.subtract(const Duration(minutes: 17)),
    ),
    MatchEvent(
      id: 'ev_04',
      matchId: 'fx_03',
      type: MatchEventType.goal,
      sequence: 4,
      teamId: 'cl_sultans',
      teamName: 'Multan Sultans',
      playerName: 'Talha Javed',
      points: 1,
      minute: 29,
      period: '1H',
      createdAt: _now.subtract(const Duration(minutes: 9)),
    ),
    MatchEvent(
      id: 'ev_05',
      matchId: 'fx_03',
      type: MatchEventType.goal,
      sequence: 5,
      teamId: 'cl_bears',
      teamName: 'Quetta Bears',
      playerName: 'Ahsan Malik',
      points: 1,
      minute: 35,
      period: '1H',
      createdAt: _now.subtract(const Duration(minutes: 3)),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Standings
  // ---------------------------------------------------------------------------
  static const List<StandingsRow> footballStandings = [
    StandingsRow(
      teamId: 'cl_falcons',
      teamName: 'Karachi Falcons',
      teamShortName: 'Falcons',
      position: 1,
      played: 14,
      won: 10,
      drawn: 2,
      lost: 2,
      points: 32,
      differential: 18,
      qualification: QualificationStatus.qualified,
    ),
    StandingsRow(
      teamId: 'cl_lions',
      teamName: 'Lahore Lions',
      teamShortName: 'Lions',
      position: 2,
      played: 14,
      won: 9,
      drawn: 3,
      lost: 2,
      points: 30,
      differential: 15,
      qualification: QualificationStatus.qualified,
    ),
    StandingsRow(
      teamId: 'cl_eagles',
      teamName: 'Islamabad Eagles',
      teamShortName: 'Eagles',
      position: 3,
      played: 14,
      won: 8,
      drawn: 3,
      lost: 3,
      points: 27,
      differential: 9,
      qualification: QualificationStatus.qualified,
    ),
    StandingsRow(
      teamId: 'cl_panthers',
      teamName: 'Peshawar Panthers',
      teamShortName: 'Panthers',
      position: 4,
      played: 14,
      won: 7,
      drawn: 4,
      lost: 3,
      points: 25,
      differential: 6,
      qualification: QualificationStatus.qualified,
    ),
    StandingsRow(
      teamId: 'cl_bears',
      teamName: 'Quetta Bears',
      teamShortName: 'Bears',
      position: 5,
      played: 14,
      won: 6,
      drawn: 3,
      lost: 5,
      points: 21,
      differential: 1,
      qualification: QualificationStatus.inContention,
    ),
    StandingsRow(
      teamId: 'cl_sultans',
      teamName: 'Multan Sultans',
      teamShortName: 'Sultans',
      position: 6,
      played: 14,
      won: 5,
      drawn: 4,
      lost: 5,
      points: 19,
      differential: -3,
      qualification: QualificationStatus.inContention,
    ),
    StandingsRow(
      teamId: 'cl_royals',
      teamName: 'Pindi Royals',
      teamShortName: 'Royals',
      position: 7,
      played: 14,
      won: 4,
      drawn: 3,
      lost: 7,
      points: 15,
      differential: -9,
      qualification: QualificationStatus.eliminated,
    ),
    StandingsRow(
      teamId: 'cl_hawks',
      teamName: 'Hyderabad Hawks',
      teamShortName: 'Hawks',
      position: 8,
      played: 14,
      won: 2,
      drawn: 2,
      lost: 10,
      points: 8,
      differential: -20,
      qualification: QualificationStatus.eliminated,
    ),
  ];

  /// Cricket league deliberately omits `qualification` — the UI must not invent
  /// a qualification state the backend did not provide.
  static const List<StandingsRow> cricketStandings = [
    StandingsRow(
      teamId: 'cl_strikers',
      teamName: 'Sialkot Strikers',
      teamShortName: 'Strikers',
      position: 1,
      played: 6,
      won: 4,
      drawn: 0,
      lost: 2,
      points: 12,
      differential: 24,
    ),
    StandingsRow(
      teamId: 'cl_titans',
      teamName: 'Faisalabad Titans',
      teamShortName: 'Titans',
      position: 2,
      played: 6,
      won: 3,
      drawn: 0,
      lost: 3,
      points: 9,
      differential: 5,
    ),
    StandingsRow(
      teamId: 'cl_warriors',
      teamName: 'Gwadar Warriors',
      teamShortName: 'Warriors',
      position: 3,
      played: 6,
      won: 2,
      drawn: 0,
      lost: 4,
      points: 6,
      differential: -11,
    ),
    StandingsRow(
      teamId: 'cl_kings',
      teamName: 'Abbottabad Kings',
      teamShortName: 'Kings',
      position: 4,
      played: 6,
      won: 1,
      drawn: 0,
      lost: 5,
      points: 3,
      differential: -18,
    ),
  ];

  // ---------------------------------------------------------------------------
  // Store
  // ---------------------------------------------------------------------------
  static const List<Product> products = [
    Product(
      id: 'pr_jersey_home',
      name: 'Home Jersey 2026',
      price: 4500,
      category: 'Apparel',
      description:
          'Official NaSCon 2026 home jersey with breathable mesh panels and '
          'the embroidered league crest.',
      variants: [
        ProductVariant(id: 'var_home_s', name: 'Small', stockQuantity: 8),
        ProductVariant(id: 'var_home_m', name: 'Medium', stockQuantity: 14),
        ProductVariant(id: 'var_home_l', name: 'Large', stockQuantity: 5),
        ProductVariant(id: 'var_home_xl', name: 'X-Large', stockQuantity: 0),
      ],
    ),
    Product(
      id: 'pr_jersey_away',
      name: 'Away Jersey 2026',
      price: 4500,
      category: 'Apparel',
      description: 'Official away jersey in midnight navy.',
      variants: [
        ProductVariant(id: 'var_away_s', name: 'Small', stockQuantity: 3),
        ProductVariant(id: 'var_away_m', name: 'Medium', stockQuantity: 9),
        ProductVariant(id: 'var_away_l', name: 'Large', stockQuantity: 6),
      ],
    ),
    Product(
      id: 'pr_hoodie',
      name: 'Training Hoodie',
      price: 5200,
      category: 'Apparel',
      description: 'Fleece-lined hoodie worn by the squads in pre-season.',
      variants: [
        ProductVariant(id: 'var_hood_m', name: 'Medium', stockQuantity: 7),
        ProductVariant(id: 'var_hood_l', name: 'Large', stockQuantity: 4),
      ],
    ),
    Product(
      id: 'pr_cap',
      name: 'Team Cap',
      price: 1500,
      category: 'Accessories',
      description: 'Adjustable cap with the league monogram.',
      stockQuantity: 25,
    ),
    Product(
      id: 'pr_scarf',
      name: 'Supporters Scarf',
      price: 1800,
      category: 'Accessories',
      description: 'Knitted scarf in the league colours.',
      stockQuantity: 12,
    ),
    Product(
      id: 'pr_bottle',
      name: 'Steel Water Bottle',
      price: 1200,
      category: 'Accessories',
      description: 'Insulated 750ml bottle.',
      stockQuantity: 40,
    ),
    Product(
      id: 'pr_ball',
      name: 'Official Match Ball',
      price: 3200,
      category: 'Equipment',
      description: 'FIFA-quality match ball used across the league.',
      stockQuantity: 6,
    ),
    Product(
      id: 'pr_gloves',
      name: 'Goalkeeper Gloves',
      price: 2800,
      category: 'Equipment',
      description: 'Latex palm gloves with wrist strap. Currently sold out.',
      stockQuantity: 0,
    ),
  ];

  // ---------------------------------------------------------------------------
  // Demo accounts (one per role)
  // ---------------------------------------------------------------------------
  static const List<DemoAccount> demoAccounts = [
    DemoAccount(
      email: 'admin@nascon.example',
      password: 'NasCon@2026',
      user: User(
        id: 'u_admin',
        fullName: 'Ayesha Khan',
        email: 'admin@nascon.example',
        role: UserRole.superAdmin,
      ),
    ),
    DemoAccount(
      email: 'organizer@nascon.example',
      password: 'NasCon@2026',
      user: User(
        id: 'u_organizer',
        fullName: 'Omar Farooq',
        email: 'organizer@nascon.example',
        role: UserRole.leagueOrganizer,
        leagueId: 'lg_football',
      ),
    ),
    DemoAccount(
      email: 'manager@nascon.example',
      password: 'NasCon@2026',
      user: User(
        id: 'u_manager',
        fullName: 'Sana Malik',
        email: 'manager@nascon.example',
        role: UserRole.clubManager,
        clubId: 'cl_falcons',
        leagueId: 'lg_football',
      ),
    ),
    DemoAccount(
      email: 'player@nascon.example',
      password: 'NasCon@2026',
      user: User(
        id: 'u_player',
        fullName: 'Zain Abbas',
        email: 'player@nascon.example',
        role: UserRole.player,
        clubId: 'cl_falcons',
        leagueId: 'lg_football',
      ),
    ),
    DemoAccount(
      email: 'viewer@nascon.example',
      password: 'NasCon@2026',
      user: User(
        id: 'u_viewer',
        fullName: 'Guest Viewer',
        email: 'viewer@nascon.example',
        role: UserRole.viewer,
      ),
    ),
  ];
}
