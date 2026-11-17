// Level solver CLI.
//
//   dart run tool/level_solver.dart assets/levels/level_001.json [more...]
//   dart run tool/level_solver.dart --all
//
// Prints win/no-win, best score, best line, fewest moves, the intended line's
// score and stars, and a random-bot win rate.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:knightsnake/core/level.dart';
import 'package:knightsnake/core/scoring.dart';
import 'package:knightsnake/core/solver.dart';

void main(List<String> args) {
  var paths = args.where((a) => !a.startsWith('--')).toList();
  if (args.contains('--all')) {
    paths =
        Directory('assets/levels')
            .listSync()
            .whereType<File>()
            .map((f) => f.path)
            .where((p) => p.endsWith('.json'))
            .toList()
          ..sort();
  }
  if (paths.isEmpty) {
    print('usage: dart run tool/level_solver.dart <level.json>... | --all');
    exitCode = 64;
    return;
  }
  for (final path in paths) {
    _report(path);
  }
}

void _report(String path) {
  final level = Level.fromJsonString(File(path).readAsStringSync());
  final watch = Stopwatch()..start();
  final r = solveLevel(level);
  final ms = watch.elapsedMilliseconds;
  final bot = randomBotWinRate(level);

  print('== Level ${level.id}: ${level.name} ($path)');
  print(level.toAscii());
  print('goal: ${level.goal.toJson()}  moveLimit: ${level.moveLimit}');
  print('result:       ${r.won ? 'WIN' : 'NO WIN'}');
  if (r.won) {
    print('best score:   ${r.bestScore}');
    print('best line:    ${r.bestLine.join(' ')}');
    print('fewest moves: ${r.fewestMoves}');
  }
  print(
    'search:       ${r.statesExplored} states, '
    '${r.exhaustive ? 'exhaustive' : 'beam-pruned'}, ${ms}ms',
  );
  print('random bot:   ${(bot * 100).toStringAsFixed(1)}% wins (1000 games)');

  if (level.intended.isNotEmpty) {
    try {
      final end = level.play(level.intended);
      final stars = Scoring.stars(
        won: end.isWon,
        score: end.totalScore,
        thresholds: level.stars,
      );
      print(
        'intended:     ${end.status.name}, score ${end.totalScore}, '
        '$stars★ (stars at ${level.stars[0]}/${level.stars[1]})',
      );
    } on Object catch (e) {
      print('intended:     INVALID ($e)');
    }
  }
  final three = (r.bestScore ~/ 10) * 10;
  final two = ((three * 0.7) ~/ 10) * 10;
  print('suggested stars: [$two, $three]');
  print('');
}
