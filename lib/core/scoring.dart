import 'piece.dart';

/// Scoring rules (GAME_PLAN §3). All functions are pure.
abstract final class Scoring {
  /// Highest combo multiplier.
  static const maxCombo = 5;

  /// Bonus per unused move on a win.
  static const perUnusedMove = 50;

  /// Combo multiplier for the [streak]-th eat in a row (1-based).
  static int multiplier(int streak) => streak < 1
      ? 1
      : streak > maxCombo
      ? maxCombo
      : streak;

  /// Points for eating [piece] as the [streak]-th eat in a row.
  static int eatPoints(PieceType piece, int streak) =>
      piece.points * multiplier(streak);

  /// End-of-level bonus for [unusedMoves].
  static int movesBonus(int unusedMoves) =>
      unusedMoves < 0 ? 0 : unusedMoves * perUnusedMove;

  /// Stars earned: 0 if not won, else 1–3 using `[twoStar, threeStar]`.
  static int stars({
    required bool won,
    required int score,
    required List<int> thresholds,
  }) {
    if (!won) return 0;
    if (score >= thresholds[1]) return 3;
    if (score >= thresholds[0]) return 2;
    return 1;
  }
}
