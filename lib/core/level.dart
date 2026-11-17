import 'dart:convert';

import 'board.dart';
import 'game_state.dart';
import 'goal.dart';
import 'piece.dart';
import 'rules.dart';
import 'snake.dart';
import 'square.dart';

/// A level definition (format: docs/levels/README.md).
class Level {
  Level({
    required this.id,
    required this.name,
    required this.world,
    required this.board,
    required this.snake,
    required this.goal,
    required this.moveLimit,
    required this.stars,
    this.intended = const [],
    this.tutorial,
  }) {
    _validate();
  }

  factory Level.fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Level JSON must be an object');
    }
    return Level.fromJson(decoded);
  }

  factory Level.fromJson(Map<String, Object?> json) {
    T field<T>(String key) {
      final v = json[key];
      if (v is! T) throw FormatException('Level field "$key" missing/invalid');
      return v;
    }

    final snakeJson = field<Map<String, Object?>>('snake');
    final head = snakeJson['head'];
    final squares = snakeJson['squares'];
    if (head is! String || squares is! List<Object?>) {
      throw const FormatException('Level "snake" needs head and squares');
    }
    return Level(
      id: field<int>('id'),
      name: field<String>('name'),
      world: field<int>('world'),
      board: Board.fromRows(field<List<Object?>>('board').cast<String>()),
      snake: Snake(
        head: PieceType.fromName(head),
        squares: [for (final s in squares) Square.parse(s! as String)],
      ),
      goal: Goal.fromJson(field<Map<String, Object?>>('goal')),
      moveLimit: field<int>('moveLimit'),
      stars: field<List<Object?>>('stars').cast<int>().toList(),
      intended: [
        for (final s in (json['intended'] as List<Object?>?) ?? const [])
          Square.parse(s! as String),
      ],
      tutorial: json['tutorial'] as String?,
    );
  }

  final int id;
  final String name;
  final int world;
  final Board board;
  final Snake snake;
  final Goal goal;
  final int moveLimit;

  /// `[twoStarScore, threeStarScore]`.
  final List<int> stars;
  final List<Square> intended;
  final String? tutorial;

  void _validate() {
    if (id < 1) throw const FormatException('id must be ≥ 1');
    if (world < 1 || world > 3) throw const FormatException('world 1–3');
    if (moveLimit < 1) throw const FormatException('moveLimit must be ≥ 1');
    if (stars.length != 2 || stars[0] > stars[1] || stars[0] < 0) {
      throw const FormatException('stars must be [two, three], two ≤ three');
    }
    for (final s in snake.squares) {
      final t = board[s];
      if (t.isFood || t.isRock) {
        throw FormatException('Snake square $s is on food/rock');
      }
    }
    if (goal is ReachExitGoal && board.exitSquare == null) {
      throw const FormatException('reachExit level needs an E square');
    }
  }

  /// Fresh game state for this level.
  GameState start() => Rules.start(
    GameState(board: board, snake: snake, goal: goal, moveLimit: moveLimit),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'world': world,
    'board': board.toRows(),
    'snake': {
      'head': snake.head.name,
      'squares': [for (final s in snake.squares) s.name],
    },
    'goal': goal.toJson(),
    'moveLimit': moveLimit,
    'stars': stars,
    'intended': [for (final s in intended) s.name],
    if (tutorial != null) 'tutorial': tutorial,
  };

  /// Plays [moves] from the start; returns the final state.
  /// Throws if a move is illegal or the game ends early.
  GameState play(List<Square> moves) {
    var state = start();
    for (final m in moves) {
      state = Rules.apply(state, m).state;
    }
    return state;
  }

  /// ASCII picture (rank 8 on top) with the snake drawn as S/s.
  String toAscii() {
    final buf = StringBuffer();
    for (var rank = 7; rank >= 0; rank--) {
      buf.write('${rank + 1} ');
      for (var f = 0; f < 8; f++) {
        final sq = Square(f, rank);
        final c = sq == snake.headSquare
            ? 'S'
            : snake.occupies(sq)
            ? 's'
            : board[sq].char;
        buf.write(f == 7 ? c : '$c ');
      }
      buf.writeln();
    }
    buf.write('  a b c d e f g h');
    return buf.toString();
  }
}
