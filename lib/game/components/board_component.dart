import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

import '../../core/board.dart';
import '../../core/square.dart';
import '../palette.dart';

/// Converts between board squares and pixel positions (rank 8 on top).
class BoardLayout {
  BoardLayout(this.size);
  final double size;
  double get cell => size / 8;

  Vector2 center(Square s) =>
      Vector2((s.file + 0.5) * cell, (7 - s.rank + 0.5) * cell);

  Square? squareAt(Vector2 p) {
    final f = (p.x / cell).floor();
    final r = 7 - (p.y / cell).floor();
    return Square.onBoard(f, r) ? Square(f, r) : null;
  }
}

/// Draws the checkered board, coordinates, rocks and the exit, and turns
/// taps / drags into square callbacks.
class BoardComponent extends PositionComponent
    with TapCallbacks, DragCallbacks {
  BoardComponent({
    required this.layout,
    required this.board,
    required this.onSquare,
    required this.time,
  }) : super(size: Vector2.all(layout.size));

  final BoardLayout layout;
  Board board;
  final void Function(Square square, {required bool dragged}) onSquare;

  /// Shared clock (seconds) for idle animation.
  final double Function() time;

  Vector2? _dragPos;

  @override
  void onTapUp(TapUpEvent event) {
    final s = layout.squareAt(event.localPosition);
    if (s != null) onSquare(s, dragged: false);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _dragPos = event.localPosition.clone();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _dragPos?.add(event.localDelta);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    final p = _dragPos;
    _dragPos = null;
    if (p == null) return;
    final s = layout.squareAt(p);
    if (s != null) onSquare(s, dragged: true);
  }

  @override
  void render(Canvas canvas) {
    final c = layout.cell;
    final outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, layout.size, layout.size),
      Radius.circular(c * 0.3),
    );
    canvas
      ..drawRRect(
        outer.shift(Offset(0, c * 0.08)),
        Paint()..color = Palette.boardEdge,
      )
      ..save()
      ..clipRRect(outer);
    for (final s in Square.all) {
      final tl = layout.center(s) - Vector2.all(c / 2);
      final light = (s.file + s.rank).isOdd;
      canvas.drawRect(
        Rect.fromLTWH(tl.x, tl.y, c, c),
        Paint()..color = light ? Palette.boardLight : Palette.boardDark,
      );
    }
    _drawCoords(canvas);
    canvas.restore();
    for (final s in Square.all) {
      final t = board[s];
      if (t.isRock) _drawRock(canvas, s);
      if (t.isExit) _drawExit(canvas, s);
    }
  }

  void _drawCoords(Canvas canvas) {
    final c = layout.cell;
    for (var i = 0; i < 8; i++) {
      _text(
        canvas,
        String.fromCharCode(0x61 + i),
        Offset((i + 0.92) * c, 7.98 * c),
        alignEnd: true,
      );
      _text(canvas, '${8 - i}', Offset(0.06 * c, (i + 0.04) * c));
    }
  }

  void _text(Canvas canvas, String s, Offset at, {bool alignEnd = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: Palette.coord,
          fontSize: layout.cell * 0.17,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignEnd ? at.dx - tp.width : at.dx;
    final dy = alignEnd ? at.dy - tp.height : at.dy;
    tp.paint(canvas, Offset(dx, dy));
  }

  void _drawRock(Canvas canvas, Square s) {
    final c = layout.cell;
    final o = layout.center(s).toOffset();
    final blob = Path()
      ..moveTo(o.dx - c * 0.36, o.dy + c * 0.18)
      ..cubicTo(
        o.dx - c * 0.42,
        o.dy - c * 0.10,
        o.dx - c * 0.20,
        o.dy - c * 0.36,
        o.dx + c * 0.02,
        o.dy - c * 0.32,
      )
      ..cubicTo(
        o.dx + c * 0.30,
        o.dy - c * 0.30,
        o.dx + c * 0.44,
        o.dy - c * 0.04,
        o.dx + c * 0.38,
        o.dy + c * 0.20,
      )
      ..cubicTo(
        o.dx + c * 0.30,
        o.dy + c * 0.36,
        o.dx - c * 0.28,
        o.dy + c * 0.38,
        o.dx - c * 0.36,
        o.dy + c * 0.18,
      )
      ..close();
    canvas
      ..drawPath(
        blob.shift(Offset(0, c * 0.05)),
        Paint()..color = Palette.rockShade,
      )
      ..drawPath(blob, Paint()..color = Palette.rock)
      ..drawOval(
        Rect.fromCenter(
          center: o.translate(-c * 0.12, -c * 0.14),
          width: c * 0.26,
          height: c * 0.12,
        ),
        Paint()..color = Palette.rockLight,
      );
  }

  void _drawExit(Canvas canvas, Square s) {
    final c = layout.cell;
    final o = layout.center(s).toOffset();
    final pulse = 0.5 + 0.5 * math.sin(time() * 3);
    for (var i = 0; i < 3; i++) {
      final r = c * (0.18 + i * 0.1 + pulse * 0.03);
      canvas.drawCircle(
        o,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = c * 0.05
          ..color = Palette.exit.withValues(alpha: 0.9 - i * 0.25),
      );
    }
    // A small flag so it reads as "go here" without text or colour alone.
    final pole = Paint()
      ..color = Palette.ink
      ..strokeWidth = c * 0.04
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(
        o.translate(-c * 0.04, c * 0.14),
        o.translate(-c * 0.04, -c * 0.16),
        pole,
      )
      ..drawPath(
        Path()
          ..moveTo(o.dx - c * 0.03, o.dy - c * 0.16)
          ..lineTo(o.dx + c * 0.14, o.dy - c * 0.09)
          ..lineTo(o.dx - c * 0.03, o.dy - c * 0.02)
          ..close(),
        Paint()..color = Palette.danger,
      );
  }
}
