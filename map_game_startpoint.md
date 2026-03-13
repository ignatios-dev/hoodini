# Map Game – Product & Technical Startpoint

## Confirmed Decisions (MVP)

| Topic | Decision |
|---|---|
| Backend | **Supabase** |
| Identity | **Anonymous nickname + optional email** (no OAuth for now) |
| Map engine | **flutter_map + OpenStreetMap** (no API key, works on web + mobile, migrate to MapLibre later) |
| State management | **Riverpod** |
| Navigation | **go_router** |
| Platforms | **Android, iOS, Web** (web first for sharing with friends, app stores later) |
| Backend wiring | Start with **mock repositories**, wire Supabase in Phase 2 |
| Supabase project | Not yet created – create before Phase 2 |

---

## Vision
A mobile multiplayer map game where players join a lobby, explore the real world around them, and interact with places and each other through location-based actions.

The core idea is to turn the physical world into a lightweight social game layer.

## Core MVP Concept
Players open the app, join a lobby, and see a map around them with a radius of roughly **20 km**.

Inside that area they can:

1. **Place a GPS marker** with:
   - photo
   - short text
   - optional visibility rules
2. **Create a call-to-action flag**
   - for example: "meet here", "come to this spot", "group event starting here"
3. See markers and flags from other players depending on the game rules.

## Example Gameplay Modes

### 1. Shared Exploration
Players discover and leave messages, photos, and signals in the world.

### 2. Delayed Discovery
A marker is only revealed when another player physically reaches that location.

### 3. Group Coordination
Players use flags to gather at a point for social or game-based activities.

## Later Feature Ideas

### Catch Me If You Can
One player becomes the target. Others try to find or catch them within a defined area and time window.

### Territory / Crew Control
Players or crews color areas of the map to claim influence or territory.

### Hidden Drops
Players can leave virtual items or clues at a GPS location.

### Time-Limited Events
Temporary activities appear for a certain time, such as:
- meetups
- scavenger hunts
- races
- area capture challenges

## Complexity Assessment

## Overall
This is **very buildable**, but the complexity depends heavily on how far the game mechanics go.

A basic social location game MVP is **medium complexity**.
A real-time multiplayer territory game with background tracking is **high complexity**.

## Complexity by Feature

### A. Join lobby + show map in 20 km radius
**Complexity: Low to Medium**

You need:
- authentication or guest identity
- lobby model
- location permission
- map rendering
- query backend objects in map bounds

This is straightforward for an MVP.

### B. GPS marker with image + text
**Complexity: Medium**

You need:
- create marker UI
- camera/gallery upload
- backend storage for image
- moderation concept
- visibility rules

This is still very manageable.

### C. Marker visible only when player reaches location
**Complexity: Medium to High**

You need:
- proximity checks
- hidden/revealed state per player
- anti-cheat considerations
- backend logic or trusted client logic

This is where the app starts to become a real game instead of a social map.

### D. Call-to-action group flag
**Complexity: Medium**

You need:
- flag type / category
- optional expiry time
- visibility to lobby or crew
- player notifications

Quite feasible.

### E. Catch Me If You Can
**Complexity: High**

You need:
- live player positions or position updates
- game session rules
- fairness rules
- anti-spoofing thinking
- battery-aware tracking
- event timers

This is a real multiplayer game mode and should come later.

### F. Territory / crew coloring
**Complexity: High**

You need:
- world partitioning into cells
- ownership rules
- rendering claimed zones
- conflict mechanics
- backend aggregation
- scaling strategy

This is one of the hardest parts and should not be in v1.

## Recommended MVP Scope

Build this first:

### MVP v1
- sign in or anonymous nickname
- join or create lobby
- show player location on map
- show map content in a 20 km area
- place marker with text and optional image
- place CTA flag
- markers visible immediately to lobby members
- simple feed/list of nearby activity

### v1.5
- marker expiration
- comments / reactions
- hidden markers unlocked by proximity
- basic report system

### v2
- crews / groups
- territory cells
- timed events
- catch mode
- achievements

## Recommended Architecture

## Frontend
- **Flutter** for mobile cross-platform
- Map engine:
  - preferred: **MapLibre**
  - alternative: **flutter_map**

Why:
- more flexibility than Google Maps
- better fit for game overlays and custom styling
- easier to evolve into territory systems and fog-of-war concepts

## Backend
Choose one of these:

### Option A – Supabase
Good for fast MVPs.

Pros:
- auth
- postgres
- storage
- realtime
- easy setup

Cons:
- some game logic may outgrow it later

### Option B – Firebase
Good if you want strong mobile ecosystem support.

Pros:
- easy auth
- storage
- notifications
- mature mobile tooling

Cons:
- querying geospatial data can get awkward depending on model

### Option C – Custom backend
For example:
- Kotlin / Ktor
- NestJS
- Laravel

Pros:
- full control
- better long-term game logic ownership

Cons:
- slower to ship MVP

### Recommendation
For speed: **Flutter + Supabase + MapLibre**

## Data Model Draft

### User
```json
{
  "id": "uuid",
  "nickname": "Ignatz",
  "avatarUrl": "string|null",
  "createdAt": "timestamp"
}
```

### Lobby
```json
{
  "id": "uuid",
  "name": "Offenburg Crew",
  "visibility": "public|private",
  "createdBy": "userId",
  "createdAt": "timestamp"
}
```

### LobbyMember
```json
{
  "lobbyId": "uuid",
  "userId": "uuid",
  "role": "owner|member",
  "joinedAt": "timestamp"
}
```

### Marker
```json
{
  "id": "uuid",
  "lobbyId": "uuid",
  "createdBy": "userId",
  "type": "note|photo|hidden_note|cta_flag",
  "lat": 48.47,
  "lng": 7.94,
  "text": "Meet here at 8",
  "imageUrl": "string|null",
  "visibilityMode": "instant|proximity_unlock",
  "unlockRadiusMeters": 50,
  "expiresAt": "timestamp|null",
  "createdAt": "timestamp"
}
```

### MarkerReveal
```json
{
  "markerId": "uuid",
  "userId": "uuid",
  "revealedAt": "timestamp"
}
```

### PlayerLocationEvent
For MVP this should be minimal.
```json
{
  "userId": "uuid",
  "lobbyId": "uuid",
  "lat": 48.47,
  "lng": 7.94,
  "capturedAt": "timestamp"
}
```

Do **not** store high-frequency raw location data forever in v1.
Keep only what you need.

## Map / Geo Model Recommendations

## Start simple
Do not begin with full territory control.

For MVP:
- use plain points for markers
- use radius-based visibility
- use map bounds query for nearby content

For territory later:
- use **H3** or another hex/cell system
- each cell can be:
  - neutral
  - player-owned
  - crew-owned
  - contested

This will make area coloring much easier than free-form polygons.

## Real-Time vs Near-Real-Time

Do not build fully live multiplayer first unless it is essential.

Recommended for MVP:
- markers and flags update in near-real-time
- player positions are optional or coarse
- refresh every few seconds or on movement

Why:
- easier
- cheaper
- less battery usage
- less creepy
- fewer privacy issues

## Privacy and Safety
This is critical for any location-based social game.

You need at minimum:
- block/report tools
- rate limits for marker creation
- image moderation strategy
- no precise public live location unless explicitly intended
- clear visibility rules
- delete/edit own content
- terms for unsafe or abusive location content

Strong recommendation:
Do **not** expose exact live player locations by default in early versions.
Instead expose:
- markers
- events
- approximate zones
- opt-in game sessions

## Anti-Cheat / Abuse Risks
Even early on, think about:
- fake GPS / spoofing
- spam markers
- inappropriate images
- stalking behavior
- griefing through territory systems

For MVP, accept that anti-cheat will be basic.
Do not overengineer it initially.

## Suggested Tech Stack

## Mobile App
- Flutter
- Riverpod or Bloc for state management
- Dio or Supabase SDK / Firebase SDK
- MapLibre Flutter integration
- image_picker
- permission_handler
- geolocator

## Backend / Infra
- Supabase Auth
- Postgres
- Storage bucket for images
- Realtime subscriptions
- Edge functions for server-side rules

## Nice-to-have later
- push notifications
- background location updates
- geofencing
- moderation pipeline
- admin dashboard

## Product Specification Questions

Answering the following questions will clarify the product direction and allow AI agents and developers to refine this document.

### 1. Target Audience
- Who is the primary target group?
  - friends in the same city
  - local communities
  - tourists
  - gamers
  - outdoor explorers
- Is the app intended to be:
  - casual social
  - competitive game
  - exploration tool
- Age group?
- Expected player density (small groups vs many strangers)?

### 2. Geographic Scope
- Is the world:
  - global
  - city-based
  - lobby-based areas
- Does each lobby operate in:
  - one city
  - dynamic location
  - fixed radius
- Should players only see activity within:
  - 20 km
  - configurable radius
  - entire map

### 3. Identity Model
- Are users:
  - anonymous nicknames
  - registered accounts
  - OAuth (Google/Apple)?
- Can players change their nickname?
- Do players have profiles?
- Do players have reputation or levels?

### 4. Lobby Model
- Who can create a lobby?
- Lobby types:
  - public
  - private
  - invite-only
- Max players per lobby?
- Can players join multiple lobbies?
- Are lobbies location locked?

### 5. Player Visibility
- Can players see each other on the map?
- If yes, how precisely?
  - exact location
  - approximate area
  - only during events
- Should player positions be:
  - real-time
  - periodic
  - hidden unless needed

### 6. Marker System
Questions about GPS markers:

- Marker types:
  - text note
  - photo note
  - hidden note
  - challenge
  - CTA flag

- Marker visibility:
  - visible instantly
  - visible when nearby
  - visible only to crew

- Should markers:
  - expire automatically
  - stay permanently
  - have limited lifetime

- Can markers be:
  - edited
  - deleted
  - reported

- Max markers per player?

### 7. Image Content
- Are images:
  - optional
  - required for certain marker types
- Should images be moderated?
- Should AI moderation be used?

### 8. Call-To-Action Flags
- What kinds of CTA flags exist?
  - meetup
  - challenge
  - event
  - race

- Should CTA flags:
  - expire
  - trigger notifications
  - allow RSVP

### 9. Discovery Mechanics
How do players discover content?

- Automatic discovery when near
- Manual scanning
- Map exploration
- Hidden clues

Unlock distance?

Example:

- 50m
- 100m
- 200m

### 10. Territory Mechanics (Future)
If territory control exists:

- Territory units:
  - grid
  - hex cells
  - polygons

- Ownership:
  - individual
  - crew

- How does territory change?
  - presence
  - battles
  - missions

- Does territory decay over time?

### 11. Crew / Team System
- Can players create crews?
- Crew size limits?
- Can crews claim territory?
- Crew chat?

### 12. Game Modes
Possible game modes:

- exploration
- catch me if you can
- scavenger hunt
- territory war
- event mode

Questions:

- Are modes lobby-specific?
- Can multiple modes run simultaneously?

### 13. Anti-Abuse
What protections exist?

- spam prevention
- fake GPS detection
- reporting system
- moderator tools

### 14. Privacy
Location privacy rules:

- do not show live player location
- show approximate location
- show location only in game modes

Questions:

- Can players hide location?
- Should location history be stored?

### 15. Retention Mechanics
What makes players come back?

Possible systems:

- achievements
- exploration statistics
- daily quests
- crew competition

### 16. Monetization (Optional)
Is monetization planned?

Options:

- cosmetic upgrades
- premium markers
- event hosting
- subscriptions

### 17. Scaling
Expected scale?

- dozens of players
- hundreds
- thousands

Questions:

- Is the first version local only?
- Should backend support global scale?

## Recommended Product Framing
A strong first framing could be:

> A local multiplayer exploration game where players leave messages, signals, and challenges in the real world for others to discover.

This is clearer and easier to build than trying to pitch everything at once.

## Development Status

| Phase | Status |
|---|---|
| Phase 1 – Foundation | ✅ DONE |
| Phase 2 – Supabase Backend + Deployment | ✅ DONE – https://hoodini.vercel.app |
| Phase 2.5 – World Objects (image upload, marker detail) | 🔜 Next |
| Phase 3 – Social Layer | ⬜ Planned |
| Phase 4 – Game Mechanics | ⬜ Planned |
| Phase 5 – Expansion | ⬜ Planned |

## Development Plan

### Phase 1 – Foundation
- bootstrap Flutter app
- user identity
- location permission
- render map
- join/create lobby

### Phase 2 – World Objects
- create markers
- upload images
- fetch markers in visible radius
- show marker detail page

### Phase 3 – Social Layer
- CTA flags
- list of lobby activity
- notifications or in-app prompts

### Phase 4 – Game Mechanics
- hidden markers
- proximity unlock
- points / rewards

### Phase 5 – Expansion
- crews
- territory cells
- game modes
- catch me if you can

## AI Coding Agent Guidance
Use these implementation rules:

1. Keep the codebase **modular and domain-first**.
2. Separate concerns clearly:
   - auth
   - lobby
   - map
   - markers
   - geo
   - realtime
3. Prefer simple, explicit data models over clever abstractions.
4. Build local-first UI flows where possible.
5. Do not implement advanced real-time tracking before marker flows work end to end.
6. Add mock repositories before wiring the full backend.
7. Keep game rules configurable.
8. Avoid coupling the domain model to a specific map provider.

## Suggested Folder Structure
```text
lib/
  app/
  core/
  features/
    auth/
    lobby/
    map/
    marker/
    cta_flag/
    geo/
    profile/
  shared/
```

More detailed example:

```text
lib/
  app/
    app.dart
    router.dart
  core/
    error/
    result/
    constants/
  features/
    auth/
      domain/
      application/
      infrastructure/
      presentation/
    lobby/
      domain/
      application/
      infrastructure/
      presentation/
    map/
      presentation/
      application/
    marker/
      domain/
      application/
      infrastructure/
      presentation/
    geo/
      domain/
      application/
      infrastructure/
    cta_flag/
      domain/
      application/
      infrastructure/
      presentation/
  shared/
    widgets/
    theme/
```

## First Milestone Definition
A good first milestone is:

> A player can open the app, join a lobby, see a map centered on their location, create a text marker, and another player in the same lobby can see it.

If this works well, the project is alive.

## What Is Hard vs Easy

### Easier than it seems
- map rendering
- join lobby
- creating markers
- image upload
- fetching nearby content

### Harder than it seems
- background tracking
- exact live multiplayer
- territory control
- privacy-safe social location features
- moderation
- anti-spoofing

## Final Recommendation
Do not start with territory gameplay or live chase modes.
Start with:
- local map
- lobbies
- markers
- CTA flags
- hidden discovery

That already gives you a meaningful, testable product.

Once that loop works, you can evolve it into a much deeper game.

