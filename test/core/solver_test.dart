import 'package:flutter_test/flutter_test.dart';
import 'package:knightsnake/core/game_state.dart';
import 'package:knightsnake/core/goal.dart';
import 'package:knightsnake/core/level.dart';
import 'package:knightsnake/core/piece.dart';
import 'package:knightsnake/core/solver.dart';

import 'helpers.dart';

Level levelOf(List<String> rows, String head, String squares, int limit) =>
    Level(
      id: 1,
      name: 't',
      world: 1,
      board: boardFromRows(rows),
      snake: snake(PieceType.fromName(head), squares),
      goal: const EatAllGoal(),
      moveLimit: limit,
      stars: const [0, 0],
    );

void main() {
  test('finds a one-move win with the moves bonus', () {
    final l = levelOf(_rows({'e4': 'p'}), 'knight', 'c3', 3);
    final r = solveLevel(l);
    expect(r.won, isTrue);
    expect(r.bestLine, [sq('e4')]);
    expect(r.fewestMoves, 1);
    expect(r.bestScore, 10 + 2 * 50);
    expect(r.exhaustive, isTrue);
  });

  test('prefers the higher-scoring order (combo on the queen)', () {
    // King a1 can eat a2 (pawn) then a3 (queen) in 2 moves; limit 2.
    final l = levelOf(_rows({'a2': 'p', 'a3': 'q'}), 'king', 'a1', 2);
    final r = solveLevel(l);
    expect(r.won, isTrue);
    expect(r.bestScore, 10 + 90 * 2);
    expect(l.play(r.bestLine).isWon, isTrue);
  });

  test('reports no win when the limit is too small', () {
    final l = levelOf(_rows({'h8': 'p'}), 'king', 'a1', 3);
    final r = solveLevel(l);
    expect(r.won, isFalse);
    expect(r.bestLine, isEmpty);
    expect(r.fewestMoves, isNull);
  });

  test('beam pruning marks result non-exhaustive', () {
    final l = levelOf(_rows({'h8': 'p'}), 'queen', 'a1', 3);
    final r = solveLevel(l, beamWidth: 5);
    expect(r.exhaustive, isFalse);
  });

  test('random bot win rate is deterministic and in range', () {
    final l = levelOf(_rows({'e4': 'p'}), 'knight', 'c3', 2);
    final a = randomBotWinRate(l, games: 200, seed: 5);
    final b = randomBotWinRate(l, games: 200, seed: 5);
    expect(a, b);
    expect(a, inInclusiveRange(0.0, 1.0));
    expect(a, greaterThan(0));
  });

  test('already-won start returns immediately', () {
    final s = stateOf(board: boardWith({}), snake: snake(PieceType.king, 'a1'));
    final won = s.copyWith(status: GameStatus.won);
    expect(solve(won).won, isTrue);
  });
}

List<String> _rows(Map<String, String> tiles) => boardWith(tiles).toRows();
