import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/piece.dart';
import 'token_painter.dart';

/// An enemy piece waiting to be eaten. Wobbles gently; pops when eaten.
class FoodComponent extends PositionComponent {
  FoodComponent({
    required this.piece,
    required Vector2 center,
    required this.cell,
    required this.phase,
    required this.reducedMotion,
  }) : super(position: center, anchor: Anchor.center);

  final PieceType piece;
  final double cell;
  final double phase;
  final bool reducedMotion;

  double _t = 0;
  double _eaten = -1; // <0 alive, else seconds since eaten
  double _appear = 0;

  void eat() => _eaten = 0;

  @override
  void update(double dt) {
    _t += dt;
    _appear = math.min(1, _appear + dt * 4);
    if (_eaten >= 0) {
      _eaten += dt;
      if (_eaten > 0.25) removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    var scale = _easeOutBack(_appear);
    var alpha = 1.0;
    if (_eaten >= 0) {
      final k = (_eaten / 0.25).clamp(0.0, 1.0);
      scale = 1 + k * 0.5;
      alpha = 1 - k;
    }
    final wobble = reducedMotion ? 0.0 : math.sin(_t * 2.4 + phase) * 0.07;
    canvas
      ..saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, alpha))
      ..rotate(wobble)
      ..scale(scale);
    TokenPainter.food(canvas, Offset.zero, cell * 0.36, piece);
    canvas.restore();
  }
}

double _easeOutBack(double t) {
  const c1 = 1.70158;
  const c3 = c1 + 1;
  return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2);
}
