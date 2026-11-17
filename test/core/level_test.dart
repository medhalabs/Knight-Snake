import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:knightsnake/core/game_state.dart';
import 'package:knightsnake/core/goal.dart';
import 'package:knightsnake/core/level.dart';
import 'package:knightsnake/core/piece.dart';

import 'helpers.dart';

Map<String, Object?> sample() => {
  'id': 1,
  'name': 'Test',
  'world': 1,
  'board': [
    '........',
    '........',
    '........',
    '........',
    '....p...',
    '........',
    '........',
    '........',
  ],
  'snake': {
    'head': 'knight',
    'squares': ['c3'],
  },
  'goal': {'type': 'eatAll'},
  'moveLimit': 3,
  'stars': [60, 100],
  'intended': ['e4'],
  'tutorial': 'tapDot',
};

void main() {
  test('parses the documented format', () {
    final l = Level.fromJsonString(jsonEncode(sample()));
    expect(l.id, 1);
    expect(l.board[sq('e4')].piece, PieceType.pawn);
    expect(l.snake.headSquare, sq('c3'));
    expect(l.goal, isA<EatAllGoal>());
    expect(l.intended, [sq('e4')]);
    expect(l.tutorial, 'tapDot');
  });

  test('JSON round-trip', () {
    final l = Level.fromJson(sample());
    expect(Level.fromJson(l.toJson()).toJson(), l.toJson());
  });

  test('play() runs the intended line', () {
    final l = Level.fromJson(sample());
    final end = l.play(l.intended);
    expect(end.status, GameStatus.won);
    expect(end.totalScore, 10 + 2 * 50);
  });

  test('ASCII shows the snake', () {
    final l = Level.fromJson(sample());
    expect(l.toAscii(), contains('3 . . S'));
    expect(l.toAscii(), contains('4 . . . . p'));
  });

  group('validation', () {
    void bad(void Function(Map<String, Object?>) edit) {
      final j = sample();
      edit(j);
      expect(() => Level.fromJson(j), throwsA(anything));
    }

    test('rejects bad fields', () {
      bad((j) => j['moveLimit'] = 0);
      bad((j) => j['stars'] = [100, 50]);
      bad((j) => j['world'] = 4);
      bad((j) => j.remove('goal'));
      bad((j) => (j['board']! as List<Object?>)[0] = '.......');
      bad(
        (j) => j['snake'] = {
          'head': 'pawn',
          'squares': ['a1'],
        },
      );
      bad(
        (j) => j['snake'] = {
          'head': 'knight',
          'squares': ['e4'],
        },
      );
      bad((j) => j['goal'] = {'type': 'reachExit'});
    });
  });
}
