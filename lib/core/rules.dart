import 'board.dart';
import 'game_state.dart';
import 'moves.dart';
import 'piece.dart';
import 'scoring.dart';
import 'square.dart';

/// Something that happened during a move, for the UI to animate.
sealed class GameEvent {
  const GameEvent();
}

class MovedEvent extends GameEvent {
  const MovedEvent(this.from, this.to, this.head);
  final Square from;
  final Square to;

  /// Head type that made the move (decides arc vs slide animation).
  final PieceType head;
}

class AteEvent extends GameEvent {
  const AteEvent(this.square, this.piece, this.points, this.multiplier);
  final Square square;
  final PieceType piece;
  final int points;
  final int multiplier;
}

class HeadChangedEvent extends GameEvent {
  const HeadChangedEvent(this.from, this.to);
  final PieceType from;
  final PieceType to;
}

class WonEvent extends GameEvent {
  const WonEvent(this.unusedMoves, this.bonus);
  final int unusedMoves;
  final int bonus;
}

class LostEvent extends GameEvent {
  const LostEvent(this.status);
  final GameStatus status;
}

class MoveResult {
  const MoveResult(this.state, this.events);
  final GameState state;
  final List<GameEvent> events;
}

/// Applies the game rules (GAME_PLAN §2–3).
abstract final class Rules {
  /// Legal destinations, or none when the game is over.
  static List<Square> legalMoves(GameState state) =>
      state.isOver ? const [] : legalMovesFor(state.board, state.snake);

  /// Initial status check (a level could start trapped; treat as a loss).
  static GameState start(GameState state) {
    if (state.goal.isComplete(state)) {
      return state.copyWith(status: GameStatus.won);
    }
    if (legalMovesFor(state.board, state.snake).isEmpty) {
      return state.copyWith(status: GameStatus.lostTrapped);
    }
    return state;
  }

  /// Moves the head to [to]. Throws [ArgumentError] if the move is illegal.
  static MoveResult apply(GameState state, Square to) {
    if (state.isOver) throw StateError('Game is over');
    if (!legalMoves(state).contains(to)) {
      throw ArgumentError.value(to, 'to', 'illegal move');
    }
    final events = <GameEvent>[];
    final from = state.snake.headSquare;
    final oldHead = state.snake.head;
    events.add(MovedEvent(from, to, oldHead));

    final tile = state.board[to];
    var board = state.board;
    var score = state.score;
    var streak = 0;
    var eaten = state.eaten;
    var newHead = oldHead;

    if (tile.isFood) {
      final piece = tile.piece!;
      streak = state.streak + 1;
      final points = Scoring.eatPoints(piece, streak);
      score += points;
      board = board.withTile(to, Tile.empty);
      eaten = {...eaten, piece: (eaten[piece] ?? 0) + 1};
      if (!piece.keepsHead) newHead = piece;
      events.add(AteEvent(to, piece, points, Scoring.multiplier(streak)));
      if (newHead != oldHead) events.add(HeadChangedEvent(oldHead, newHead));
    }

    final snake = state.snake.moveTo(to, grow: tile.isFood, newHead: newHead);
    var next = state.copyWith(
      board: board,
      snake: snake,
      movesUsed: state.movesUsed + 1,
      score: score,
      streak: streak,
      eaten: eaten,
    );

    if (next.goal.isComplete(next)) {
      final unused = next.movesLeft ?? 0;
      final bonus = Scoring.movesBonus(unused);
      next = next.copyWith(status: GameStatus.won, bonus: bonus);
      events.add(WonEvent(unused, bonus));
    } else if (next.movesLeft != null && next.movesLeft! <= 0) {
      next = next.copyWith(status: GameStatus.lostOutOfMoves);
      events.add(const LostEvent(GameStatus.lostOutOfMoves));
    } else if (legalMovesFor(next.board, next.snake).isEmpty) {
      next = next.copyWith(status: GameStatus.lostTrapped);
      events.add(const LostEvent(GameStatus.lostTrapped));
    }
    return MoveResult(next, events);
  }
}
