import 'dart:ui';

import '../../core/piece.dart';
import '../palette.dart';
import '../piece_paths.dart';

/// Paints round piece tokens: the snake head (colored, white silhouette,
/// eyes) and food (dark, light silhouette).
abstract final class TokenPainter {
  /// Glossy colored head token with a white silhouette and eyes.
  /// [blink] 0 = open, 1 = closed. [look] shifts the pupils (unit offset).
  static void head(
    Canvas canvas,
    Offset c,
    double radius,
    PieceType type, {
    double blink = 0,
    Offset look = Offset.zero,
  }) {
    final color = Palette.head(type);
    _glossyCircle(canvas, c, radius, color);
    final box = Rect.fromCircle(center: c, radius: radius * 0.86);
    PiecePaths.draw(
      canvas,
      type,
      box.shift(Offset(0, radius * 0.04)),
      Paint()..color = Palette.shade(color, 0.35),
    );
    PiecePaths.draw(canvas, type, box, Paint()..color = Palette.white);
    _eyes(canvas, type, box, blink, look);
  }

  /// Dark food token with a light silhouette.
  static void food(Canvas canvas, Offset c, double radius, PieceType type) {
    canvas
      ..drawCircle(
        c.translate(0, radius * 0.1),
        radius,
        Paint()..color = const Color(0x33000000),
      )
      ..drawCircle(c, radius, Paint()..color = Palette.foodRim)
      ..drawCircle(c, radius * 0.88, Paint()..color = Palette.foodToken);
    final box = Rect.fromCircle(center: c, radius: radius * 0.78);
    PiecePaths.draw(canvas, type, box, Paint()..color = Palette.foodSilhouette);
    if (type == PieceType.pawn) {
      // Pawn snacks get a small green dot so they differ from heads by more
      // than shape (they never change your head).
      canvas.drawCircle(
        c.translate(radius * 0.62, -radius * 0.62),
        radius * 0.16,
        Paint()..color = Palette.head(PieceType.pawn),
      );
    }
  }

  static void _glossyCircle(Canvas canvas, Offset c, double r, Color color) {
    canvas
      ..drawCircle(
        c.translate(0, r * 0.12),
        r,
        Paint()..color = Palette.shade(color, 0.3),
      )
      ..drawCircle(
        c,
        r,
        Paint()
          ..shader = Gradient.radial(
            c.translate(-r * 0.35, -r * 0.4),
            r * 1.6,
            [Palette.tint(color, 0.35), color, Palette.shade(color, 0.12)],
            const [0, 0.55, 1],
          ),
      )
      ..drawOval(
        Rect.fromCenter(
          center: c.translate(-r * 0.32, -r * 0.5),
          width: r * 0.7,
          height: r * 0.32,
        ),
        Paint()..color = const Color(0x66FFFFFF),
      );
  }

  static void _eyes(
    Canvas canvas,
    PieceType type,
    Rect box,
    double blink,
    Offset look,
  ) {
    final r = box.width * 0.055;
    for (final e in PiecePaths.eyes(type)) {
      final o = Offset(
        box.left + e.dx * box.width,
        box.top + e.dy * box.height,
      );
      final open = (1 - blink).clamp(0.08, 1.0);
      canvas.drawOval(
        Rect.fromCenter(center: o, width: r * 2.2, height: r * 2.4 * open),
        Paint()..color = Palette.white,
      );
      final p = o + look * r * 0.4;
      canvas.drawOval(
        Rect.fromCenter(center: p, width: r * 1.4, height: r * 1.6 * open),
        Paint()..color = Palette.ink,
      );
      if (open > 0.5) {
        canvas.drawCircle(
          p.translate(-r * 0.3, -r * 0.35),
          r * 0.28,
          Paint()..color = Palette.white,
        );
      }
    }
  }
}
