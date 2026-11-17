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
  double _duration = 0.22;
  bool _arc = false;
  Completer<void>? _done;

  double _pop = 1;
  double _shudder = 1;
  double _blinkIn = 2;
  double _blink = 0;
  Offset _look = const Offset(0, 1);

  void finishAnimation() {
    _t = 1;
    _done?.complete();
    _done = null;
  }

  Future<void> animateTo(Snake next, {required PieceType mover}) {
    if (reducedMotion) {
      _pos = [for (final s in next.squares) layout.center(s)];
      return Future<void>.value();
    }
    final old = _pos;
    _from = [
      for (var i = 0; i < next.length; i++) i < old.length ? old[i] : old.last,
    ];
    _to = [for (final s in next.squares) layout.center(s)];
    final d = _to.first - _from.first;
    if (d.length > 0) _look = Offset(d.x, d.y) / d.length;
    _arc = mover == PieceType.knight;
    _duration = switch (mover) {
      PieceType.knight => 0.25,
      PieceType.king => 0.15,
      _ => math.min(0.30, 0.13 + d.length / layout.cell * 0.024),
    };
    _pos = [for (final p in _from) p.clone()];
    _t = 0;
    _done = Completer<void>();
    return _done!.future;
  }

  void changeHead(PieceType type) {
    _head = type;
    if (!reducedMotion) _pop = 0;
  }

  void shudder() {
    if (!reducedMotion) _shudder = 0;
  }

  @override
  void update(double dt) {
    if (reducedMotion) return;
    if (_t < 1) {
      _t = math.min(1, _t + dt / _duration);
      final e = _easeInOut(_t);
      for (var i = 0; i < _pos.length; i++) {
        _pos[i] = _from[i] + (_to[i] - _from[i]) * e;
      }
      if (_t >= 1) finishAnimation();
    }
    _pop = math.min(1, _pop + dt * 4.2);
    _shudder = math.min(1, _shudder + dt * 3);
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
    final lift = _lift(_t);
    final ground = _pos.first.toOffset();

    if (_t < 1) _drawTrail(canvas, color);
    for (var i = n - 1; i >= 1; i--) {
      final k = i / (n - 1);
      final a = _pos[i].toOffset();
      final b = i == 1 ? ground.translate(0, -lift) : _pos[i - 1].toOffset();
      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = c * (0.36 - 0.12 * k);
      canvas
        ..drawLine(
          a.translate(0, c * 0.05),
          b.translate(0, c * 0.05),
          paint..color = Palette.ink,
        )
        ..drawLine(a, b, paint..color = Palette.shade(color, 0.44))
        ..drawLine(
          a.translate(0, -c * 0.035),
          b.translate(0, -c * 0.035),
          paint
            ..strokeWidth = c * 0.028
            ..color = color.withValues(alpha: 0.62),
        );
    }
    for (var i = n - 1; i >= 1; i--) {
      final k = i / (n - 1);
      _segment(canvas, _pos[i].toOffset(), c * (0.28 - 0.075 * k), color);
    }

    var head = ground.translate(0, -lift);
    if (_shudder < 1) {
      head = head.translate(
        math.sin(_shudder * 40) * c * 0.08 * (1 - _shudder),
        0,
      );
    }
    final shadow = Rect.fromCenter(
      center: ground.translate(0, c * 0.11),
      width: c * 0.77,
      height: c * 0.42,
    );
    final paint = Paint();
    canvas
      ..drawOval(shadow, paint..color = const Color(0x80100A1D))
      ..drawCircle(
        ground,
        c * 0.46,
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = c * 0.024
          ..color = color.withValues(alpha: lift == 0 ? 0.48 : 0.27),
      );
    final popScale = 1 + math.sin(math.pi * _pop) * 0.26;
    final blink = _blink > 0 ? math.sin(math.pi * _blink / 0.16) : 0.0;
    TokenPainter.head(
      canvas,
      head,
      c * 0.405 * popScale,
      _head,
      blink: blink,
      look: _look,
    );
  }

  double _lift(double t) =>
      _arc && t < 1 ? math.sin(math.pi * t) * layout.cell * 0.78 : 0;

  void _drawTrail(Canvas canvas, Color color) {
    final c = layout.cell;
    final paint = Paint();
    for (var i = 5; i >= 1; i--) {
      final t = _t - i * 0.045;
      if (t <= 0) continue;
      final p = _from.first + (_to.first - _from.first) * _easeInOut(t);
      final center = p.toOffset().translate(0, -_lift(t));
      canvas.drawCircle(
        center,
        c * (0.25 - i * 0.032),
        paint..color = color.withValues(alpha: 0.24 - i * 0.034),
      );
    }
  }

  void _segment(Canvas canvas, Offset o, double r, Color color) {
    final bounds = Rect.fromCircle(center: o, radius: r);
    final paint = Paint();
    canvas
      ..drawCircle(o.translate(0, r * 0.20), r, paint..color = Palette.ink)
      ..drawCircle(
        o,
        r,
        paint
          ..shader = Gradient.linear(
            bounds.topLeft,
            bounds.bottomRight,
            [Palette.tint(color, 0.55), color, Palette.shade(color, 0.75)],
            const [0, 0.35, 1],
          ),
      )
      ..drawCircle(
        o,
        r * 0.72,
        paint
          ..shader = Gradient.radial(
            o.translate(-r * 0.35, -r * 0.4),
            r * 1.45,
            [color, Palette.shade(color, 0.73)],
          ),
      );
    final rhombus = Path()
      ..addPolygon([
        o.translate(0, -r * 0.46),
        o.translate(r * 0.38, 0),
        o.translate(0, r * 0.39),
        o.translate(-r * 0.38, 0),
      ], true);
    canvas.drawPath(
      rhombus,
      paint
        ..shader = null
        ..color = color.withValues(alpha: 0.57),
    );
  }
}

double _easeInOut(double t) => t * t * (3 - 2 * t);
