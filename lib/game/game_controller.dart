import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/game_state.dart';
import '../core/level.dart';
import '../core/rules.dart';
import '../core/scoring.dart';
import '../core/square.dart';

/// Holds the current [GameState] for one level and turns taps into moves.
/// The Flame game listens to [moves]/[resets] to animate; widgets listen via
/// [ChangeNotifier] to rebuild the HUD.
class GameController extends ChangeNotifier {
  GameController(this.level) : _state = level.start();

  final Level level;
  GameState _state;
  final List<GameState> _history = [];
  final _moves = StreamController<MoveResult>.broadcast();
  final _resets = StreamController<GameState>.broadcast();

  /// True while the board is animating a move; input is ignored meanwhile.
  bool busy = false;

  /// True once the end-of-level finale has finished (result card can show).
  bool finaleDone = false;

  GameState get state => _state;
  Stream<MoveResult> get moves => _moves.stream;
  Stream<GameState> get resets => _resets.stream;
  List<Square> get legalMoves => Rules.legalMoves(_state);
  bool get canUndo => _history.isNotEmpty;

  /// Stars for the current score (0 until won).
  int get stars => Scoring.stars(
    won: _state.isWon,
    score: _state.totalScore,
    thresholds: level.stars,
  );

  /// 0..1 fill of the star bar toward the 3-star score.
  double get starProgress {
    final three = level.stars[1];
    if (three <= 0) return _state.isWon ? 1 : 0;
    return (_state.totalScore / three).clamp(0.0, 1.0);
  }

  /// Tries to move the head to [to]. Returns false if not legal or busy.
  bool tryMove(Square to) {
    if (busy || _state.isOver || !legalMoves.contains(to)) return false;
    final result = Rules.apply(_state, to);
    _history.add(_state);
    _state = result.state;
    busy = true;
    notifyListeners();
    _moves.add(result);
    return true;
  }

  /// Called by the game when the move animation is finished.
  void animationDone() {
    busy = false;
    if (_state.isOver) finaleDone = true;
    notifyListeners();
  }

  /// Steps back one move (used by the rewarded "undo" after a crash).
  void undo() {
    if (_history.isEmpty) return;
    _state = _history.removeLast();
    _resetView();
  }

  void restart() {
    _history.clear();
    _state = level.start();
    _resetView();
  }

  void _resetView() {
    busy = false;
    finaleDone = false;
    notifyListeners();
    _resets.add(_state);
  }

  @override
  void dispose() {
    unawaited(_moves.close());
    unawaited(_resets.close());
    super.dispose();
  }
}
