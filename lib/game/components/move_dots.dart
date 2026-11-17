import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/board.dart';
import '../../core/square.dart';
import '../palette.dart';
import 'board_component.dart';

/// Diamonds mark legal landings. Capture targets get four mint corners.
class MoveDots extends Component {
  MoveDots({required this.layout, required this.reducedMotion});

  final BoardLayout layout;
  final bool reducedMotion;

  List<Square> _squares = const [];
  Board? _board;
  Color _color = Palette.violet;
  double _t = 0;
  Square? _rejected;
  double _rejectTime = 0;

  void show(List<Square> squares, Board board, Color color) {
    _squares = squares;
    _board = board;
    _color = Palette.tint(color, 0.32);
  }

  void hide() {
    _squares = const [];
    _rejected = null;
  }

  void reject(Square s) {
    _rejected = s;
    _rejectTime = 0.32;
  }

  @override
  void update(double dt) {
    _t += dt;
    _rejectTime = math.max(0, _rejectTime - dt);
  }

  @override
  void render(Canvas canvas) {
    final c = layout.cell;
    final pulse = reducedMotion ? 0.5 : math.sin(_t * 3) * 0.5 + 0.5;
    final paint = Paint();
    for (final s in _squares) {
      final o = layout.center(s).toOffset();
      final capture = _board![s].isFood;
      final exit = _board![s].isExit;
      final color = capture
          ? Palette.mint
          : exit
          ? Palette.exit
          : _color;
      final tile = Rect.fromCenter(
        center: o,
        width: c * 0.91,
        height: c * 0.91,
      );
      final shape = RRect.fromRectAndRadius(tile, Radius.circular(c * 0.14));
      canvas.drawRRect(
        shape,
        paint
          ..style = PaintingStyle.fill
          ..shader = Gradient.radial(o, c * 0.65, [
            color.withValues(alpha: 0.13 + pulse * 0.06),
            color.withValues(alpha: 0.045),
          ]),
      );
      paint
        ..shader = null
        ..color = color.withValues(alpha: capture ? 0.86 : 0.32 + pulse * 0.13)
        ..style = PaintingStyle.stroke
        ..strokeWidth = c * (capture ? 0.033 : 0.019);
      if (capture) {
        final marks = Path();
        for (final (corner, signX, signY) in [
          (tile.topLeft, 1, 1),
          (tile.topRight, -1, 1),
          (tile.bottomLeft, 1, -1),
          (tile.bottomRight, -1, -1),
        ]) {
          final a = corner.translate(signX * c * 0.045, signY * c * 0.045);
          marks
            ..moveTo(a.dx, a.dy + signY * c * 0.14)
            ..lineTo(a.dx, a.dy)
            ..lineTo(a.dx + signX * c * 0.14, a.dy);
        }
        canvas.drawPath(
          marks,
          paint
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      } else {
        canvas.drawRRect(shape, paint);
        final y = exit ? c * 0.28 : 0.0;
        final center = o.translate(0, y);
        final r = c * (0.075 + 0.018 * pulse);
        final diamond = Path()
          ..addPolygon([
            center.translate(0, -r),
            center.translate(r, 0),
            center.translate(0, r),
            center.translate(-r, 0),
          ], true);
        canvas.drawPath(
          diamond,
          paint
            ..style = PaintingStyle.fill
            ..color = color,
        );
      }
    }
    final rejected = _rejected;
    if (rejected == null || _rejectTime == 0) return;
    final o = layout.center(rejected).toOffset();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: o, width: c * 0.86, height: c * 0.86),
        Radius.circular(c * 0.12),
      ),
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = c * 0.035
        ..color = Palette.danger.withValues(
          alpha: reducedMotion ? 0.76 : _rejectTime / 0.32,
        ),
    );
  }
}
