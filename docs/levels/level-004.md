# Level 004 — Rock Garden

| World | Goal | Move limit | Heads | Difficulty | Status |
|---|---|---|---|---|---|
| 1 | eatAll | 6 | N → B | 2 | tested |

## Intent
Rocks block slides. The direct diagonal d2 → h6 is blocked by the f4 rock, so
the bishop has to go around. (A knight would just jump over it.)

## Starting board
```
8 . . . . . . . .
7 . . . . . . p .
6 . . . . . . . p
5 . . . . . . . .
4 . # . . . # . .
3 . . . . . . # .
2 . . . b . . . .
1 . S . . . . . .
  a b c d e f g h
```
Start head: knight at b1 · length 1.

## Goal and moves
Eat the bishop and both pawns in 6 moves. Rocks at b4, f4 and g3 close the
short cuts on both sides; the open road is the long a1–h8 diagonal.

## Intended solution
`d2` (become bishop) `→ c3` (step onto the long diagonal) `→ g7` (eat pawn)
`→ h6` (eat pawn, combo ×2). Score: 30 + 10 + 20 = 60, + 2 × 50 = **160**.

## Star reasoning
Solver best 160 (exhaustive), same as the intended line. 3★ = 160,
2★ = 110 (one extra move).

## Tutorial
`rocks`: if the player taps a square behind a rock, the rock wobbles.

## Test results
```
result: WIN · best 160 · line d2 c3 g7 h6 · fewest 4 · 2180 states, exhaustive
random bot: 0.9% wins · intended: won, 160, 3★
```

## Playtest notes
Not yet played by hand; automated tests only (solver + intended line). Play in Chrome next session.

## Change log
| Date | Change |
|---|---|
| 2026-11-17 | First draft needed 7 moves (too hard); moved pawns, added g3 rock, limit 8 → 6. Stars [110, 160] |
