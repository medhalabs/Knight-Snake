# Level 003 — Slide Away

| World | Goal | Move limit | Heads | Difficulty | Status |
|---|---|---|---|---|---|
| 1 | eatAll | 5 | N → B | 2 | tested |

## Intent
The core hook: **eat a piece, become that piece**. Eating the bishop turns the
head teal and the dots change to long diagonals. The pawns are far away on one
diagonal, so sliding is obviously the fast way.

## Starting board
```
8 . . . . . . . p
7 . . . . . . . .
6 . . . . . p . .
5 . . . . . . . .
4 . . . . . . . .
3 . . b . . . . .
2 . . . . . . . .
1 . S . . . . . .
  a b c d e f g h
```
Start head: knight at b1 · length 1.

## Goal and moves
Eat all (bishop + 2 pawns) in 5 moves. The f6 pawn blocks the slide to h8,
which shows "you can stop on food but not slide past it".

## Intended solution
`c3` (eat bishop, become bishop) `→ f6` (slide, eat pawn) `→ h8` (eat pawn).
Score: 30×1 + 10×2 + 10×3 = 80, + 2 × 50 = **180**.

## Star reasoning
Solver best 180 (exhaustive). 3★ = 180, 2★ = 120.

## Tutorial
`eatChange`: when the head changes, the head token does a big pop and the new
move dots ripple out from it along the diagonals.

## Test results
```
result: WIN · best 180 · line c3 f6 h8 · fewest 3 · 2668 states, exhaustive
random bot: 0.5% wins · intended: won, 180, 3★
```

## Playtest notes
2026-11-17 · Chrome 375×812 · Eating the bishop turned the head teal and the dots switched to diagonals, h8 correctly not reachable past the f6 pawn. Change is very readable.

## Change log
| Date | Change |
|---|---|
| 2026-11-17 | Created; stars [120, 180] from solver |
