import 'package:flutter_test/flutter_test.dart';
import 'package:knightsnake/core/game_state.dart';
import 'package:knightsnake/core/goal.dart';
import 'package:knightsnake/core/piece.dart';
import 'package:knightsnake/core/rules.dart';
import 'package:knightsnake/core/scoring.dart';

import 'helpers.dart';

void main() {
  test('plain move: head moves, tail frees, no score', () {
    final s = stateOf(
      board: boardWith({'h8': 'p'}),
      snake: snake(PieceType.king, 'b2 a1'),
    );
    final r = Rules.apply(s, sq('c3'));
    expect(names(r.state.snake.squares), names(sqs('c3 b2')));
    expect(r.state.snake.squares.first, sq('c3'));
    expect(r.state.score, 0);
    expect(r.state.movesUsed, 1);
    expect(r.state.status, GameStatus.playing);
    expect(r.events.single, isA<MovedEvent>());
  });

  test('eating grows the snake and changes the head', () {
    final s = stateOf(
      board: boardWith({'b3': 'b', 'h8': 'p'}),
      snake: snake(PieceType.knight, 'a1'),
    );
    final r = Rules.apply(s, sq('b3'));
    expect(r.state.snake.squares, sqs('b3 a1'));
    expect(r.state.snake.head, PieceType.bishop);
    expect(r.state.board[sq('b3')].isFood, isFalse);
    expect(r.state.score, PieceType.bishop.points);
    expect(r.state.eaten[PieceType.bishop], 1);
    expect(r.events.whereType<AteEvent>().single.multiplier, 1);
    expect(r.events.whereType<HeadChangedEvent>().single.to, PieceType.bishop);
  });

  test('eating a pawn keeps the head type', () {
    final s = stateOf(
      board: boardWith({'b3': 'p', 'h8': 'p'}),
      snake: snake(PieceType.knight, 'a1'),
    );
    final r = Rules.apply(s, sq('b3'));
    expect(r.state.snake.head, PieceType.knight);
    expect(r.state.snake.length, 2);
    expect(r.events.whereType<HeadChangedEvent>(), isEmpty);
  });

  test('combo multiplies consecutive eats and resets on a plain move', () {
    final s = stateOf(
      board: boardWith({'a2': 'p', 'a3': 'p', 'a5': 'p', 'h8': 'p'}),
      snake: snake(PieceType.king, 'a1'),
    );
    var st = Rules.apply(s, sq('a2')).state; // 10 ×1
    final r2 = Rules.apply(st, sq('a3')); // 10 ×2
    st = r2.state;
    expect(r2.events.whereType<AteEvent>().single.multiplier, 2);
    expect(st.score, 10 + 20);
    st = Rules.apply(st, sq('a4')).state; // no eat → reset
    expect(st.streak, 0);
    st = Rules.apply(st, sq('a5')).state; // 10 ×1
    expect(st.score, 40);
  });

  test('combo multiplier is capped', () {
    expect(Scoring.multiplier(9), Scoring.maxCombo);
    expect(Scoring.eatPoints(PieceType.queen, 3), 270);
  });

  test('landing on the tail square is legal and frees it', () {
    // King d4, body d3, tail e3 → move onto e3.
    final s = stateOf(
      board: boardWith({'h8': 'p'}),
      snake: snake(PieceType.king, 'd4 d3 e3'),
    );
    final r = Rules.apply(s, sq('e3'));
    expect(r.state.snake.squares, sqs('e3 d4 d3'));
  });

  test('illegal move throws', () {
    final s = stateOf(
      board: boardWith({'h8': 'p'}),
      snake: snake(PieceType.king, 'a1'),
    );
    expect(() => Rules.apply(s, sq('c3')), throwsArgumentError);
  });

  test('win adds unused-moves bonus and stops play', () {
    final s = stateOf(
      board: boardWith({'b3': 'p'}),
      snake: snake(PieceType.knight, 'a1'),
      moveLimit: 4,
    );
    final r = Rules.apply(s, sq('b3'));
    expect(r.state.status, GameStatus.won);
    expect(r.state.bonus, 3 * Scoring.perUnusedMove);
    expect(r.state.totalScore, 10 + 150);
    expect(r.events.last, isA<WonEvent>());
    expect(Rules.legalMoves(r.state), isEmpty);
    expect(() => Rules.apply(r.state, sq('c1')), throwsStateError);
  });

  test('running out of moves loses', () {
    final s = stateOf(
      board: boardWith({'h8': 'p'}),
      snake: snake(PieceType.king, 'a1'),
      moveLimit: 1,
    );
    final r = Rules.apply(s, sq('a2'));
    expect(r.state.status, GameStatus.lostOutOfMoves);
    expect(r.events.last, isA<LostEvent>());
  });

  test('winning on the last move beats running out', () {
    final s = stateOf(
      board: boardWith({'a2': 'p'}),
      snake: snake(PieceType.king, 'a1'),
      moveLimit: 1,
    );
    expect(Rules.apply(s, sq('a2')).state.status, GameStatus.won);
  });

  test('trapped when no legal moves remain', () {
    // King in corner a1 after moving; b1, b2 rocks; a2 body after move.
    final s = stateOf(
      board: boardWith({'b1': '#', 'b2': '#', 'b3': '#', 'a4': '#', 'h8': 'p'}),
      snake: snake(PieceType.king, 'a2 a3'),
    );
    // Eat nothing: move a2 → a1; snake becomes a1 a2; a2 is the tail → legal!
    final r = Rules.apply(s, sq('a1'));
    expect(r.state.status, GameStatus.playing);
    // Longer snake: head a2, body a3 + tail elsewhere → a1 then trapped.
    final s2 = stateOf(
      board: boardWith({'b1': '#', 'b2': '#', 'b3': '#', 'a4': '#', 'h8': 'p'}),
      snake: snake(PieceType.king, 'a2 a3 c5'),
    );
    final r2 = Rules.apply(s2, sq('a1'));
    expect(r2.state.status, GameStatus.lostTrapped);
  });

  test('reach exit goal', () {
    final s = stateOf(
      board: boardWith({'a3': 'E'}),
      snake: snake(PieceType.rook, 'a1'),
      goal: const ReachExitGoal(),
      moveLimit: 3,
    );
    expect(Rules.apply(s, sq('a2')).state.status, GameStatus.playing);
    expect(Rules.apply(s, sq('a3')).state.status, GameStatus.won);
  });

  test('start() marks an already-trapped level as lost', () {
    final s = stateOf(
      board: boardWith({'b3': '#', 'c2': '#', 'h8': 'p'}),
      snake: snake(PieceType.knight, 'a1'),
    );
    expect(Rules.start(s).status, GameStatus.lostTrapped);
  });

  test('an already-complete goal earns its unused-move bonus', () {
    final s = stateOf(
      board: boardWith({'b3': '#', 'c2': '#'}),
      snake: snake(PieceType.knight, 'a1'),
      moveLimit: 3,
    );
    final started = Rules.start(s);
    expect(started.status, GameStatus.won);
    expect(started.bonus, 3 * Scoring.perUnusedMove);
    expect(Rules.legalMoves(started), isEmpty);
  });
}
