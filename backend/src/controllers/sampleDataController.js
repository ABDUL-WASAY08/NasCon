const fixtures = [
  {
    id: 'fixture-demo-001',
    league_id: 'nascon-2026',
    home_team: { id: 'team-lions', name: 'Lions', short_name: 'LIO' },
    away_team: { id: 'team-eagles', name: 'Eagles', short_name: 'EAG' },
    kickoff: '2026-11-02T14:00:00.000Z',
    venue: 'NaSCon Arena',
    status: 'scheduled',
    round: 'Group A',
  },
  {
    id: 'fixture-demo-002',
    league_id: 'nascon-2026',
    home_team: { id: 'team-titans', name: 'Titans', short_name: 'TIT' },
    away_team: { id: 'team-panthers', name: 'Panthers', short_name: 'PAN' },
    kickoff: '2026-11-03T16:30:00.000Z',
    venue: 'University Ground',
    status: 'completed',
    home_score: 2,
    away_score: 1,
    round: 'Group A',
  },
];

const leagues = [
  {
    id: 'nascon-2026',
    name: 'NaSCon 2026',
    season: '2026',
    sport: 'football',
    team_count: 3,
  },
];

const standings = [
  {
    team_id: 'team-titans',
    team_name: 'Titans',
    team_short_name: 'TIT',
    position: 1,
    played: 3,
    won: 2,
    drawn: 1,
    lost: 0,
    points: 7,
    differential: 4,
  },
  {
    team_id: 'team-lions',
    team_name: 'Lions',
    team_short_name: 'LIO',
    position: 2,
    played: 3,
    won: 2,
    drawn: 0,
    lost: 1,
    points: 6,
    differential: 2,
  },
  {
    team_id: 'team-eagles',
    team_name: 'Eagles',
    team_short_name: 'EAG',
    position: 3,
    played: 3,
    won: 1,
    drawn: 0,
    lost: 2,
    points: 3,
    differential: -1,
  },
];

const products = [
  {
    id: 'product-demo-001',
    name: 'NaSCon Match Jersey',
    description: 'Official tournament jersey.',
    price: 2500,
    currency: 'PKR',
    image_url: null,
    category: 'Apparel',
    stock_quantity: 40,
    variants: [
      { id: 'jersey-s', name: 'S', stock_quantity: 8, sku: 'NAS-JER-S' },
      { id: 'jersey-m', name: 'M', stock_quantity: 16, sku: 'NAS-JER-M' },
      { id: 'jersey-l', name: 'L', stock_quantity: 16, sku: 'NAS-JER-L' },
    ],
  },
  {
    id: 'product-demo-002',
    name: 'Tournament Water Bottle',
    description: 'Reusable bottle with NaSCon branding.',
    price: 800,
    currency: 'PKR',
    image_url: null,
    category: 'Accessories',
    stock_quantity: 65,
    variants: [],
  },
];

export function getFixtures(req, res) {
  const { league_id: leagueId, status } = req.query;
  const normalizedStatus = typeof status === 'string' ? status.toLowerCase() : '';
  const filtered = fixtures.filter((fixture) =>
    (!leagueId || fixture.league_id === leagueId) &&
    (!normalizedStatus ||
      normalizedStatus === 'all' ||
      (normalizedStatus === 'upcoming'
        ? ['scheduled', 'postponed'].includes(fixture.status)
        : fixture.status === normalizedStatus)));
  res.json(filtered);
}

export function getStandings(_req, res) {
  res.json(standings);
}

export function getLeagues(_req, res) {
  res.json(leagues);
}

export function getLeagueStandings(req, res) {
  if (!leagues.some((league) => league.id === req.params.leagueId)) {
    return res.status(404).json({ message: 'League not found.' });
  }
  res.json(standings);
}

export function getProducts(req, res) {
  const { category, q } = req.query;
  const filtered = products.filter((product) =>
    (!category || product.category.toLowerCase() === String(category).toLowerCase()) &&
    (!q || product.name.toLowerCase().includes(String(q).toLowerCase())));
  res.json(filtered);
}

export function getProduct(req, res) {
  const product = products.find((item) => item.id === req.params.productId);
  if (!product) return res.status(404).json({ message: 'Product not found.' });
  res.json(product);
}
