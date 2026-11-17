# Level 001 — First Hop

| World | Goal | Move limit | Heads | Difficulty | Status |
|---|---|---|---|---|---|
| 1 | eatAll (1 pawn) | 3 | N | 1 | tested |

## Intent
The very first touch. Learn: dots show where you can go; tap one to jump.
A pawn sits on one of the dots, so the first tap a curious child makes has a
good chance of eating it.

## Starting board
```
8 . . . . . . . .
7 . . . . . . . .
6 . . . . . . . .
5 . . . . . . . .
4 . . . . . . . .
3 . . p . . . . .
2 . . . . . . . .
1 . S . . . . . .
  a b c d e f g h
```
Start head: knight at b1 · body: none (length 1).

## Goal and moves
Eat all food (one pawn). 3 moves, so a wrong first tap can still be fixed:
b1 → a3 → b5 → c3 or b1 → d2 → e4 → c3 both win in exactly 3.

## Intended solution
`c3` — one jump. Score: pawn 10 + 2 unused moves × 50 = **110**.

## Star reasoning
Solver best 110 (exhaustive). 3★ = 110 (win in 1 move), 2★ = 60. c3 is
either 1 or 3 jumps away, so in practice it is 3★ (1 move) or 1★ (3 moves).

## Tutorial
`tapDot`: a pointing hand pulses over the c3 dot until the first tap.

## Test results
```
result: WIN · best 110 · line c3 · fewest moves 1 · 62 states, exhaustive
random bot: 42.0% wins · intended: won, 110, 3★
```
`flutter test test/levels`: pass.

## Playtest notes
2026-11-17 · Chrome 375×812 + 1280×800 · Tapped c3 first try: `+10`, CHECKMATE! + confetti, result card counted `+50 × 2`, 3★. Also lost on purpose (a3 → c4 → e5): out-of-moves card, undo worked. Feels good; very short, as intended.

## Change log
| Date | Change |
|---|---|
| 2026-11-17 | Created; stars [60, 110] from solver |
