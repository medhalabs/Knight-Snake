import 'package:flutter_test/flutter_test.dart';
import 'package:knightsnake/core/board.dart';
import 'package:knightsnake/core/moves.dart';
import 'package:knightsnake/core/piece.dart';

import 'helpers.dart';

List<String> movesOf(Board b, PieceType head, String squares) =>
    names(legalMovesFor(b, snake(head, squares)));

void main() {
  final empty = Board.empty();

  group('knight', () {
    test('8 jumps from the centre, 2 from a corner', () {
      expect(movesOf(empty, PieceType.knight, 'd4'), [
        'b3', 'b5', 'c2', 'c6', 'e2', 'e6', 'f3', 'f5', //
      ]);
      expect(movesOf(empty, PieceType.knight, 'a1'), ['b3', 'c2']);
    });

    test('jumps over body, food and rocks but not onto rock/body', () {
      final b = boardWith({'d5': '#', 'e5': 'q', 'b3': '#'});
      // b3 is a rock; d5/e5 do not block the jump.
      expect(movesOf(b, PieceType.knight, 'd4 c4 c2'), isNot(contains('b3')));
      expect(movesOf(b, PieceType.knight, 'd4 d3 c2'), contains('c2'));
      expect(
        movesOf(b, PieceType.knight, 'd4 d3 c2 c1'),
        isNot(contains('c2')),
      );
      expect(movesOf(b, PieceType.knight, 'd4'), contains('e6'));
    });
  });

  group('king', () {
    test('one step any direction', () {
      expect(movesOf(empty, PieceType.king, 'd4'), [
        'c3', 'c4', 'c5', 'd3', 'd5', 'e3', 'e4', 'e5', //
      ]);
      expect(movesOf(empty, PieceType.king, 'h8'), ['g7', 'g8', 'h7']);
    });

    test('cannot step onto body except the tail', () {
      // Head d4, body d3, tail e3: d3 blocked, e3 (tail) allowed.
      final m = movesOf(empty, PieceType.king, 'd4 d3 e3');
      expect(m, isNot(contains('d3')));
      expect(m, contains('e3'));
    });
  });

  group('sliders', () {
    test('rook covers rank and file on an empty board', () {
      expect(movesOf(empty, PieceType.rook, 'a1'), hasLength(14));
      expect(movesOf(empty, PieceType.bishop, 'd4'), hasLength(13));
      expect(movesOf(empty, PieceType.queen, 'd4'), hasLength(27));
    });

    test('stop before rocks', () {
      final b = boardWith({'a4': '#'});
      final m = movesOf(b, PieceType.rook, 'a1');
      expect(m, containsAll(['a2', 'a3']));
      expect(m, isNot(contains('a4')));
      expect(m, isNot(contains('a5')));
    });

    test('can stop on food but not pass it', () {
      final b = boardWith({'c3': 'p'});
      final m = movesOf(b, PieceType.bishop, 'a1');
      expect(m, ['b2', 'c3']);
    });

    test('blocked by body; tail is landable but not passable', () {
      // Rook head a1, body b1 b2, tail a3 (squares need not be adjacent).
      final m = movesOf(empty, PieceType.rook, 'a1 b1 b2 a3');
      expect(m, ['a2', 'a3']);
    });

    test('exit square is passable and landable', () {
      final b = boardWith({'a3': 'E'});
      expect(movesOf(b, PieceType.rook, 'a1'), containsAll(['a3', 'a8']));
    });
  });

  test('length-1 snake can move freely', () {
    expect(movesOf(empty, PieceType.king, 'a1'), ['a2', 'b1', 'b2']);
  });

  test('pawn head is rejected', () {
    expect(() => snake(PieceType.pawn, 'a1'), throwsArgumentError);
  });
}
