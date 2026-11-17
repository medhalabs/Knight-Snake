import 'game_state.dart';
import 'level.dart';
import 'rng.dart';
import 'rules.dart';
import 'square.dart';

/// Result of searching a level.
class SolveResult {
  const SolveResult({
    required this.won,
    required this.bestScore,
    required this.bestLine,
    required this.fewestMoves,
    required this.statesExplored,
    required this.exhaustive,
  });

  /// Whether any winning line was found within the move limit.
  final bool won;

  /// Best total score (eating + moves bonus) among winning lines, or 0.
  final int bestScore;
  final List<Square> bestLine;

  /// Shortest winning line length, or null if no win.
  final int? fewestMoves;
  final int statesExplored;

  /// True when no states were pruned (results are exact).
  final bool exhaustive;
}

class _Node {
  _Node(this.state, this.parent, this.move);
  final GameState state;
  final _Node? parent;
  final Square? move;

  List<Square> line() {
    final out = <Square>[];
    _Node? n = this;
    while (n != null && n.move != null) {
      out.add(n.move!);
      n = n.parent;
    }
    return out.reversed.toList();
  }
}

/// Breadth-first search with a beam cap, one layer per move.
///
/// States with the same key in a layer are merged, keeping the higher score
/// (score only ever grows, so this keeps best-score search exact). When a
/// layer exceeds [beamWidth], only the most promising states are kept.
SolveResult solve(GameState start, {int beamWidth = 20000, int? maxDepth}) {
  final limit = maxDepth ?? start.moveLimit ?? 30;
  var layer = <_Node>[_Node(start, null, null)];
  var explored = 0;
  var exhaustive = true;
  _Node? best;
  int? fewest;

  if (start.isWon) {
    return SolveResult(
      won: true,
      bestScore: start.totalScore,
      bestLine: const [],
      fewestMoves: 0,
      statesExplored: 1,
      exhaustive: true,
    );
  }

  for (var depth = 0; depth < limit && layer.isNotEmpty; depth++) {
    final next = <String, _Node>{};
    for (final node in layer) {
      for (final move in Rules.legalMoves(node.state)) {
        final child = Rules.apply(node.state, move).state;
        explored++;
        final n = _Node(child, node, move);
        if (child.isWon) {
          fewest ??= depth + 1;
          if (best == null || child.totalScore > best.state.totalScore) {
            best = n;
          }
          continue;
        }
        if (child.isOver) continue;
        final key = child.key;
        final prev = next[key];
        if (prev == null || child.score > prev.state.score) next[key] = n;
      }
    }
    var nodes = next.values.toList();
    if (nodes.length > beamWidth) {
      exhaustive = false;
      nodes.sort((a, b) => _promise(b.state).compareTo(_promise(a.state)));
      nodes = nodes.sublist(0, beamWidth);
    }
    layer = nodes;
  }

  return SolveResult(
    won: best != null,
    bestScore: best?.state.totalScore ?? 0,
    bestLine: best?.line() ?? const [],
    fewestMoves: fewest,
    statesExplored: explored,
    exhaustive: exhaustive,
  );
}

/// Heuristic for pruning: goal progress first, then score, then mobility.
int _promise(GameState s) {
  final (done, target) = s.goal.progress(s);
  final ratio = target == 0 ? 1000 : (done * 1000) ~/ target;
  return ratio * 100000 + s.score * 10 + Rules.legalMoves(s).length;
}

/// Convenience: solve a level from its start.
SolveResult solveLevel(Level level, {int beamWidth = 20000}) =>
    solve(level.start(), beamWidth: beamWidth);

/// Plays [games] games choosing uniformly random legal moves.
/// Returns the fraction won (0–1). Deterministic for a given [seed].
double randomBotWinRate(Level level, {int games = 1000, int seed = 1}) {
  final rng = XorShift32(seed);
  var wins = 0;
  for (var g = 0; g < games; g++) {
    var s = level.start();
    while (!s.isOver) {
      s = Rules.apply(s, rng.pick(Rules.legalMoves(s))).state;
    }
    if (s.isWon) wins++;
  }
  return wins / games;
}
