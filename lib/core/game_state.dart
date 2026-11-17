import 'board.dart';
import 'goal.dart';
import 'piece.dart';
import 'snake.dart';

enum GameStatus { playing, won, lostTrapped, lostOutOfMoves }

/// Immutable snapshot of a game in progress.
class GameState {
  GameState({
    required this.board,
    required this.snake,
    required this.goal,
    this.moveLimit,
    this.movesUsed = 0,
    this.score = 0,
    this.streak = 0,
    this.bonus = 0,
    Map<PieceType, int> eaten = const {},
    this.status = GameStatus.playing,
  }) : eaten = Map.unmodifiable(eaten);

  final Board board;
  final Snake snake;
  final Goal goal;

  /// Max moves, or null for no limit (endless).
  final int? moveLimit;
  final int movesUsed;

  /// Points from eating (without the end bonus).
  final int score;

  /// Number of consecutive moves that ate, ending with the last move.
  final int streak;

  /// Unused-moves bonus, set when the level is won.
  final int bonus;

  /// Pieces eaten by type.
  final Map<PieceType, int> eaten;
  final GameStatus status;

  int get eatenTotal => eaten.values.fold(0, (a, b) => a + b);
  int? get movesLeft => moveLimit == null ? null : moveLimit! - movesUsed;
  int get totalScore => score + bonus;
  bool get isOver => status != GameStatus.playing;
  bool get isWon => status == GameStatus.won;

  GameState copyWith({
    Board? board,
    Snake? snake,
    int? movesUsed,
    int? score,
    int? streak,
    int? bonus,
    Map<PieceType, int>? eaten,
    GameStatus? status,
  }) => GameState(
    board: board ?? this.board,
    snake: snake ?? this.snake,
    goal: goal,
    moveLimit: moveLimit,
    movesUsed: movesUsed ?? this.movesUsed,
    score: score ?? this.score,
    streak: streak ?? this.streak,
    bonus: bonus ?? this.bonus,
    eaten: eaten ?? this.eaten,
    status: status ?? this.status,
  );

  /// Key for search deduplication: everything that affects future play.
  String get key =>
      '${board.key}|${snake.key}|$movesUsed|$streak|'
      '${PieceType.values.map((p) => eaten[p] ?? 0).join(',')}';
}
