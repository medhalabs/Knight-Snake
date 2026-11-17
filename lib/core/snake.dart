import 'piece.dart';
import 'square.dart';

/// The player's snake: ordered squares (head first) and the head's piece type.
class Snake {
  Snake({required this.head, required List<Square> squares})
    : squares = List.unmodifiable(squares) {
    if (squares.isEmpty) throw ArgumentError('Snake needs at least 1 square');
    if (!head.canBeHead) throw ArgumentError('$head cannot be a head');
    if (squares.toSet().length != squares.length) {
      throw ArgumentError('Snake squares must be distinct: $squares');
    }
  }

  /// Head piece type (how the head moves).
  final PieceType head;

  /// Squares, head first, tail last.
  final List<Square> squares;

  Square get headSquare => squares.first;
  Square get tailSquare => squares.last;
  int get length => squares.length;

  bool occupies(Square s) => squares.contains(s);

  /// Moves the head to [to]. When [grow] is true the tail stays.
  Snake moveTo(Square to, {required bool grow, PieceType? newHead}) {
    final next = <Square>[to, ...squares];
    if (!grow) next.removeLast();
    return Snake(head: newHead ?? head, squares: next);
  }

  String get key => '${head.letter}:${squares.map((s) => s.index).join(',')}';

  @override
  bool operator ==(Object other) => other is Snake && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => '${head.name} ${squares.join(' ')}';
}
