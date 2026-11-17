import 'game_state.dart';
import 'piece.dart';

/// A level goal (see GAME_PLAN §2 "Goals").
sealed class Goal {
  const Goal();

  factory Goal.fromJson(Map<String, Object?> json) {
    final type = json['type'];
    return switch (type) {
      'eatAll' => const EatAllGoal(),
      'reachExit' => const ReachExitGoal(),
      'eatCount' => EatCountGoal(_int(json, 'count')),
      'length' => LengthGoal(_int(json, 'length')),
      'eatPieces' => EatPiecesGoal(_pieces(json['pieces'])),
      _ => throw FormatException('Unknown goal type', '$type'),
    };
  }

  Map<String, Object?> toJson();

  /// Progress as (done, target), used by the HUD and the solver heuristic.
  (int, int) progress(GameState state);

  bool isComplete(GameState state) {
    final (done, target) = progress(state);
    return done >= target;
  }

  static int _int(Map<String, Object?> json, String key) {
    final v = json[key];
    if (v is! int || v < 1) throw FormatException('Goal "$key" must be ≥ 1');
    return v;
  }

  static Map<PieceType, int> _pieces(Object? raw) {
    if (raw is! Map<String, Object?> || raw.isEmpty) {
      throw const FormatException('eatPieces needs a "pieces" map');
    }
    return {
      for (final e in raw.entries)
        PieceType.fromName(e.key): e.value is int && (e.value! as int) > 0
            ? e.value! as int
            : throw FormatException('Bad count for ${e.key}'),
    };
  }
}

class EatAllGoal extends Goal {
  const EatAllGoal();
  @override
  Map<String, Object?> toJson() => {'type': 'eatAll'};
  @override
  (int, int) progress(GameState s) =>
      (s.eatenTotal, s.eatenTotal + s.board.foodCount);
}

class EatCountGoal extends Goal {
  const EatCountGoal(this.count);
  final int count;
  @override
  Map<String, Object?> toJson() => {'type': 'eatCount', 'count': count};
  @override
  (int, int) progress(GameState s) => (s.eatenTotal, count);
}

class LengthGoal extends Goal {
  const LengthGoal(this.length);
  final int length;
  @override
  Map<String, Object?> toJson() => {'type': 'length', 'length': length};
  @override
  (int, int) progress(GameState s) => (s.snake.length, length);
}

class EatPiecesGoal extends Goal {
  const EatPiecesGoal(this.pieces);
  final Map<PieceType, int> pieces;
  @override
  Map<String, Object?> toJson() => {
    'type': 'eatPieces',
    'pieces': {for (final e in pieces.entries) e.key.name: e.value},
  };
  @override
  (int, int) progress(GameState s) {
    var done = 0;
    var target = 0;
    for (final e in pieces.entries) {
      final eaten = s.eaten[e.key] ?? 0;
      done += eaten < e.value ? eaten : e.value;
      target += e.value;
    }
    return (done, target);
  }
}

class ReachExitGoal extends Goal {
  const ReachExitGoal();
  @override
  Map<String, Object?> toJson() => {'type': 'reachExit'};
  @override
  (int, int) progress(GameState s) =>
      (s.board[s.snake.headSquare].isExit ? 1 : 0, 1);
}
