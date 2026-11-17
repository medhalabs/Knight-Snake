# Level 005 — Mind Your Tail

| World | Goal | Move limit | Heads | Difficulty | Status |
|---|---|---|---|---|---|
| 1 | length 6 | 6 | N, B | 3 | tested |

## Intent
Your body is a wall — but it moves. The snake starts at length 3. A pawn
(e2) sits right behind the body; as a bishop you can't slide through your own
body, but once the tail has moved on, the road opens.

## Starting board
```
8 . . . . p . . .
7 . . . . . . . .
6 . . . . . . . .
5 . b . . . . . .
4 . . . S . . . .
3 . . . s . . . .
2 . . . s p . . .
1 . . . . . . . .
  a b c d e f g h
```
Start head: knight at d4 · body d3, d2 (length 3).

## Goal and moves
Reach length 6 (eat all 3 pieces) in 6 moves.

## Intended solution
`b5` (become bishop) `→ e8` (eat pawn, combo ×2) `→ h5` (step aside; the
body follows) `→ e2` (the d3 body square is gone now, eat the pawn).
Score: 30 + 20 + 10 = 60, + 2 × 50 = **160**.
Also 160: `e2 → c3 → b5 → e8` (eat the pawn as a knight first).

## Star reasoning
Solver best 160 (exhaustive); two different lines reach it, which is good for
a "think ahead" level. 3★ = 160, 2★ = 110.

## Tutorial
`body`: the first time a slide is cut short by the body, the blocking body
segment flashes.

## Test results
```
result: WIN · best 160 · line e2 c3 b5 e8 · fewest 4 · 20884 states, exhaustive
random bot: 0.6% wins · intended: won, 160, 3★
```

## Playtest notes
Not yet played by hand; automated tests only (solver + intended line). Play in Chrome next session.

## Change log
| Date | Change |
|---|---|
| 2026-11-17 | Draft goal length 5 was a 2-move win; raised to 6 so the tail lesson matters. Stars [110, 160] |
