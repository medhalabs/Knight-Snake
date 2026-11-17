import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../core/piece.dart';
import '../core/rules.dart';
import '../core/square.dart';
import '../services/services.dart';
import 'components/board_component.dart';
import 'components/effects.dart';
import 'components/food_component.dart';
import 'components/move_dots.dart';
import 'components/snake_component.dart';
import 'game_controller.dart';
import 'palette.dart';

/// Renders the board for one [GameController] and plays its moves.
/// Holds no game rules: it only draws state and forwards taps.
class KnightSnakeGame extends FlameGame {
  KnightSnakeGame({
    required this.controller,
    required this.services,
    required this.reducedMotion,
  });

  final GameController controller;
  final Services services;
  final bool reducedMotion;

  late BoardLayout _layout;
  BoardComponent? _board;
  SnakeComponent? _snake;
  MoveDots? _dots;
  final Map<int, FoodComponent> _food = {};
  final List<StreamSubscription<Object>> _subs = [];
  final List<Component> _mine = [];
  double _side = 0;
  double _time = 0;
  double _shake = 0;
  double _shakePower = 0;
  int _seed = 1;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    _subs
      ..add(controller.moves.listen(_onMove))
      ..add(controller.resets.listen((_) => _rebuild()));
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final side = math.min(size.x, size.y);
    if (side > 0 && side != _side) _rebuild();
  }

  /// Recreates all board components from the controller state (first
  /// layout, size change, restart or undo). A pending move animation is
  /// finished first so its awaiting code never hangs.
  void _rebuild() {
    final side = math.min(size.x, size.y);
    if (side <= 0) return;
    _side = side;
    _snake?.snapTo(controller.state.snake);
    for (final c in _mine) {
      c.removeFromParent();
    }
    _mine.clear();
    _food.clear();
    _layout = BoardLayout(side);
    final st = controller.state;
    _board = BoardComponent(
      layout: _layout,
      board: st.board,
      onSquare: _onSquare,
      time: () => _time,
    );
    _dots = MoveDots(layout: _layout, reducedMotion: reducedMotion);
    _snake = SnakeComponent(
      layout: _layout,
      snake: st.snake,
      reducedMotion: reducedMotion,
    );
    _own(_board!);
    for (final s in st.board.foodSquares) {
      _addFood(s, st.board[s].piece!);
    }
    _own(_dots!);
    _own(_snake!);
    _showDots();
  }

  void _addFood(Square s, PieceType p) {
    final f = FoodComponent(
      piece: p,
      center: _layout.center(s),
      cell: _layout.cell,
      phase: s.index * 0.7,
      reducedMotion: reducedMotion,
    );
    _food[s.index] = f;
    _own(f);
  }

  void _showDots() {
    final st = controller.state;
    if (st.isOver) {
      _dots?.hide();
    } else {
      _dots?.show(controller.legalMoves, st.board, Palette.head(st.snake.head));
    }
  }

  void _onSquare(Square s, {required bool dragged}) {
    if (controller.busy) return;
    if (dragged && s == controller.state.snake.headSquare) return;
    if (!controller.tryMove(s)) {
      if (!dragged && s != controller.state.snake.headSquare) {
        services.haptics.play(Haptic.light);
      }
    }
  }

  Future<void> _onMove(MoveResult r) async {
    final snake = _snake;
    if (snake == null) return;
    _dots?.hide();
    final moved = r.events.whereType<MovedEvent>().first;
    services.haptics.play(Haptic.light);
    services.audio.play(Sfx.move);
    await snake.animateTo(r.state.snake, mover: moved.head);

    final c = _layout.cell;
    for (final e in r.events) {
      switch (e) {
        case AteEvent():
          _food.remove(e.square.index)?.eat();
          final at = _layout.center(e.square);
          _spawn(
            Burst(
              at: at,
              colors: [Palette.head(e.piece), Palette.star, Palette.white],
              cell: c,
              count: reducedMotion ? 6 : 18,
              seed: _seed++,
            ),
          );
          _spawn(
            FloatingText(
              '+${e.points}',
              e.multiplier > 1 ? 'COMBO ×${e.multiplier}' : null,
              at: at - Vector2(0, c * 0.3),
              cell: c,
            ),
          );
          services.haptics.play(Haptic.medium);
          services.audio.play(e.multiplier > 1 ? Sfx.combo : Sfx.eat);
          if (!r.state.isWon) {
            if (e.multiplier >= 3) {
              _praise('GREAT!');
              _shakeIt(0.25);
            } else if (e.multiplier == 2) {
              _praise('NICE!');
            } else if (e.piece == PieceType.queen) {
              _shakeIt(0.2);
            }
          }
        case HeadChangedEvent():
          snake.changeHead(e.to);
        case WonEvent():
          _praise('CHECKMATE!', big: true);
          _shakeIt(0.35);
          services.haptics.play(Haptic.heavy);
          services.audio.play(Sfx.win);
          _spawn(
            Burst(
              at: Vector2(size.x / 2, size.y * 0.55),
              colors: const [
                Color(0xFF8E5CF7),
                Color(0xFF14B8A6),
                Color(0xFFFB8C2A),
                Color(0xFFF0509A),
                Color(0xFFF5B800),
              ],
              cell: c,
              count: reducedMotion ? 20 : 80,
              confetti: true,
              seed: _seed++,
            ),
          );
        case LostEvent():
          snake.shudder();
          services.haptics.play(Haptic.error);
          services.audio.play(Sfx.lose);
        case MovedEvent():
          break;
      }
    }
    if (r.state.isOver) {
      await Future<void>.delayed(
        Duration(milliseconds: r.state.isWon ? 1300 : 800),
      );
    }
    _showDots();
    controller.animationDone();
  }

  void _own(Component c) {
    _mine.add(c);
    add(c);
  }

  /// Adds a short-lived effect component without awaiting its load.
  void _spawn(Component c) => unawaited(Future<void>.value(add(c)));

  void _praise(String word, {bool big = false}) {
    add(
      PraiseText(
        word,
        at: Vector2(_layout.size / 2, _layout.size * 0.16),
        fontSize: _layout.cell * (big ? 0.85 : 0.6),
        color: big ? Palette.star : Palette.white,
      ),
    );
  }

  void _shakeIt(double power) {
    if (reducedMotion) return;
    _shake = 0.3;
    _shakePower = power;
  }

  @override
  void update(double dt) {
    _time += dt;
    if (_shake > 0) _shake = math.max(0, _shake - dt);
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    if (_shake > 0) {
      final m = _layout.cell * _shakePower * (_shake / 0.3);
      canvas
        ..save()
        ..translate(math.sin(_time * 90) * m, math.cos(_time * 70) * m);
      super.render(canvas);
      canvas.restore();
    } else {
      super.render(canvas);
    }
  }

  @override
  void onRemove() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    super.onRemove();
  }
}
