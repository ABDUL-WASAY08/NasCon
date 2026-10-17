# NaSCon '26 — Mobile App (Flutter)

Multi-sport league & club operations client. Feature-first architecture, Riverpod
state, `go_router` navigation, mock-first repositories, and a durable offline
action queue.

> **The NaSCon backend does not exist yet.** The app ships in **mock mode** by
> default and is fully usable without a server. Every remote integration point is
> declared in [`FRONTEND_BACKEND_CONTRACT.md`](./FRONTEND_BACKEND_CONTRACT.md) as
> `PENDING BACKEND CONTRACT`.

---

## 1. Prerequisites

| Tool | Version used |
|---|---|
| Flutter | 3.41.9 (stable) |
| Dart | 3.11.5 |
| Android | AGP 8.11.1, Gradle 8.14, Kotlin 2.2.20, JVM 17 |

## 2. Install & run

```bash
flutter pub get
flutter run                       # mock backend, no server required
```

## 3. Tests

```bash
flutter analyze                   # must report no issues
flutter test                      # unit + widget + integration
flutter test test/unit            # unit only
```

The suite runs entirely on in-memory doubles (mock repositories, in-memory
session store, in-memory database) — no network, no platform channels, no device
database.

## 4. Configuration

All configuration is supplied at build time via `--dart-define`; nothing
environment-specific lives in source control.

| Define | Default | Meaning |
|---|---|---|
| `USE_MOCK_BACKEND` | `true` | Resolves every repository to its mock implementation |
| `API_BASE_URL` | `http://10.0.2.2:8080/v1` | API root used when mock mode is off |

**Networking notes**

* Android emulator reaches the host loopback as `10.0.2.2` (the default).
* A physical device must use your machine's LAN address, e.g.
  `--dart-define=API_BASE_URL=http://192.168.1.20:8080/v1`.
* Production supplies the real host; never hard-code `localhost`.

**Against a real backend**

```bash
flutter run --dart-define=USE_MOCK_BACKEND=false \
            --dart-define=API_BASE_URL=https://api.nascon.example/v1
```

## 5. Demo accounts (mock mode only)

Mock mode accepts five documented accounts — one per role — and the Login screen
lists them behind a "Demo accounts (mock backend)" card. Shared password:
`NasCon@2026`.

| Email | Role |
|---|---|
| `admin@nascon.example` | Platform Super-Admin |
| `organizer@nascon.example` | League Organizer |
| `manager@nascon.example` | Club Manager |
| `player@nascon.example` | Player |
| `viewer@nascon.example` | Guest Viewer |

These are **development data**, not a production authentication path. They are
not compiled into any non-mock build path.

## 6. Build the Android APK

```bash
flutter build apk --release
```

The verified artifact is copied to the competition path:

```
mobile/release/app-release.apk
```

`android/app/build.gradle.kts` currently signs release builds with the **debug**
key so `flutter run --release` works. Replace it with a real signing config
before distribution; never commit a keystore or its passwords.

## 7. Storage

| Data | Where | Why |
|---|---|---|
| Access/refresh token + user | `flutter_secure_storage` (Keychain / EncryptedSharedPreferences) | Secrets never live in plain preferences |
| Theme mode, onboarding flag | `shared_preferences` | Non-sensitive preferences only |
| Fixtures / standings / club / product caches | SQLite (`nascon.db`) with `updated_at` | Offline reads; staleness is surfaced in the UI |
| Cart | SQLite | Survives restarts; totals are never recomputed elsewhere |
| Offline action queue | SQLite `sync_queue` | Must survive force-close |

Queue states: `pending`, `syncing`, `synced`, `failed`, `conflict`,
`needs_review`. Nothing is discarded on failure; conflicts and needs-review
entries are preserved for a human.

## 8. Architecture

```text
lib/
  main.dart              bootstrap: config → database → prefs → session → runApp
  app/                   MaterialApp.router + go_router (auth redirect, guards)
  core/                  config, theme, errors, network, storage, sync, permissions, widgets
  models/                typed, tolerant JSON models
  repositories/          interfaces + mock/* + api/* + Riverpod wiring
  features/              splash auth home fixtures match_detail standings
                         club_profile store orders roster scoring sync_status profile
```

Screens never talk to HTTP: they read repositories through providers, and every
repository has a mock and a production implementation behind one interface.

## 9. Known limitations

* **No live scores.** The backend has no WebSocket/SSE contract, so no real-time
  updates are simulated. The subscription boundary is documented, not faked.
* **Roster "Add player"** is intentionally absent — no backend contract exists
  for creating a player, and inventing one would be a fake capability.
  Transfer / Loan / Release are implemented.
* **Fonts** are fetched at runtime by `google_fonts`; the first run needs
  network or text falls back to the platform font.
* **Server-side authorization** is not implemented here. The app hides controls
  the user may not use, but the backend must enforce every permission.
* `pdf` 3.12 pins `archive <4.1.0`, so `image` is pinned to `4.3.0` via
  `dependency_overrides` (see `pubspec.yaml`); remove it once `pdf` ≥ 3.13 is
  usable on this Dart SDK.
