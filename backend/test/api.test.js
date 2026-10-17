import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';

process.env.JWT_SECRET = 'test-only-secret-with-at-least-thirty-two-characters';
process.env.MONGODB_URI = 'mongodb://127.0.0.1/test';
process.env.GOOGLE_CLIENT_ID = 'test-client-id';
process.env.CLOUDINARY_CLOUD_NAME = 'test-cloud';
process.env.CLOUDINARY_API_KEY = 'test-api-key';
process.env.CLOUDINARY_API_SECRET = 'test-api-secret';
process.env.CORS_ORIGINS = '';

const { createApp } = await import('../src/app.js');
let server;
let baseUrl;

before(async () => {
  server = createApp().listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  await new Promise((resolve, reject) =>
    server.close((error) => error ? reject(error) : resolve()));
});

test('health endpoint reports readiness of the HTTP app', async () => {
  const response = await fetch(`${baseUrl}/api/health`);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { status: 'ok' });
});

test('fixtures endpoint returns app-compatible records and supports filters', async () => {
  const response = await fetch(`${baseUrl}/api/fixtures?status=completed`);
  const fixtures = await response.json();
  assert.equal(response.status, 200);
  assert.equal(fixtures.length, 1);
  assert.equal(fixtures[0].home_team.name, 'Titans');
  assert.equal(fixtures[0].status, 'completed');
});

test('standings and store endpoints return lists matching Flutter model fields', async () => {
  const [standingsResponse, productsResponse] = await Promise.all([
    fetch(`${baseUrl}/api/standings`),
    fetch(`${baseUrl}/api/store/products?q=jersey`),
  ]);
  const standings = await standingsResponse.json();
  const products = await productsResponse.json();
  assert.equal(standingsResponse.status, 200);
  assert.ok('team_id' in standings[0] && 'position' in standings[0]);
  assert.equal(productsResponse.status, 200);
  assert.equal(products.length, 1);
  assert.ok('image_url' in products[0] && Array.isArray(products[0].variants));
});

test('profile endpoint rejects requests without a bearer token', async () => {
  const response = await fetch(`${baseUrl}/api/user/profile`);
  assert.equal(response.status, 401);
  assert.match((await response.json()).message, /authentication/i);
});

test('legacy mobile repository paths are served by the API', async () => {
  const [leaguesResponse, standingsResponse, productsResponse] = await Promise.all([
    fetch(`${baseUrl}/api/leagues`),
    fetch(`${baseUrl}/api/leagues/nascon-2026/standings`),
    fetch(`${baseUrl}/api/products`),
  ]);
  assert.equal(leaguesResponse.status, 200);
  assert.equal(standingsResponse.status, 200);
  assert.equal(productsResponse.status, 200);
  assert.equal((await leaguesResponse.json())[0].id, 'nascon-2026');
});

test('unknown product IDs return a not-found response', async () => {
  const response = await fetch(`${baseUrl}/api/products/not-a-product`);
  assert.equal(response.status, 404);
  assert.match((await response.json()).message, /product not found/i);
});

test('registration validates input without requiring a database write', async () => {
  const response = await fetch(`${baseUrl}/api/auth/register`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({}),
  });
  assert.equal(response.status, 400);
  assert.match((await response.json()).message, /name must/i);
});

test('user model hashes passwords and never serializes credentials', async () => {
  const { User } = await import('../src/models/User.js');
  const user = new User({ fullName: 'Demo User', email: 'demo@example.com' });
  await user.setPassword('correct-horse-battery');
  await user.validate();
  assert.notEqual(user.passwordHash, 'correct-horse-battery');
  assert.equal(await user.verifyPassword('correct-horse-battery'), true);
  assert.equal(await user.verifyPassword('wrong-password'), false);
  assert.equal('passwordHash' in user.toPublicJSON(), false);
});
