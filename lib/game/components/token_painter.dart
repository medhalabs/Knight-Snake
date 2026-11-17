import 'dart:math' as math;
import 'dart:ui';

import '../../core/piece.dart';
import '../palette.dart';
import '../piece_paths.dart';

/// Faceted chess tokens, shared by the board, HUD and title art.
abstract final class TokenPainter {
  static void head(
    Canvas canvas,
    Offset c,
    double radius,
    PieceType type, {
    double blink = 0,
    Offset look = Offset.zero,
  }) {
    final color = Palette.head(type);
    _medal(canvas, c, radius, color, active: true);
    final box = Rect.fromCircle(center: c, radius: radius * 0.79);
    _piece(canvas, type, box, color, Palette.white);
    _eyes(canvas, type, box, blink, look);
  }

  static void food(Canvas canvas, Offset c, double radius, PieceType type) {
    final color = Palette.head(type);
    _medal(canvas, c, radius, color, active: false);
    _piece(
      canvas,
      type,
      Rect.fromCircle(center: c, radius: radius * 0.80),
      color,
      Palette.tint(color, 0.46),
    );
  }

  static void _medal(
    Canvas canvas,
    Offset c,
    double r,
    Color color, {
    required bool active,
  }) {
    final light = Palette.tint(color, 0.55);
    final shadow = Palette.shade(color, 0.80);
    final bevel = Rect.fromCircle(center: c, radius: r);
    final paint = Paint();
    canvas
      ..drawCircle(
        c,
        r * 1.36,
        paint
          ..shader = Gradient.radial(c, r * 1.36, [
            color.withValues(alpha: active ? 0.48 : 0.22),
            color.withValues(alpha: 0),
          ]),
      )
      ..drawCircle(
        c.translate(0, r * 0.14),
        r,
        paint
          ..shader = null
          ..color = Palette.ink,
      )
      ..drawCircle(
        c,
        r,
        paint
          ..shader = Gradient.linear(
            bevel.topLeft,
            bevel.bottomRight,
            [light, color, shadow],
            const [0, 0.38, 1],
          ),
      )
      ..drawCircle(
        c,
        r * 0.84,
        paint
          ..shader = Gradient.radial(
            c.translate(-r * 0.32, -r * 0.5),
            r * 1.55,
            [active ? color : Palette.shade(color, 0.62), shadow, Palette.ink],
            const [0, 0.72, 1],
          ),
      );
    paint
      ..shader = null
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.04
      ..color = light.withValues(alpha: 0.72);
    canvas.drawArc(bevel.deflate(r * 0.08), -2.96, 1.88, false, paint);
    paint.color = color.withValues(alpha: 0.44);
    canvas.drawArc(bevel.deflate(r * 0.15), 0.23, 1.68, false, paint);

    paint
      ..style = PaintingStyle.fill
      ..color = light;
    for (final angle in const [-0.82, 2.32]) {
      final x = c.dx + math.cos(angle) * r * 0.91;
      final y = c.dy + math.sin(angle) * r * 0.91;
      canvas.drawCircle(Offset(x, y), r * 0.035, paint);
    }
  }

  static void _piece(
    Canvas canvas,
    PieceType type,
    Rect box,
    Color color,
    Color light,
  ) {
    PiecePaths.draw(
      canvas,
      type,
      box.shift(Offset(0, box.width * 0.036)),
      Paint()..color = Palette.ink,
    );
    PiecePaths.draw(
      canvas,
      type,
      box,
      Paint()
        ..shader = Gradient.linear(
          box.topCenter,
          box.bottomCenter,
          [Palette.white, light, Palette.tint(color, 0.28)],
          const [0.26, 0.60, 0.95],
        ),
    );
  }

  static void _eyes(
    Canvas canvas,
    PieceType type,
    Rect box,
    double blink,
    Offset look,
  ) {
    final r = box.width * 0.038;
    final open = (1 - blink).clamp(0.12, 1.0);
    for (final e in PiecePaths.eyes(type)) {
      final p =
          Offset(box.left + e.dx * box.width, box.top + e.dy * box.height) +
          look * r * 0.4;
      canvas.drawOval(
        Rect.fromCenter(center: p, width: r * 1.9, height: r * 2.3 * open),
        Paint()..color = Palette.ink,
      );
      if (open > 0.6) {
        canvas.drawCircle(
          p.translate(-r * 0.22, -r * 0.37),
          r * 0.26,
          Paint()..color = Palette.white,
        );
      }
    }
  }
}
