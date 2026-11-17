import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/board.dart';
import '../../core/square.dart';
import '../palette.dart';
import 'board_component.dart';

/// Pulsing dots on every legal destination. Food targets get a ring instead.
class MoveDots extends Component {
  MoveDots({required this.layout, required this.reducedMotion});

  final BoardLayout layout;
  final bool reducedMotion;

  List<Square> _squares = const [];
  Board? _board;
  Color _color = Palette.ink;
  double _t = 0;
  double _fade = 0;

  void show(List<Square> squares, Board board, Color color) {
    _squares = squares;
    _board = board;
    _color = color;
    _fade = 0;
  }

  void hide() => _squares = const [];

  @override
  void update(double dt) {
    _t += dt;
    _fade = math.min(1, _fade + dt * 5);
  }

  @override
  void render(Canvas canvas) {
    final c = layout.cell;
    final pulse = reducedMotion ? 0.0 : math.sin(_t * 4) * 0.5 + 0.5;
    for (final s in _squares) {
      final o = layout.center(s).toOffset();
      final isFood = _board?[s].isFood ?? false;
      if (isFood) {
        canvas.drawCircle(
          o,
          c * (0.44 + pulse * 0.03),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = c * 0.07
            ..color = _color.withValues(alpha: 0.85 * _fade),
        );
      } else {
        canvas
          ..drawCircle(
            o,
            c * (0.17 + pulse * 0.03),
            Paint()..color = Palette.white.withValues(alpha: 0.9 * _fade),
          )
          ..drawCircle(
            o,
            c * (0.12 + pulse * 0.03),
            Paint()..color = _color.withValues(alpha: 0.85 * _fade),
          );
      }
    }
  }
}
