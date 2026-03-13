# HOODINI — Mark Your Hood.

> A real-time geo-marker app for friends — and a community platform against right-wing extremism.

Built with **Flutter** + **Supabase**. Deployable to the web via **Vercel**, with CI/CD through **GitHub Actions**.

---

## Features

### For Your Crew
- Drop geo-markers on a shared map (long-press or tap ＋)
- Attach text, photos, and emoji tags to markers
- Invite friends via share link — they join and see the same map in real time
- Earn XP for every marker; unlock 7 level tiers from *Ghost* up to *The Hoodini*
- See player movement trails (polylines) on the map

### Community Lobby
- A globally visible, permanent lobby for documenting right-wing symbols
- No account required — just open the app and pin
- Report graffiti, stickers, and Nazi symbols with photo + location
- Content is community-moderated (see `docs/moderation.md`)

### Lobby System
- Create or join lobbies scoped to your city or neighbourhood
- Lobbies are GPS-filtered: only lobbies within ~30 km of your location appear
- Each lobby has a name, description, and optional radius
- The community lobby is always visible regardless of location

### Landing Page
- Static HTML landing page at `/landing` explaining the app
- Served alongside the Flutter web app via Vercel

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter 3.38.7 (web + mobile) |
| State management | flutter_riverpod 2.6.1 |
| Routing | go_router 14.8.1 |
| Map | flutter_map 7.0.2 + OpenStreetMap (no API key) |
| Backend | Supabase (Postgres, Auth, Storage, Realtime) |
| Deployment | Vercel (prebuilt static) |
| CI/CD | GitHub Actions |

---

## Architecture

Feature-first folder structure under `lib/features/`:

```
lib/
  core/           # constants, result type, theme
  features/
    auth/         # anonymous login with nickname + optional email
    lobby/        # lobby list, create, GPS filter
    map/          # map view, marker creation, trails
    marker/       # domain + repository
    geo/          # GPS location provider
    xp/           # XP accumulation + level system
    onboarding/   # first-launch modal slideshow
  shared/
    image_picker/ # conditional import: dart:html (web) / file_picker (native)
```

State is managed via `AsyncNotifier` + Riverpod. Data access uses a repository interface with a Supabase implementation. Errors are surfaced through a `Result<T>` sealed class (`Ok` / `Err`).

---

## Local Development

### Prerequisites

- Flutter 3.38.7 (`flutter --version`)
- A [Supabase](https://supabase.com) project with the migrations applied

### 1. Clone & install

```bash
git clone <your-repo>
cd hoodini
flutter pub get
```

### 2. Configure environment

Copy `run_dev.sh.example` to `run_dev.sh` and fill in your Supabase credentials:

```bash
cp run_dev.sh.example run_dev.sh
# edit run_dev.sh with your SUPABASE_URL and SUPABASE_ANON_KEY
chmod +x run_dev.sh
```

> `run_dev.sh` is gitignored — never commit it.

### 3. Apply Supabase migrations

Run all migrations in order via the Supabase dashboard SQL editor or CLI:

| File | Description |
|---|---|
| `001_initial.sql` | Core schema: players, lobbies, markers, player\_lobbies |
| `002_fix_rls_recursion.sql` | Fix RLS infinite recursion |
| `003_reset_rls.sql` | Clean RLS policies |
| `004_add_xp.sql` | XP column on players |
| `005_add_tags.sql` | Tags array on markers |
| `006_lobby_location.sql` | GPS fields on lobbies + community lobby seed |

### 4. Run

```bash
./run_dev.sh
# or manually:
flutter run -d chrome \
  --dart-define=SUPABASE_URL=<url> \
  --dart-define=SUPABASE_ANON_KEY=<key>
```

---

## Deployment

Pushes to `main` automatically build and deploy to Vercel via GitHub Actions.

### Required GitHub Secrets

| Secret | Description |
|---|---|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Your Supabase anon public key |
| `VERCEL_TOKEN` | Vercel personal access token |

### How it works

1. GitHub Actions checks out the repo and sets up Flutter 3.38.7
2. Runs `flutter build web` with secrets baked in via `--dart-define`
3. Copies `build/web/` into `.vercel/output/static/`
4. Deploys with `vercel deploy --prebuilt` and aliases to `hoodini.vercel.app`

The `.vercel/output/config.json` is committed (needed for `--prebuilt`). The `static/` subdirectory is gitignored since it contains the built artefacts with baked-in credentials.

---

## XP Levels

| Level | Title | XP |
|---|---|---|
| 1 | Ghost | 0 |
| 2 | Street Kid | 50 |
| 3 | Local | 150 |
| 4 | Hood Rat | 350 |
| 5 | Block Boss | 700 |
| 6 | Legend | 1200 |
| 7 | The Hoodini | 2000 |

---

## Community Lobby

The community lobby has a fixed UUID (`00000000-0000-0000-0000-000000000001`) seeded by migration `006`. It is always visible regardless of the user's location. Its purpose is to document right-wing extremist symbols in public space.

See [`docs/moderation.md`](docs/moderation.md) for the planned admin/moderation interface.

---

## Open Source

Built with Flutter & Supabase. OpenStreetMap tiles — no proprietary map API required.
