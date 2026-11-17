import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/piece.dart';
import 'token_painter.dart';

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
  double _eaten = -1;

  void eat() {
    if (reducedMotion) {
      removeFromParent();
    } else {
      _eaten = 0;
    }
  }

  @override
  void update(double dt) {
    _t += dt;
    if (_eaten >= 0) {
      _eaten += dt;
      if (_eaten > 0.16) removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (_eaten > 0.16) return;
    if (_eaten >= 0) {
      final fade = _eaten / 0.16;
      canvas
        ..saveLayer(
          Rect.fromCircle(center: Offset.zero, radius: cell * 0.8),
          Paint()..color = Color.fromRGBO(0, 0, 0, 1 - fade),
        )
        ..scale(1 + fade * 0.55);
    } else {
      final hover = reducedMotion ? 0.0 : math.sin(_t * 2.4 + phase);
      canvas
        ..save()
        ..translate(0, hover * cell * 0.024)
        ..rotate(hover * 0.055);
    }
    TokenPainter.food(canvas, Offset.zero, cell * 0.34, piece);
    canvas.restore();
  }
}
