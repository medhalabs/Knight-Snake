import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:knightsnake/core/level.dart';
import 'package:knightsnake/core/scoring.dart';
import 'package:knightsnake/core/solver.dart';

/// Minimum stars the documented intended solution must earn, per level.
/// Teaching levels must be 3★ (docs/levels/README.md).
const intendedStars = {1: 3, 2: 3, 3: 3, 4: 3, 5: 3};

void main() {
  final files =
      Directory('assets/levels')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('level files exist and are numbered 1..N without gaps', () {
    expect(files, isNotEmpty);
    for (var i = 0; i < files.length; i++) {
      final expected = 'level_${(i + 1).toString().padLeft(3, '0')}.json';
      expect(files[i].uri.pathSegments.last, expected);
    }
  });

  for (final file in files) {
    final name = file.uri.pathSegments.last;
    group(name, () {
      late Level level;

      setUpAll(() => level = Level.fromJsonString(file.readAsStringSync()));

      test('is valid and id matches the file name', () {
        expect(name, 'level_${level.id.toString().padLeft(3, '0')}.json');
        expect(level.start().isOver, isFalse);
        final doc = File(
          'docs/levels/level-${level.id.toString().padLeft(3, '0')}.md',
        );
        expect(doc.existsSync(), isTrue, reason: 'missing ${doc.path}');
      });

      test('solver wins within the move limit and reaches 3★', () {
        final r = solveLevel(level);
        expect(r.won, isTrue);
        expect(r.fewestMoves, lessThanOrEqualTo(level.moveLimit));
        expect(r.bestScore, greaterThanOrEqualTo(level.stars[1]));
        expect(level.play(r.bestLine).totalScore, r.bestScore);
      });

      test('intended solution wins with the documented stars', () {
        expect(level.intended, isNotEmpty);
        final end = level.play(level.intended);
        expect(end.isWon, isTrue);
        final stars = Scoring.stars(
          won: true,
          score: end.totalScore,
          thresholds: level.stars,
        );
        expect(stars, greaterThanOrEqualTo(intendedStars[level.id] ?? 1));
      });
    });
  }
}
