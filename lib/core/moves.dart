import 'board.dart';
import 'piece.dart';
import 'snake.dart';
import 'square.dart';

const _knightJumps = [
  (1, 2), (2, 1), (2, -1), (1, -2), //
  (-1, -2), (-2, -1), (-2, 1), (-1, 2),
];
const _straight = [(0, 1), (1, 0), (0, -1), (-1, 0)];
const _diagonal = [(1, 1), (1, -1), (-1, -1), (-1, 1)];
const _allDirs = [..._straight, ..._diagonal];

/// Legal destination squares for the snake's head (see GAME_PLAN §2).
///
/// - Destinations must be on the board, not a rock, and not a snake square,
///   except the tail square (the tail leaves this turn).
/// - Sliders stop at the first rock, food or snake square; they may land on
///   food or the tail but never pass through them.
/// - Knights jump over anything.
List<Square> legalMovesFor(Board board, Snake snake) {
  final from = snake.headSquare;
  final result = <Square>[];

  bool canLand(Square s) {
    if (board[s].isRock) return false;
    if (!snake.occupies(s)) return true;
    return snake.length > 1 && s == snake.tailSquare;
  }

  void steps(List<(int, int)> dirs) {
    for (final (df, dr) in dirs) {
      final s = from.offset(df, dr);
      if (s != null && canLand(s)) result.add(s);
    }
  }

  void slides(List<(int, int)> dirs) {
    for (final (df, dr) in dirs) {
      var s = from.offset(df, dr);
      while (s != null) {
        if (!canLand(s)) break;
        result.add(s);
        // Food and the tail can be landed on but not passed.
        if (board[s].isFood || snake.occupies(s)) break;
        s = s.offset(df, dr);
      }
    }
  }

  switch (snake.head) {
    case PieceType.knight:
      steps(_knightJumps);
    case PieceType.king:
      steps(_allDirs);
    case PieceType.bishop:
      slides(_diagonal);
    case PieceType.rook:
      slides(_straight);
    case PieceType.queen:
      slides(_allDirs);
    case PieceType.pawn:
      throw StateError('Pawn cannot be a head in v1');
  }
  return result;
}
