import 'package:flutter_test/flutter_test.dart';
import 'package:knightsnake/core/piece.dart';
import 'package:knightsnake/core/square.dart';

void main() {
  group('Square', () {
    test('parses and prints chess names', () {
      expect(Square.parse('a1'), const Square(0, 0));
      expect(Square.parse('H8'), const Square(7, 7));
      expect(Square.parse('e4').name, 'e4');
      expect(Square.parse('e4').index, 3 * 8 + 4);
    });

    test('rejects bad names', () {
      for (final bad in ['', 'a', 'a9', 'i1', 'a0', 'a10']) {
        expect(() => Square.parse(bad), throwsFormatException, reason: bad);
      }
    });

    test('index round-trips for all 64 squares', () {
      expect(Square.all, hasLength(64));
      for (var i = 0; i < 64; i++) {
        expect(Square.fromIndex(i).index, i);
      }
      expect(() => Square.fromIndex(64), throwsRangeError);
    });

    test('offset stays on the board', () {
      expect(Square.parse('a1').offset(1, 2), Square.parse('b3'));
      expect(Square.parse('a1').offset(-1, 0), isNull);
      expect(Square.parse('h8').offset(0, 1), isNull);
    });

    test('equality and hash', () {
      expect(Square.parse('c3'), Square.parse('c3'));
      expect({Square.parse('c3'), const Square(2, 2)}, hasLength(1));
    });
  });

  group('PieceType', () {
    test('letters and names round-trip', () {
      for (final p in PieceType.values) {
        expect(PieceType.fromLetter(p.letter), p);
        expect(PieceType.fromLetter(p.letter.toUpperCase()), p);
        expect(PieceType.fromName(p.name), p);
      }
      expect(() => PieceType.fromLetter('x'), throwsFormatException);
    });

    test('points grow with strength; pawn keeps head', () {
      expect(PieceType.pawn.points, lessThan(PieceType.knight.points));
      expect(PieceType.queen.points, greaterThan(PieceType.rook.points));
      expect(PieceType.pawn.keepsHead, isTrue);
      expect(PieceType.pawn.canBeHead, isFalse);
      expect(PieceType.values.where((p) => p.keepsHead), [PieceType.pawn]);
    });
  });
}
