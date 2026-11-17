# Knight Snake — Game Plan

An original 2D mobile puzzle game: **chess × snake**. You are a snake on an 8×8
chess board. Your head moves like a chess piece. Whatever piece you eat becomes
your new head, and your body grows by one.

- Audience: children (about 6+) to adults. Readable without text, colorful, calm.
- Platforms: Android and iOS from one Flutter codebase; web build for testing.
- Business: free, hybrid monetization (rewarded ads + small in-app purchases).

## 1. Market check (17 Nov 2026)

Searched Google Play, the App Store and the web for "chess snake", "knight
snake" and "snake head moves like a chess piece".

- No mobile app on Google Play or the App Store combines chess movement with
  snake growth. "Dice Master: Snake Chess" is a snakes-and-ladders dice game.
- Knight puzzle apps exist (Knight Squares, The Knight Watch, Knight's Graph),
  but none has a growing body.
- **Closest:** a free web game, "Chess Snake" on chessplex.com: a real-time
  joystick snake on a chess board with a head piece picked before the game.
  Also a fan "Chess Mod" for Google's snake doodle (eating a piece gives its
  move). Neither is a mobile app, neither is turn-based or level-based.
- Our difference: **turn-based puzzle levels** where the head **changes type
  when it eats**, plus goals, stars and a kid-friendly look. Re-check before
  store submission.

## 2. Core rules (v1, turn-based)

### Board
8×8, squares named like chess: files a–h (left→right), ranks 1–8
(bottom→top). Each square is one of:

| Tile | Meaning |
|---|---|
| empty | free square |
| food | an enemy chess piece: pawn, knight, bishop, rook, queen or king |
| rock | obstacle; nothing can land on or slide through it |
| exit | goal square on "reach the exit" levels; behaves like empty otherwise |

### Snake
An ordered list of squares, head first. Length L = number of squares. The body
is the head's previous L−1 landing squares (one square per move, **not** the
squares a slider passed over). Every level sets the start squares and head type.

### A turn
1. The game highlights every legal destination.
2. The player taps a highlighted square (or drags the head onto it).
3. The head moves there. If it ate, the snake grows (tail stays). Otherwise the
   tail square frees up.
4. Win/lose is checked.

### Legal moves
| Head | Moves |
|---|---|
| Knight | the 8 L-jumps; jumps over anything |
| Bishop | slides diagonally any distance |
| Rook | slides straight any distance |
| Queen | bishop + rook |
| King | one step in any of 8 directions |

- Sliders cannot pass through body, rocks or food. They can **stop on** food
  (eat it) but not go beyond it.
- The destination must be on the board, not a rock, and not a body square.

**Decision — tail square.** The head **may land on the tail square** (the tail
leaves this turn, as in classic snake). It may **not slide through** it. Landing
on the tail never eats (the tail square has no food), so the tail always leaves.
A snake of length 1 has no body to hit.

**Decision — pawns.** Pawns are "snacks": eating one gives +1 length and points
but **keeps the current head type**. There is no pawn head in v1 (green is kept
for pawn food highlights and a future pawn head skin).

### Eating
Landing on food eats it: +1 length, food removed, head becomes that piece type
(except pawns, above).

### Win and lose
- **Win** as soon as the level goal is complete (checked first, including at
  the start of a level). A goal already complete at the start earns the usual
  bonus for all unused moves.
- **Lose — trapped:** no legal moves.
- **Lose — out of moves:** the move limit is used up and the goal is not done.
- Every level has a move limit (it drives stars). Endless has none.

### Goals (one per level)
| Goal | Done when |
|---|---|
| `eatCount` N | N pieces eaten (pawns count) |
| `length` N | snake length ≥ N |
| `eatPieces` {type: n} | at least n of each listed type eaten |
| `reachExit` | head lands on the exit square |
| `eatAll` | no food left on the board |

## 3. Scoring and stars

Piece points (stronger = more):

| pawn | knight | bishop | rook | king | queen |
|---|---|---|---|---|---|
| 10 | 30 | 30 | 50 | 60 | 90 |

- **Combo:** eating on consecutive moves builds a streak. The k-th eat in a row
  scores piece points × k (capped at ×5). Shown as `+60 COMBO ×2`. A move
  without eating resets the streak.
- **Moves bonus:** on a win, +50 per unused move, counted one by one on the
  result card.
- Score always counts up; it never jumps.
- **Stars:** ★ = win. ★★ / ★★★ = reach the level's 2- and 3-star scores (set
  from solver results, see `docs/levels/README.md`). In the HUD, star 1 lights
  only on a win; a bar fills toward 3 stars as you score.
- A **?** button explains scoring and shows this level's star scores.
- Teaching levels: the intended solution earns 3★.

## 4. Modes

1. **Levels** (main): 30 levels, 3 worlds of 10, one new idea at a time,
   sawtooth difficulty, boss levels at 10/20/30.
2. **Endless** (unlocks after level 5): food keeps appearing (seeded RNG),
   survive and score as long as possible; no move limit.
3. **Daily puzzle** (later): one seeded puzzle per day, same for everyone.
4. **Rush** (later): timed variant.

## 5. Look and feel

- Dark arcade presentation with original vector art drawn in code.
- Board: beveled violet tiles, coordinates on the edges, diamonds for open
  destinations and mint corners for captures.
- Head and food: faceted tokens with chess silhouettes drawn as paths.
  The connected body takes on the head color after a transformation.
- Feedback: movement trails, landing rings, capture sparks and score text,
  a combo counter, haptics, and a star reveal after a win.
- Responsive: phone portrait and tablet/desktop landscape; board max ~620 px.
- Accessibility: reduced-motion option; every piece has a distinct silhouette,
  never color alone; large touch targets (≥ 44 px).

## 6. Audience and child safety

- Neutral age gate on first launch (birth year picker, no default year).
- Under 13: child-directed ad requests only, no tracking or personalized ads,
  no analytics IDs, purchases behind a parent gate (simple adult question).
- Only SDKs in the Google Play Families Self-Certified Ads SDK list; COPPA and
  GDPR-K settings on. Not listed in the App Store "Kids" category.
- No chat, no user-generated content, no external links without a parent gate.

## 7. Monetization (final phase, designed in now)

- Rewarded ads: undo a crash (step back one move), +3 extra moves.
- Interstitials only between levels after level 10, at most one every 3 levels
  and never more than once per 3 minutes. Never after a loss streak.
- IAP: Remove Ads, coin packs, head/body skins. Prices shown clearly.
- No loot boxes, no fake timers, no energy system, no pay-to-win.
- All of this sits behind interfaces in `lib/services` with fakes for tests.

## 8. Release plan

| Phase | Content |
|---|---|
| 0 | Docs, Flutter project, `lib/core` + tests, solver CLI |
| 1 | Levels 1–5, playable Flame board, HUD, result card, finale (web + Android) |
| 2 | Levels 6–30, level select, local save, audio, haptics, settings |
| 3 | Endless mode, polish, reduced motion, tablet layout pass |
| 4 | Age gate, parent gate, ads + IAP (fakes → real SDKs), privacy policy |
| 5 | Store listings, Codemagic iOS build, closed test, launch |

## 9. Rule change log

| Date | Change |
|---|---|
| 2026-11-17 | v1 rules written: tail-square landing allowed, pawns keep head type |
| 2026-11-17 | Apply the normal unused-move bonus when a level's goal is already complete at the start |
