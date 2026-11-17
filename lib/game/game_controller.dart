import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/game_state.dart';
import '../core/level.dart';
import '../core/rules.dart';
import '../core/scoring.dart';
import '../core/square.dart';

class GameController extends ChangeNotifier {
  GameController(this.level) : _state = level.start();

  final Level level;
  GameState _state;
  final List<GameState> _history = [];
  final _moves = StreamController<MoveResult>.broadcast();
  final _resets = StreamController<GameState>.broadcast(sync: true);
  MoveResult? _pendingMove;

  bool get busy => _pendingMove != null;
  bool get finaleDone => _state.isOver && !busy;
  GameState get state => _state;
  Stream<MoveResult> get moves => _moves.stream;
  Stream<GameState> get resets => _resets.stream;
  List<Square> get legalMoves => Rules.legalMoves(_state);
  bool get canUndo => _history.isNotEmpty;

  int get stars => Scoring.stars(
    won: _state.isWon,
    score: _state.totalScore,
    thresholds: level.stars,
  );

  double get starProgress {
    final three = level.stars[1];
    if (three <= 0) return _state.isWon ? 1 : 0;
    return (_state.totalScore / three).clamp(0.0, 1.0);
  }

  bool tryMove(Square to) {
    if (busy || _state.isOver || !legalMoves.contains(to)) return false;
    final result = Rules.apply(_state, to);
    _history.add(_state);
    _state = result.state;
    _pendingMove = result;
    _moves.add(result);
    notifyListeners();
    return true;
  }

  /// A restart or undo invalidates callbacks from the previous move.
  bool isAnimating(MoveResult move) => identical(_pendingMove, move);

  void animationDone(MoveResult move) {
    if (!isAnimating(move)) return;
    _pendingMove = null;
    notifyListeners();
  }

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
    _pendingMove = null;
    _resets.add(_state);
    notifyListeners();
  }

  @override
  void dispose() {
    _pendingMove = null;
    unawaited(_moves.close());
    unawaited(_resets.close());
    super.dispose();
  }
}
