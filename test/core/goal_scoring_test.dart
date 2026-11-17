import 'package:flutter_test/flutter_test.dart';
import 'package:knightsnake/core/goal.dart';
import 'package:knightsnake/core/piece.dart';
import 'package:knightsnake/core/scoring.dart';

import 'helpers.dart';

void main() {
  group('goals', () {
    final base = stateOf(
      board: boardWith({'h8': 'q', 'h1': 'p'}),
      snake: snake(PieceType.knight, 'a1 a2'),
    );

    test('eatAll counts remaining food', () {
      expect(const EatAllGoal().progress(base), (0, 2));
      expect(const EatAllGoal().isComplete(base), isFalse);
      final done = base.copyWith(board: boardWith({}));
      expect(const EatAllGoal().isComplete(done), isTrue);
    });

    test('eatCount, length', () {
      final s = base.copyWith(eaten: {PieceType.pawn: 2});
      expect(const EatCountGoal(3).progress(s), (2, 3));
      expect(const EatCountGoal(2).isComplete(s), isTrue);
      expect(const LengthGoal(2).isComplete(base), isTrue);
      expect(const LengthGoal(3).progress(base), (2, 3));
    });

    test('eatPieces caps per type', () {
      const g = EatPiecesGoal({PieceType.queen: 2, PieceType.rook: 1});
      final s = base.copyWith(eaten: {PieceType.queen: 3});
      expect(g.progress(s), (2, 3));
      expect(g.isComplete(s), isFalse);
      final s2 = s.copyWith(eaten: {PieceType.queen: 2, PieceType.rook: 1});
      expect(g.isComplete(s2), isTrue);
    });

    test('JSON round-trip and errors', () {
      final goals = <Goal>[
        const EatAllGoal(),
        const ReachExitGoal(),
        const EatCountGoal(3),
        const LengthGoal(5),
        const EatPiecesGoal({PieceType.queen: 2}),
      ];
      for (final g in goals) {
        expect(Goal.fromJson(g.toJson()).toJson(), g.toJson());
      }
      expect(() => Goal.fromJson({'type': 'nope'}), throwsFormatException);
      expect(
        () => Goal.fromJson({'type': 'eatCount', 'count': 0}),
        throwsFormatException,
      );
      expect(
        () =>
            Goal.fromJson({'type': 'eatPieces', 'pieces': <String, Object?>{}}),
        throwsFormatException,
      );
    });
  });

  group('scoring', () {
    test('moves bonus', () {
      expect(Scoring.movesBonus(3), 150);
      expect(Scoring.movesBonus(-1), 0);
    });

    test('stars', () {
      int s(int score, {bool won = true}) =>
          Scoring.stars(won: won, score: score, thresholds: [100, 200]);
      expect(s(500, won: false), 0);
      expect(s(10), 1);
      expect(s(100), 2);
      expect(s(199), 2);
      expect(s(200), 3);
    });
  });
}
