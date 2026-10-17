# Frontend ↔ Backend Contract — NaSCon '26 Mobile

**Status of every route below: `PENDING BACKEND CONTRACT`.**

No NaSCon API documentation, OpenAPI schema, or backend source was available in
this repository. Every path in `lib/core/network/api_routes.dart` is a **proposal
written by the frontend** — it is *not* a verified contract, and no request has
ever been made against a live service. The app therefore runs on **mock
repositories** by default (`USE_MOCK_BACKEND=true`).

Nothing in this app fabricates success: with mock mode off and no backend, calls
surface as `AppException` and the UI shows a real error state.

Legend — **Status**: `Mock` = implemented and tested against mock repositories ·
`PENDING` = frontend ready, backend contract required.

---

## 1. Authentication

| Feature | Screen | Operation | Method + route | Request | Response | Auth / role | Error / conflict | Offline | Status |
|---|---|---|---|---|---|---|---|---|---|
| Sign in | `/login` | Exchange credentials | `POST /auth/login` **[proposed]** | `{ email, password }` | `{ access_token, refresh_token?, expires_at?, user{ id, full_name, email, role, club_id?, league_id? } }` | None | `401` → "Incorrect email or password" (mapped to `invalidCredentials`, **not** session-expired) | Not allowed — checkout-style action requires connectivity | Mock / PENDING |
| Restore session | startup | Read persisted session | — (local) | — | — | — | Corrupt payload is discarded, not crashed on | Local | Mock |
| Current user | bootstrap / profile | Refresh profile + role | `GET /auth/me` **[proposed]** | — | `user` object | Bearer | `401` → session expired | Cached session used | Mock / PENDING |
| Sign out | `/profile` | Invalidate + clear | `POST /auth/logout` **[proposed]** | — | — | Bearer | Local credentials are cleared **even if** the server call fails | Local clear | Mock / PENDING |

**Roles** (`user.role`): `super_admin`, `league_organizer`, `club_manager`,
`player`, `viewer`. Unrecognised values resolve to `unknown`, which the
permission layer treats as **no privileges**.

**Backend must**: enforce authorization server-side. Hiding a button in the app
is not authorization.

---

## 2. Fixtures & match detail

| Feature | Screen | Operation | Method + route | Request | Response | Auth / role | Error / conflict | Offline | Status |
|---|---|---|---|---|---|---|---|---|---|
| Leagues | fixtures / standings | List leagues | `GET /leagues` **[proposed]** | — | `[{ id, name, season?, sport?, team_count? }]` | Bearer | — | Falls back to cache | Mock / PENDING |
| Fixtures | `/fixtures` | List + filter | `GET /fixtures?league_id=&status=` **[proposed]** | — | `[{ id, home_team{…}, away_team{…}, kickoff, venue?, status, home_score?, away_score?, minute?, round? }]` | Bearer | Any transport failure → cached list + "Showing cached fixtures" | **Yes** — SQLite cache per `league|filter` key | Mock / PENDING |
| Match detail | `/matches/:matchId` | Single match | `GET /fixtures/:matchId` **[proposed]** | — | `fixture` | Bearer | `404` → "That match could not be found." | Yes — cached per match | Mock / PENDING |
| Timeline | match detail (Timeline tab) | Event history | `GET /fixtures/:matchId/events` **[proposed]** | — | `[{ id, match_id, type, sequence, team_id?, team_name?, player_id?, player_name?, description?, minute?, period?, points?, status, created_at? }]` | Bearer | — | Yes | Mock / PENDING |
| Scoring config | scoring | Sport rules | `GET /fixtures/:matchId/scoring-config` **[proposed]** | — | `{ match_id, sport, allows_correction, periods[], event_types[{ type, label?, points?, requires_player, requires_period, is_correction }] }` | Bearer | Missing config → "Scoring not configured" empty state (no invented rules) | Not cached | Mock / PENDING |
| **Live updates** | match detail | Real-time score | **No contract** | — | — | — | — | — | **PENDING — deliberately not simulated** |

`type` values currently understood: `goal`, `point`, `try`, `wicket`, `card`,
`substitution`, `period_start`, `period_end`, `correction`, `other`. Unknown
values parse to `unknown` and still render.

---

## 3. Standings & clubs

| Feature | Screen | Operation | Method + route | Request | Response | Auth / role | Error / conflict | Offline | Status |
|---|---|---|---|---|---|---|---|---|---|
| Standings | `/standings` | League table | `GET /leagues/:leagueId/standings` **[proposed]** | — | `[{ team_id, team_name, team_short_name?, position, played?, won?, drawn?, lost?, points?, differential?, qualification? }]` | Bearer | — | Yes — cached per league | Mock / PENDING |
| Clubs | roster pickers | List clubs | `GET /clubs` **[proposed]** | — | `[{ id, name, short_name?, league_id?, logo_url?, description?, stats{…}? }]` | Bearer | — | Yes | Mock / PENDING |
| Club profile | `/clubs/:clubId` | Profile | `GET /clubs/:clubId` **[proposed]** | — | `club` | Bearer | `404` → "That club could not be found." | Yes | Mock / PENDING |
| Squad | club profile / roster | Squad list | `GET /clubs/:clubId/roster` **[proposed]** | — | `[{ id, name, club_id, position?, jersey_number?, status, loan_club_id? }]` | Bearer | — | Yes | Mock / PENDING |

**Important**: `qualification` (`qualified` / `in_contention` / `eliminated`) is
rendered **only when the backend supplies it**. The app never derives a points
system or tie-breaker. When absent (as in the cricket demo data) no badge shows.

---

## 4. Squad management

| Feature | Screen | Operation | Method + route | Request | Response | Auth / role | Error / conflict | Offline | Status |
|---|---|---|---|---|---|---|---|---|---|
| Limits | `/clubs/:clubId/roster` | Squad constraints | `GET /clubs/:clubId/roster` **[proposed]** (`limits`) | — | `{ squad_size?, max_squad_size?, transfer_window_open?, position_requirements{}, restrictions[] }` | Bearer | Unknown `transfer_window_open` → **modifications disabled** (fail closed) | Yes | Mock / PENDING |
| Transfer | roster | Move player | `POST /clubs/:clubId/roster/actions` **[proposed]** | `{ action_id, type:"transfer", player_id, destination_club_id, base_version }` | updated `player` | `club_manager`+ | `409` → conflict kept in queue for review; `422` → validation message | **Yes** — queued with stable `action_id` | Mock / PENDING |
| Loan | roster | Loan out | same, `type:"loan"`, `+ return_date` | | updated `player` | `club_manager`+ | as above | **Yes** | Mock / PENDING |
| Release | roster | Release | same, `type:"release"` | | updated `player` | `club_manager`+ | as above | **Yes** | Mock / PENDING |
| **Add player** | — | Create player | **No contract** | — | — | — | — | — | **PENDING — intentionally not built** |

`action_id` doubles as the idempotency key (`Idempotency-Key` header).

---

## 5. Scoring events

| Feature | Screen | Operation | Method + route | Request | Response | Auth / role | Error / conflict | Offline | Status |
|---|---|---|---|---|---|---|---|---|---|
| Submit event | `/matches/:matchId/scoring` | Record event | `POST /fixtures/:matchId/scoring-events` **[proposed]** | `{ action_id, type, team_id, player_id?, points?, period?, minute?, note?, base_version? }` | `match_event` | `club_manager`+ | `409` → conflict preserved; **never** silently dropped | **Yes** — queued, shown as pending | Mock / PENDING |
| Correction | scoring | Compensating event | same endpoint, `type:"correction"` + `corrects_event_id` | | `match_event` | `club_manager`+ | as above | Requires connectivity | Mock / PENDING |

Committed events are **never** edited or deleted by the client; corrections are
compensating events. A queued event is never shown as officially committed.

---

## 6. Store, cart, checkout, receipts

| Feature | Screen | Operation | Method + route | Request | Response | Auth / role | Error / conflict | Offline | Status |
|---|---|---|---|---|---|---|---|---|---|
| Catalogue | `/store` | List products | `GET /products?category=&q=` **[proposed]** | — | `[{ id, name, price, currency, description?, image_url?, category?, stock_quantity?, variants[{ id, name, price?, stock_quantity, sku? }] }]` | Bearer | — | Yes — cached | Mock / PENDING |
| Categories | store filters | Category list | derived from `GET /products` **[proposed]** | — | — | Bearer | — | Yes | Mock / PENDING |
| Product | `/store/product/:id` | Single product | `GET /products/:id` **[proposed]** | — | `product` | Bearer | `404` | Yes | Mock / PENDING |
| Cart | `/cart` | Add / qty / remove | **Local only** | — | — | Bearer | Quantity clamped to known stock | Fully offline | Mock |
| Checkout | `/checkout` | Place order | `POST /orders` **[proposed]** | `{ items:[{ product_id, variant_id?, quantity, unit_price }] }` + `Idempotency-Key` | `{ order{ id, status, payment_status, items[], subtotal, tax, shipping, discount, total, currency, payment_reference }, receipt{…}? }` | Bearer | `409` out-of-stock → "no longer available in that quantity"; `422` declined → "payment was declined, no order created"; repeat of the same key returns the **original** order | **Not allowed** — button disabled offline | Mock / PENDING |
| Order | receipt | Fetch order | `GET /orders/:id` **[proposed]** | — | `order` | Bearer | `404` | Not cached | Mock / PENDING |
| Receipt | `/orders/:id/receipt` | PDF | `GET /orders/:id/receipt` **[proposed]** *(or generate locally)* | — | PDF / `receipt` meta | Bearer | Download failure is reported as a failure — never a fake success | Local generation works offline | Mock (generated) / PENDING |

**Payment**: mock payment only. No card fields are collected and no real charge
is made. If the real provider differs, the failure semantics (`409` / `422`)
must be confirmed.

---

## 7. Offline synchronisation

| Feature | Screen | Operation | Method + route | Request | Response | Auth / role | Error / conflict | Offline | Status |
|---|---|---|---|---|---|---|---|---|---|
| Drain queue | `/sync-status` | Batch push | `POST /sync/batch` **[proposed]** | `{ actions: [ queue rows ] }` + per-action `Idempotency-Key` | per-action `{ action_id, state, message?, server_state? }` | Bearer | `409` → `conflict` (preserved, needs human); `422` → `needs_review` | Core feature | Mock adapter / **PENDING** |

Queue contract requirements the backend must satisfy:

1. **Idempotency** — a repeated `action_id` must not create a second effect.
2. **Ordering** — actions are sent oldest-first; dependent actions must not be
   reordered server-side.
3. **Conflict signalling** — a stale `base_version` must return a distinguishable
   conflict, not a generic `400`.
4. **Partial failure** — one failed action must not invalidate the others.

---

## 8. User profile & permissions

| Feature | Screen | Operation | Method + route | Request | Response | Auth / role | Error / conflict | Offline | Status |
|---|---|---|---|---|---|---|---|---|---|
| Profile | `/profile` | Current user | `GET /auth/me` **[proposed]** | — | `user` | Bearer | `401` → login | Cached session | Mock / PENDING |
| Role | app-wide | Capability gate | — (from `user.role`) | — | — | — | Unknown role → **no privileges** (fail closed) | Local | Mock |
| Preferences | profile | Theme mode | **Local only** | — | — | — | — | Local | Mock |

**Permission matrix in use** (from `AppPermissions`; the backend must confirm or
correct it — this is the frontend's assumption, not a server-verified rule):

| Capability | super_admin | league_organizer | club_manager | player | viewer |
|---|---|---|---|---|---|
| Manage league | ✓ | ✓ | – | – | – |
| Manage roster | ✓ | ✓ | ✓ | – | – |
| Enter scores | ✓ | ✓ | ✓ | – | – |
| Manage store | ✓ | ✓ | – | – | – |
| View sync status | ✓ | ✓ | ✓ | ✓ | – |

---

## 9. Feature checklist (frontend side)

| Screen | Route | Implemented | States covered |
|---|---|---|---|
| Splash | `/splash` | ✓ | loading, init error + retry |
| Login | `/login` | ✓ | validation, loading, disabled, invalid credentials, demo accounts |
| Home | `/home` | ✓ | demo-data banner |
| Fixtures | `/fixtures` | ✓ | loading, populated, empty, filter-empty, error+retry, cached, refresh |
| Match Detail | `/matches/:id` | ✓ | loading, error, not-found, Overview/Timeline tabs, merchandise, role-gated Enter Score |
| Standings | `/standings` | ✓ | loading, populated, empty, error+retry, cached, last-updated, league selector |
| Club Profile | `/clubs/:id` | ✓ | loading, loaded, empty squad, not-found, error, cached |
| Roster | `/clubs/:id/roster` | ✓ | permission-denied, loading, empty, limits, transfer/loan/release + confirmations, offline queueing |
| Scoring | `/matches/:id/scoring` | ✓ | config-driven form, validation, review+confirm, history, corrections, offline queueing |
| Store | `/store` | ✓ | loading, populated, empty, search, categories, cached |
| Product | `/store/product/:id` | ✓ | variant selection, stock, quantity limits, unavailable |
| Cart | `/cart` | ✓ | empty, quantity limits, remove, live totals |
| Checkout | `/checkout` | ✓ | offline block, duplicate-submit guard, out-of-stock, declined, network error |
| Order Receipt | `/orders/:id/receipt` | ✓ | confirmed, PDF generate/share, failure reported |
| Sync Status | `/sync-status` | ✓ | online/offline, queue summary, per-action detail, Sync Now, Retry Failed, conflicts preserved |
| Profile | `/profile` | ✓ | not-signed-in, capabilities, theme, sync entry, sign out with confirmation |

**Not implemented by design** (no backend contract → building them would mean
inventing capabilities): live score streaming, roster "Add player", password
reset, and any real payment integration.
