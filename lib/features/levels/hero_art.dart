import 'package:flutter/rendering.dart';

import '../../core/piece.dart';
import '../../game/components/token_painter.dart';
import '../../game/palette.dart';

/// The title illustration uses the same tokens as the playable board.
class HeroArt extends CustomPainter {
  const HeroArt();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / 260;
    canvas
      ..save()
      ..translate(size.width / 2, 0)
      ..scale(scale);
    const center = Offset(0, 145);
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x9056369E), Color(0x004A318A)],
      ).createShader(Rect.fromCircle(center: center, radius: 155));
    canvas.drawCircle(center, 155, paint);
    paint
      ..shader = null
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final r in [91.0, 116.0, 145.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: center, width: r * 2.7, height: r * 1.22),
        paint..color = const Color(0x556B5197),
      );
    }
    for (final (x, y, radius, color) in const [
      (-166.0, 95.0, 6.0, Palette.violet),
      (150.0, 82.0, 8.0, Palette.mint),
      (117.0, 40.0, 3.0, Palette.star),
      (-96.0, 27.0, 5.0, Palette.star),
      (164.0, 189.0, 4.0, Palette.violet),
      (-129.0, 217.0, 4.0, Palette.mint),
      (85.0, 235.0, 4.0, Palette.violet),
    ]) {
      _spark(canvas, Offset(x, y), radius, color);
    }

    Offset p(int x, int y) => Offset((x - y) * 23.0, 105 + (x + y) * 11.0);
    final rim = Path()..addPolygon([p(0, 0), p(6, 0), p(6, 6), p(0, 6)], true);
    paint.style = PaintingStyle.fill;
    canvas
      ..drawPath(
        rim.shift(const Offset(0, 10)),
        paint..color = const Color(0xFF160D2A),
      )
      ..drawPath(
        rim.shift(const Offset(0, 4)),
        paint..color = const Color(0xFF8057C1),
      );
    for (var x = 0; x < 6; x++) {
      for (var y = 0; y < 6; y++) {
        final tile = Path()
          ..addPolygon([
            p(x, y),
            p(x + 1, y),
            p(x + 1, y + 1),
            p(x, y + 1),
          ], true);
        canvas.drawPath(
          tile,
          paint
            ..color = (x + y).isEven
                ? const Color(0xFF61448F)
                : const Color(0xFF392958),
        );
      }
    }
    canvas.drawPath(
      rim,
      paint
        ..style = PaintingStyle.stroke
        ..color = Palette.violet
        ..strokeWidth = 1.45,
    );
    final trail = Path()
      ..moveTo(-72, 169)
      ..quadraticBezierTo(-21, 230, 30, 181)
      ..quadraticBezierTo(71, 139, 18, 139);
    canvas
      ..drawPath(
        trail,
        paint
          ..strokeWidth = 15
          ..strokeCap = StrokeCap.round
          ..color = const Color(0x997F5AD0),
      )
      ..drawPath(
        trail,
        paint
          ..strokeWidth = 2.5
          ..color = Palette.violet,
      );
    TokenPainter.food(canvas, const Offset(-94, 144), 24, PieceType.pawn);
    TokenPainter.food(canvas, const Offset(99, 160), 30, PieceType.bishop);
    TokenPainter.head(canvas, const Offset(-1, 94), 67, PieceType.knight);
    _spark(canvas, const Offset(54, 48), 12, Palette.white);
    _spark(canvas, const Offset(-55, 127), 7, Palette.violet);
    canvas.restore();
  }

  void _spark(Canvas canvas, Offset o, double r, Color color) {
    final path = Path()
      ..addPolygon([
        o.translate(0, -r),
        o.translate(r * 0.23, -r * 0.23),
        o.translate(r, 0),
        o.translate(r * 0.23, r * 0.23),
        o.translate(0, r),
        o.translate(-r * 0.23, r * 0.23),
        o.translate(-r, 0),
        o.translate(-r * 0.23, -r * 0.23),
      ], true);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(HeroArt oldDelegate) => false;
}
