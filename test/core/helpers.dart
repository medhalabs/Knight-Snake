import 'package:knightsnake/core/board.dart';
import 'package:knightsnake/core/game_state.dart';
import 'package:knightsnake/core/goal.dart';
import 'package:knightsnake/core/piece.dart';
import 'package:knightsnake/core/snake.dart';
import 'package:knightsnake/core/square.dart';

Square sq(String name) => Square.parse(name);

List<Square> sqs(String names) =>
    names.split(' ').where((s) => s.isNotEmpty).map(Square.parse).toList();

Snake snake(PieceType head, String squares) =>
    Snake(head: head, squares: sqs(squares));

/// Board with the given `square: char` entries, everything else empty.
Board boardWith(Map<String, String> tiles) {
  var b = Board.empty();
  tiles.forEach((name, c) => b = b.withTile(sq(name), Tile.fromChar(c)));
  return b;
}

GameState stateOf({
  required Board board,
  required Snake snake,
  Goal goal = const EatAllGoal(),
  int? moveLimit,
}) => GameState(board: board, snake: snake, goal: goal, moveLimit: moveLimit);

/// Sorted square names for easy comparison.
List<String> names(Iterable<Square> squares) =>
    squares.map((s) => s.name).toList()..sort();

Board boardFromRows(List<String> rows) => Board.fromRows(rows);
