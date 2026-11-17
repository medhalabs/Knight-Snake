# Level 002 — Hop Hop Hop

| World | Goal | Move limit | Heads | Difficulty | Status |
|---|---|---|---|---|---|
| 1 | eatAll (3 pawns) | 5 | N | 1 | tested |

## Intent
Chain jumps. Pawns are snacks: you grow but stay a knight. Eating on
back-to-back moves shows the first `COMBO ×2` / `×3`.

## Starting board
```
8 . . . . . . . .
7 . . . . . . . .
6 . . . . . p . .
5 . . . p . . . .
4 . . . . . . . .
3 . . p . . . . .
2 . . . . . . . .
1 . S . . . . . .
  a b c d e f g h
```
Start head: knight at b1 · length 1.

## Goal and moves
Eat all 3 pawns in 5 moves. Each pawn is exactly one jump from the previous
one, so following the dots that sit on pawns wins.

## Intended solution
`c3 → d5 → f6`. Score: 10×1 + 10×2 + 10×3 = 60, + 2 unused × 50 = **160**.

## Star reasoning
Solver best 160 (exhaustive). 3★ = 160 (straight chain), 2★ = 110 (one
detour or a broken combo), 1★ = any win.

## Tutorial
`chain`: after the first eat, the dot on the next pawn glows a little brighter.

## Test results
```
result: WIN · best 160 · line c3 d5 f6 · fewest 3 · 1605 states, exhaustive
random bot: 1.4% wins · intended: won, 160, 3★
```

## Playtest notes
2026-11-17 · Chrome 375×812 · c3 → d5 → f6: `+20` and NICE! on the 2nd eat, 160 = 3★, NEW BEST!. Fix made: NICE! covered the `COMBO ×2` label, praise words moved to the top of the board.

## Change log
| Date | Change |
|---|---|
| 2026-11-17 | Created; stars [110, 160] from solver |
