# NaSCon API

Express and Mongoose API for the Flutter client. Authentication and profile
images use MongoDB and Cloudinary. Fixtures, standings, leagues, and store
products currently return in-memory demo data.

## Project structure

```text
backend/
  .env.example
  package.json
  src/
    app.js
    server.js
    config/       Environment, MongoDB, and Cloudinary setup
    controllers/  Authentication, profile, and demo data handlers
    middlewares/  Authentication, async handling, and errors
    models/       Mongoose schemas
    routes/       API route groups
    services/     JWT session creation
  test/
```

Routes validate and dispatch requests, controllers implement HTTP behavior,
services contain shared operations, and models own persisted account data.
Demo catalogue data remains separate from MongoDB-backed user accounts.

## Setup

Requires Node.js 20 or later. From this directory:

```powershell
npm ci
Copy-Item .env.example .env
npm run dev
```

Fill in your own values in `.env` before starting the server. `.env` is ignored
by Git; never commit credentials.

- Set `JWT_SECRET` to a random value with at least 32 characters.
- Use a MongoDB Atlas URI with a database name. URL-encode special characters
  in the database password.
- `GOOGLE_CLIENT_ID` must match the audience on ID tokens from the Flutter
  Google Sign-In client. The backend verifies ID tokens; a Google client secret
  is not used in this flow and must never be included in Flutter.
- Set `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, and
  `CLOUDINARY_API_SECRET` from your Cloudinary account.
- Set `CORS_ORIGINS` to the exact origins used by Flutter Web. Native mobile
  requests are not subject to browser CORS.

The API validates configuration and connects to MongoDB before listening.
Health check: `GET /api/health`.

## Endpoints

| Method | Path | Access | Purpose |
|---|---|---|---|
| `POST` | `/api/auth/register` | Public | Register with `full_name`, `email`, `password` |
| `POST` | `/api/auth/login` | Public | Email/password sign-in |
| `POST` | `/api/auth/google` | Public | Verify Google `id_token` and sign in |
| `GET` | `/api/auth/me` | Authenticated | Current user for the existing app |
| `POST` | `/api/auth/logout` | Authenticated | Revoke existing access tokens |
| `GET` | `/api/user/profile` | Authenticated | Current user profile |
| `POST` | `/api/user/upload-avatar` | Authenticated | Upload multipart field `avatar` |
| `GET` | `/api/fixtures` | Public | Demo fixtures; optional `league_id`, `status` filters |
| `GET` | `/api/standings` | Public | Demo standings |
| `GET` | `/api/store/products` | Public | Demo products; optional `category`, `q` filters |

Compatibility routes used by the existing repositories are also available:
`GET /api/leagues`, `GET /api/leagues/:leagueId/standings`,
`GET /api/products`, and `GET /api/products/:productId`.

Successful authentication responses use the Flutter app's snake_case session
shape: `access_token`, `token_type`, `expires_at`, and `user` (`id`,
`full_name`, `email`, `role`, `avatar_url`). Public registration always assigns
the least-privileged `viewer` role. Passwords and Google ID tokens are never
returned.

Avatar uploads accept JPEG, PNG, or WebP images up to 5 MB. The Cloudinary
configuration also exports a Multer uploader for product images; product
authoring routes are not part of this demo API. Image URLs and Cloudinary
public IDs are stored on the user, and replaced avatars are removed.

## Run Flutter against the API

For an Android emulator:

```powershell
flutter run --dart-define=USE_MOCK_BACKEND=false --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
```

On a physical device, use the computer's LAN address instead of `10.0.2.2`.
Use HTTPS in production. The Flutter `ApiService` uses the existing Dio client
for authenticated requests and error mapping.

## Checks

```powershell
npm test
npm run check
npm audit --omit=dev
```
