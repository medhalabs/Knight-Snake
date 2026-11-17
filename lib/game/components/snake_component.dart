import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/piece.dart';
import '../../core/rng.dart';
import '../../core/snake.dart';
import '../palette.dart';
import 'board_component.dart';
import 'token_painter.dart';

/// Draws the snake (glossy body + head character) and animates moves:
/// knights arc through the air, sliders glide with easing, the body follows.
class SnakeComponent extends Component {
  SnakeComponent({
    required this.layout,
    required Snake snake,
    required this.reducedMotion,
  }) : _head = snake.head {
    _pos = [for (final s in snake.squares) layout.center(s)];
  }

  final BoardLayout layout;
  final bool reducedMotion;
  final _rng = XorShift32(7);

  PieceType _head;
  late List<Vector2> _pos;
  List<Vector2> _from = const [];
  List<Vector2> _to = const [];
  double _t = 1;
  double _duration = 0.2;
  bool _arc = false;
  Completer<void>? _done;

  double _pop = 1; // 0..1 head-change pop progress
  double _shudder = 1; // 0..1 loss shudder progress
  double _blinkIn = 2;
  double _blink = 0;
  Offset _look = const Offset(0, 1);

  /// Head center in board pixels (for effects).
  Vector2 get headPosition => _pos.first;

  /// Jumps straight to [snake] without animation (restart/undo).
  void snapTo(Snake snake) {
    _head = snake.head;
    _pos = [for (final s in snake.squares) layout.center(s)];
    _t = 1;
    _done?.complete();
    _done = null;
  }

  /// Animates from the current snake to [next]. Completes when the head lands.
  Future<void> animateTo(Snake next, {required PieceType mover}) {
    final old = _pos;
    _from = [
      for (var i = 0; i < next.length; i++) i < old.length ? old[i] : old.last,
    ];
    _to = [for (final s in next.squares) layout.center(s)];
    final dist = (_to.first - _from.first).length / layout.cell;
    _arc = mover == PieceType.knight && !reducedMotion;
    _duration = reducedMotion
        ? 0.12
        : switch (mover) {
            PieceType.knight => 0.34,
            PieceType.king => 0.18,
            _ => math.min(0.42, 0.14 + dist * 0.04),
          };
    final d = _to.first - _from.first;
    if (d.length > 0) _look = Offset(d.x, d.y) / d.length;
    _pos = [for (final p in _from) p.clone()];
    _t = 0;
    _done = Completer<void>();
    return _done!.future;
  }

  /// Called after the head lands on a piece that changes its type.
  void changeHead(PieceType type) {
    _head = type;
    _pop = 0;
  }

  void shudder() => _shudder = 0;

  @override
  void update(double dt) {
    if (_t < 1) {
      _t = math.min(1, _t + dt / _duration);
      final e = _easeInOut(_t);
      for (var i = 0; i < _pos.length; i++) {
        _pos[i] = _from[i] + (_to[i] - _from[i]) * e;
      }
      if (_t >= 1) {
        _done?.complete();
        _done = null;
      }
    }
    _pop = math.min(1, _pop + dt * 3);
    _shudder = math.min(1, _shudder + dt * 2);
    _blinkIn -= dt;
    if (_blinkIn <= 0) {
      _blink = 0.0001;
      _blinkIn = 2.5 + _rng.nextInt(2500) / 1000;
    }
    if (_blink > 0) {
      _blink += dt;
      if (_blink > 0.16) _blink = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    final c = layout.cell;
    final color = Palette.head(_head);
    final n = _pos.length;
    final lift = _arc && _t < 1 ? math.sin(math.pi * _t) * c * 0.9 : 0.0;

    // Body: links then segments, tail first so the head draws on top.
    for (var i = n - 1; i >= 1; i--) {
      final k = i / math.max(1, n - 1);
      final segColor = Palette.tint(color, 0.15 + 0.45 * k);
      final a = _pos[i].toOffset();
      final b = i == 1
          ? _pos[0].toOffset().translate(0, -lift)
          : _pos[i - 1].toOffset();
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = segColor
          ..strokeWidth = c * (0.42 - 0.12 * k)
          ..strokeCap = StrokeCap.round,
      );
    }
    for (var i = n - 1; i >= 1; i--) {
      final k = i / math.max(1, n - 1);
      _segment(
        canvas,
        _pos[i].toOffset(),
        c * (0.36 - 0.08 * k),
        Palette.tint(color, 0.15 + 0.45 * k),
      );
    }

    // Head.
    var head = _pos[0].toOffset().translate(0, -lift);
    if (_shudder < 1) {
      head = head.translate(
        math.sin(_shudder * 40) * c * 0.08 * (1 - _shudder),
        0,
      );
    }
    final popScale = 1 + math.sin(math.pi * _pop) * 0.3;
    if (lift > 0) {
      canvas.drawOval(
        Rect.fromCenter(
          center: _pos[0].toOffset().translate(0, c * 0.3),
          width: c * 0.6,
          height: c * 0.16,
        ),
        Paint()..color = const Color(0x22000000),
      );
    }
    final blink = _blink > 0 ? math.sin(math.pi * _blink / 0.16) : 0.0;
    TokenPainter.head(
      canvas,
      head,
      c * 0.43 * popScale,
      _head,
      blink: blink,
      look: _look,
    );
  }

  void _segment(Canvas canvas, Offset o, double r, Color color) {
    canvas
      ..drawCircle(
        o.translate(0, r * 0.12),
        r,
        Paint()..color = Palette.shade(color, 0.2),
      )
      ..drawCircle(
        o,
        r,
        Paint()
          ..shader = Gradient.radial(
            o.translate(-r * 0.3, -r * 0.35),
            r * 1.5,
            [Palette.tint(color, 0.4), color],
          ),
      )
      ..drawCircle(
        o.translate(-r * 0.3, -r * 0.35),
        r * 0.22,
        Paint()..color = const Color(0x77FFFFFF),
      );
  }
}

double _easeInOut(double t) =>
    t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;
