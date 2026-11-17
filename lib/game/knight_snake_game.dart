import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

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

class KnightSnakeGame extends FlameGame {
  KnightSnakeGame({required this.controller, required this.services});

  final GameController controller;
  final Services services;

  late BoardLayout _layout;
  BoardComponent? _board;
  SnakeComponent? _snake;
  MoveDots? _dots;
  Component? _layers;
  Component? _effects;
  final Map<int, FoodComponent> _food = {};
  final List<StreamSubscription<Object>> _subs = [];
  double _side = 0;
  double _time = 0;
  double _shake = 0;
  double _shakePower = 0;
  int _seed = 1;
  MoveResult? _finale;
  double _finaleLeft = 0;

  bool _reducedMotion = false;
  set reducedMotion(bool value) {
    if (_reducedMotion == value) return;
    _reducedMotion = value;
    if (value) _shake = 0;
    if (_side > 0) _rebuild(_side);
  }

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    _subs
      ..add(controller.moves.listen(_onMove))
      ..add(
        controller.resets.listen((_) {
          _finale = null;
          _shake = 0;
          if (_side > 0) _rebuild(_side);
        }),
      );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final side = math.min(size.x, size.y);
    if (side > 0 && side != _side) _rebuild(side);
  }

  void _rebuild(double side) {
    _side = side;
    _board?.clearDrag();
    _snake?.finishAnimation();
    _layers?.removeFromParent();
    _food.clear();
    final st = controller.state;
    _layout = BoardLayout(side);
    final board = _board = BoardComponent(
      layout: _layout,
      board: st.board,
      onSquare: _onSquare,
      canStartDrag: (s) =>
          !controller.busy &&
          !controller.state.isOver &&
          s == controller.state.snake.headSquare,
      time: () => _reducedMotion ? 0 : _time,
    );
    final dots = _dots = MoveDots(
      layout: _layout,
      reducedMotion: _reducedMotion,
    );
    final snake = _snake = SnakeComponent(
      layout: _layout,
      snake: st.snake,
      reducedMotion: _reducedMotion,
    )..priority = 30;
    final effects = _effects = Component(priority: 50);
    final food = Component(priority: 20);
    for (final s in st.board.foodSquares) {
      final f = FoodComponent(
        piece: st.board[s].piece!,
        center: _layout.center(s),
        cell: _layout.cell,
        phase: s.index * 0.7,
        reducedMotion: _reducedMotion,
      );
      _food[s.index] = f;
      food.add(f);
    }
    dots.priority = 10;
    final layers = _layers = Component(
      children: [board, dots, food, snake, effects],
    );
    add(layers);
    _showDots();
  }

  void _showDots() {
    final st = controller.state;
    if (st.isOver || controller.busy) {
      _dots?.hide();
    } else {
      _dots?.show(controller.legalMoves, st.board, Palette.head(st.snake.head));
    }
  }

  void _onSquare(Square s, {required bool dragged}) {
    if (controller.busy ||
        controller.state.isOver ||
        s == controller.state.snake.headSquare) {
      return;
    }
    if (controller.tryMove(s)) {
      _board?.clearDrag();
    } else if (!dragged) {
      _dots?.reject(s);
      services.haptics.play(Haptic.light);
    }
  }

  Future<void> _onMove(MoveResult move) async {
    if (!controller.isAnimating(move)) return;
    final snake = _snake;
    if (snake == null) {
      controller.animationDone(move);
      return;
    }
    _dots?.hide();
    final moved = move.events.whereType<MovedEvent>().first;
    services.haptics.play(Haptic.light);
    services.audio.play(Sfx.move);
    await snake.animateTo(move.state.snake, mover: moved.head);
    if (!controller.isAnimating(move)) return;

    final at = _layout.center(moved.to);
    for (final event in move.events) {
      switch (event) {
        case AteEvent():
          _capture(event, at);
        case HeadChangedEvent():
          _snake?.changeHead(event.to);
          _impact(at, Palette.head(event.to), 1.26);
        case WonEvent():
          _celebrate();
        case LostEvent():
          _snake?.shudder();
          services.haptics.play(Haptic.error);
          services.audio.play(Sfx.lose);
        case MovedEvent():
          _impact(at, Palette.head(moved.head), 0.33);
      }
    }

    if (move.state.isOver && !_reducedMotion) {
      _finale = move;
      _finaleLeft = move.state.isWon ? 0.96 : 0.40;
    } else {
      _finish(move);
    }
  }

  void _finish(MoveResult move) {
    controller.animationDone(move);
    _showDots();
  }

  void _capture(AteEvent event, Vector2 at) {
    _food.remove(event.square.index)?.eat();
    final c = _layout.cell;
    final color = Palette.head(event.piece);
    final combo = event.multiplier;
    _impact(at, color, 0.8 + combo * 0.13);
    if (!_reducedMotion) {
      _spawn(
        Burst(
          at: at,
          colors: [color, Palette.star, Palette.white],
          cell: c,
          count: 12 + combo * 5,
          seed: _seed++,
        ),
      );
    }
    _spawn(
      FloatingText(
        '+${event.points}',
        reason: combo > 1 ? '×$combo COMBO' : null,
        at: Vector2(
          at.x.clamp(c, _layout.size - c),
          (at.y - c * 0.50).clamp(c * 0.75, _layout.size - c * 0.5),
        ),
        cell: c,
        color: color,
        reducedMotion: _reducedMotion,
      ),
    );
    services.haptics.play(Haptic.medium);
    services.audio.play(combo > 1 ? Sfx.combo : Sfx.eat);
    if (combo >= 3) _shakeIt(0.13 + combo * 0.018);
  }

  void _celebrate() {
    services.haptics.play(Haptic.heavy);
    services.audio.play(Sfx.win);
    if (_reducedMotion) return;
    final c = _layout.cell;
    final d = _layout.size;
    _shakeIt(0.23);
    for (final x in [0.26, 0.74]) {
      _spawn(
        Burst(
          at: Vector2(d * x, d * 0.57),
          colors: const [
            Palette.violet,
            Palette.mint,
            Palette.star,
            Palette.white,
            Palette.danger,
          ],
          cell: c,
          count: 34,
          confetti: true,
          seed: _seed++,
        ),
      );
    }
    _spawn(
      FloatingText(
        'CHECKMATE!',
        at: Vector2(d / 2, d * 0.18),
        cell: c,
        color: Palette.star,
        reducedMotion: false,
        victory: true,
      ),
    );
  }

  void _impact(Vector2 at, Color color, double strength) {
    if (_reducedMotion) return;
    _spawn(
      ImpactRing(at: at, cell: _layout.cell, color: color, strength: strength),
    );
  }

  void _spawn(Component c) => _effects?.add(c);

  void _shakeIt(double power) {
    if (_reducedMotion) return;
    _shake = 0.24;
    _shakePower = power;
  }

  @override
  void update(double dt) {
    _time += dt;
    _shake = math.max(0, _shake - dt);
    super.update(dt);
    if (_finale case final finale?) {
      _finaleLeft -= dt;
      if (_finaleLeft <= 0 || _reducedMotion) {
        _finale = null;
        _finish(finale);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (_shake == 0) {
      super.render(canvas);
      return;
    }
    final m = _layout.cell * _shakePower * (_shake / 0.24);
    canvas
      ..save()
      ..translate(math.sin(_time * 90) * m, math.cos(_time * 70) * m);
    super.render(canvas);
    canvas.restore();
  }

  @override
  void onRemove() {
    _snake?.finishAnimation();
    for (final sub in _subs) {
      unawaited(sub.cancel());
    }
    _subs.clear();
    super.onRemove();
  }
}
