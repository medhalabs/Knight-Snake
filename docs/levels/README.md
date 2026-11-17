# Levels

## Workflow (mandatory for every level)

1. **Plan** — add/update a row in the roadmap below.
2. **Document** — copy `_TEMPLATE.md` to `level-NNN.md` and fill it in:
   intent, ASCII board, goal, moves, intended solution, star reasoning,
   tutorial, test results, playtest notes, change log.
3. **Build** — write `assets/levels/level_NNN.json` (format below) and run
   `dart run tool/level_solver.dart assets/levels/level_NNN.json`.
   Set the star scores from the solver output (policy below).
4. **Test** — `flutter test test/levels` must pass (file valid, solver wins
   within the move limit, intended solution wins with ≥ the documented stars),
   then play it in Chrome and write playtest notes.

Status values: `planned` → `documented` → `built` → `tested` → `playtested`.

## JSON format (`assets/levels/level_NNN.json`)

```json
{
  "id": 1,
  "name": "First Hop",
  "world": 1,
  "board": [
    "........",
    "........",
    "........",
    "........",
    "....p...",
    "........",
    "........",
    "........"
  ],
  "snake": { "head": "knight", "squares": ["c3"] },
  "goal": { "type": "eatAll" },
  "moveLimit": 4,
  "stars": [60, 80],
  "intended": ["e4"],
  "tutorial": "tapDot"
}
```

| Field | Meaning |
|---|---|
| `id` | level number (1-based), matches the file name |
| `name` | short display name (internal; the game shows no text-heavy UI) |
| `world` | 1–3 |
| `board` | 8 strings of 8 chars, **first string = rank 8**, left char = file a |
| `snake.head` | `knight`, `bishop`, `rook`, `queen` or `king` |
| `snake.squares` | snake squares head first; must be distinct and not on food/rock |
| `goal` | see below |
| `moveLimit` | maximum moves (≥ 1) |
| `stars` | `[twoStarScore, threeStarScore]`, two ≤ three |
| `intended` | the designed solution as destination squares |
| `tutorial` | optional hint id: `tapDot`, `eatChange`, `slide`, `tail`, … |

Board characters: `.` empty · `#` rock · `E` exit · food: `p` pawn, `n` knight,
`b` bishop, `r` rook, `q` queen, `k` king.

Goals:
```json
{ "type": "eatAll" }
{ "type": "eatCount", "count": 3 }
{ "type": "length", "length": 5 }
{ "type": "eatPieces", "pieces": { "queen": 2 } }
{ "type": "reachExit" }
```

## Star score policy
- Run the solver. `best` = best score it finds within the move limit.
- 3★ = `best` rounded down to a multiple of 10. On teaching levels the intended
  solution must reach it (make the intended line the best line).
- 2★ = about 70 % of 3★, rounded to 10, and above the plain "just win" score
  where possible.
- Random-bot win rate is recorded in the level doc as a difficulty hint.

## Roadmap (30 levels)

Difficulty 1 (easy) – 5 (hard). Sawtooth: each world rises, dips after a new
idea, and ends with a boss.

| # | Name | Goal | New idea | Heads | Diff | Status |
|---|---|---|---|---|---|---|
| 1 | First Hop | eatAll (1 pawn) | tap a dot to jump | N | 1 | playtested |
| 2 | Hop Hop Hop | eatAll (3 pawns) | chain jumps; pawns keep your head | N | 1 | playtested |
| 3 | Slide Away | eatAll | eat a bishop → slide diagonally | N→B | 2 | playtested |
| 4 | Rock Garden | eatAll | rocks block slides | N,B | 2 | tested |
| 5 | Mind Your Tail | length 6 | your body blocks you (until the tail moves) | N,B | 3 | tested |
| 6 | Tower Power | eatAll | rook straight lines | N,R | 2 | planned |
| 7 | Find the Door | reachExit | exit square | N,R | 2 | planned |
| 8 | Royal Feast | eatPieces queen:1 | queen = bishop + rook | N,B,Q | 3 | planned |
| 9 | Tiny Steps | eatAll | king steps one square (a "downgrade") | N,K | 3 | planned |
| 10 | BOSS: Grand Tour | eatAll | mix of everything, tight moves | all | 4 | planned |
| 11 | Pick One | eatCount 3 | choosing which piece to eat first | N,B,R | 2 | planned |
| 12 | Tail Chase | length 6 | landing on your tail square | K,N | 3 | planned |
| 13 | Long Body | length 8 | plan room for a long body | N,B | 3 | planned |
| 14 | Twin Queens | eatPieces queen:2 | specific-piece goals | Q,N | 3 | planned |
| 15 | Narrow Hall | reachExit | corridors of rocks | R,B | 2 | planned |
| 16 | Combo Feast | eatAll | combos for 3★ | Q,R | 3 | planned |
| 17 | Switch Back | eatAll | eat a knight to escape slides | B,N | 3 | planned |
| 18 | Locked Door | reachExit | eat a piece to reach the exit | N,R,K | 4 | planned |
| 19 | Spiral | length 9 | coil without trapping yourself | K,Q | 4 | planned |
| 20 | BOSS: Castle Keep | eatAll | world 2 mix, tight limit | all | 5 | planned |
| 21 | Star Hop | eatCount 4 | knight-only maze | N | 2 | planned |
| 22 | Diagonal Dance | eatAll | colour-bound bishop puzzles | B,N | 3 | planned |
| 23 | Rook Rush | eatPieces rook:3 | long straight runs | R | 3 | planned |
| 24 | Body Wall | reachExit | use your own body as a wall | Q,K | 4 | planned |
| 25 | Queen's Gambit | eatAll | give up a queen head on purpose | Q,K,N | 4 | planned |
| 26 | Gentle Moon | eatAll | breather level | N,B | 2 | planned |
| 27 | Crowded Sky | length 10 | many choices, few safe | all | 4 | planned |
| 28 | Last Door | reachExit | long route, exact moves | all | 4 | planned |
| 29 | Comet Combo | eatAll | combo chains for 3★ | Q,R,B | 5 | planned |
| 30 | BOSS: Checkmate | eatAll | everything, full board | all | 5 | planned |

Worlds: 1 Meadow (1–10), 2 Castle (11–20), 3 Starry Sky (21–30).
