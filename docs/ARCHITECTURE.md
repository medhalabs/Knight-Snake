# Knight Snake — Architecture

## Stack
- Flutter 3.50+ / Dart 3.14+ (Android, iOS, web from one codebase).
- Flame (1.38+) draws the board, snake and effects.
- Material widgets come from `package:material_ui` (`flutter/material.dart` is
  deprecated since Flutter 3.47). Never import `package:flutter/material.dart`.
- Day-to-day testing: Chrome and Android. iOS builds later via Codemagic.

## Layers

```
lib/
  core/      pure Dart game logic — no Flutter, no Flame, no dart:io/dart:ui
  game/      Flame components: render core state, turn taps into moves
  features/  screens and widgets (home, level select, play, result, settings)
  services/  ads, purchases, analytics, storage, audio, haptics
             (each: abstract interface + fake + real implementation)
  app.dart, main.dart
assets/levels/   level_NNN.json
test/            mirrors lib/core (plus level tests and a few widget tests)
tool/            level_solver.dart, serve_web.dart
docs/            plans, architecture, levels
```

### The core rule
`lib/core` is **pure, deterministic Dart**:
- No imports of `package:flutter`, `package:flame`, `dart:io`, `dart:ui`,
  `dart:html`. (`dart:convert`, `dart:math` for non-random math are fine.)
- All randomness goes through `XorShift32` (seeded, 32-bit masked) so results
  are identical on the Dart VM and on the web (JS numbers).
- State is immutable value objects. `applyMove(state, to)` returns a new state
  plus a list of events (moved, ate, combo, won, lost) that the UI animates.
- A test (`test/core/purity_test.dart`) fails if any core file imports a
  forbidden library.

### Flow of one turn
```
tap/drag (game/) → GameController.tryMove(square)
  → core.Rules.legalMoves(state) contains square?
  → core.Rules.apply(state, square) → MoveResult(newState, events)
  → controller stores newState, plays events as animations/sound/haptics
  → HUD widgets rebuild from controller state (ValueNotifier)
```
Flame and widgets never change game state directly; they only send moves.

## Core modules (`lib/core`)
| File | Purpose |
|---|---|
| `square.dart` | `Square` (file 0–7, rank 0–7), parse/print `a1`–`h8` |
| `piece.dart` | `PieceType` enum, points, `keepsHead` (pawn) |
| `board.dart` | immutable 8×8 tiles: empty, food(piece), rock, exit |
| `snake.dart` | ordered squares head-first + head type |
| `moves.dart` | legal destination generation per head type |
| `goal.dart` | goal types, progress and completion check |
| `game_state.dart` | board + snake + counters + status |
| `rules.dart` | apply a move, eat, grow, combo scoring, win/lose |
| `scoring.dart` | point table, combo, end bonus breakdown, stars |
| `level.dart` | `Level` model and JSON parse/serialize |
| `rng.dart` | `XorShift32` |
| `solver.dart` | BFS / beam search for wins and best score |
| `random_bot.dart` | random legal-move player for win-rate checks |

## Services
Each service is an abstract class plus a `Fake…` for tests/dev. Real SDK
implementations arrive in the final phase. The app gets services through a
single `Services` object created in `main.dart`, so tests can swap fakes in.

| Service | Fake behavior |
|---|---|
| `StorageService` | in-memory map |
| `AudioService` / `HapticsService` | no-op, records calls |
| `AnalyticsService` | records events; disabled for under-13 |
| `AdsService` | rewarded ad always "completes" |
| `PurchaseService` | in-memory entitlements |

## Testing
- Unit tests for every core module (`test/core/…`).
- Level tests (`test/levels/level_files_test.dart`): every JSON parses, the
  solver wins within the move limit, the intended solution wins with at least
  the documented stars.
- Widget flow test (`test/features/play_flow_test.dart`): opens level 1 and wins it at
  phone (390×844) and landscape (1280×800) sizes. Add
  `--dart-define=SCREENSHOTS=true --update-goldens` to save screenshots to
  `test/features/screenshots/` (git-ignored; not compared in CI).
- CLI: `dart run tool/level_solver.dart assets/levels/level_001.json`.

## Tooling
- `analysis_options.yaml`: strict casts/inference/raw types, `flutter_lints`
  plus extra rules.
- `dart format` enforced in CI.
- GitHub Actions (`.github/workflows/ci.yml`): format check, analyze, test,
  build debug APK.
- `dart run tool/serve_web.dart` serves `build/web` on `http://localhost:8080`
  (no Python needed).

## Conventions
- Files stay small (~300 lines). Split when they grow.
- Any rule change updates `docs/GAME_PLAN.md`, the tests and the code together.
