import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

import '../../core/board.dart';
import '../../core/square.dart';
import '../palette.dart';

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

class BoardComponent extends PositionComponent
    with TapCallbacks, DragCallbacks {
  BoardComponent({
    required this.layout,
    required this.board,
    required this.onSquare,
    required this.canStartDrag,
    required this.time,
  }) : super(size: Vector2.all(layout.size));

  final BoardLayout layout;
  final Board board;
  final void Function(Square square, {required bool dragged}) onSquare;
  final bool Function(Square) canStartDrag;
  final double Function() time;
  ui.Picture? _tiles;

  Vector2? _dragPos;
  int? _dragPointer;

  @override
  void onTapUp(TapUpEvent event) {
    final s = layout.squareAt(event.localPosition);
    if (s != null) onSquare(s, dragged: false);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    final from = layout.squareAt(event.localPosition);
    if (_dragPointer != null || from == null || !canStartDrag(from)) return;
    _dragPointer = event.pointerId;
    _dragPos = event.localPosition.clone();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (event.pointerId == _dragPointer) {
      _dragPos?.add(event.deviceDelta);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (event.pointerId != _dragPointer) return;
    final p = _dragPos!;
    clearDrag();
    final s = layout.squareAt(p);
    if (s != null) onSquare(s, dragged: true);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    if (event.pointerId == _dragPointer) clearDrag();
    super.onDragCancel(event);
  }

  void clearDrag() {
    _dragPointer = null;
    _dragPos = null;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawPicture(_tiles ??= _recordTiles());
    final exit = board.exitSquare;
    if (exit != null) _drawExit(canvas, exit);
  }

  ui.Picture _recordTiles() {
    final recorder = ui.PictureRecorder();
    final d = layout.size;
    final c = layout.cell;
    final bounds = Rect.fromLTWH(0, 0, d, d);
    final canvas = Canvas(recorder, bounds);
    final paint = Paint();
    for (final s in Square.all) {
      final light = (s.file + s.rank).isOdd;
      final color = light ? Palette.boardLight : Palette.boardDark;
      final o = layout.center(s).toOffset();
      final tile = Rect.fromCenter(
        center: o,
        width: c + 0.15,
        height: c + 0.15,
      );
      canvas
        ..drawRect(
          tile,
          paint
            ..shader = ui.Gradient.linear(
              tile.topLeft,
              tile.bottomRight,
              [Palette.tint(color, 0.055), color, Palette.shade(color, 0.10)],
              const [0, 0.49, 1],
            ),
        )
        ..drawLine(
          tile.topLeft,
          tile.topRight,
          paint
            ..shader = null
            ..strokeWidth = 1
            ..color = const Color(0x227C61B1),
        )
        ..drawLine(tile.topLeft, tile.bottomLeft, paint)
        ..drawCircle(
          tile.topLeft.translate(c * 0.11, c * 0.11),
          c * 0.018,
          paint..color = const Color(0x407B65A1),
        );
    }
    canvas.drawRect(
      bounds,
      paint
        ..shader = ui.Gradient.radial(
          bounds.center,
          d * 0.7,
          [
            const Color(0x00503A72),
            const Color(0x335B3D89),
            const Color(0x800D0A18),
          ],
          const [0.16, 0.65, 1],
        ),
    );
    for (final s in Square.all) {
      if (board[s].isRock) _drawRock(canvas, s);
    }
    for (var i = 0; i < 8; i++) {
      _text(
        canvas,
        String.fromCharCode(0x61 + i),
        Offset((i + 0.94) * c, 7.98 * c),
        alignEnd: true,
      );
      _text(canvas, '${8 - i}', Offset(0.063 * c, (i + 0.15) * c));
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds.deflate(0.8), const Radius.circular(11)),
      paint
        ..shader = null
        ..color = const Color(0x665D4979)
        ..style = PaintingStyle.stroke,
    );
    return recorder.endRecording();
  }

  void _text(Canvas canvas, String s, Offset at, {bool alignEnd = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: Palette.coord,
          fontSize: layout.cell * 0.16,
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, alignEnd ? at - Offset(tp.width, tp.height) : at);
    tp.dispose();
  }

  void _drawRock(Canvas canvas, Square s) {
    final c = layout.cell;
    final o = layout.center(s).toOffset();
    final canvasPaint = Paint();
    final a = o.translate(-c * 0.37, c * 0.10);
    final b = o.translate(-c * 0.26, -c * 0.21);
    final d = o.translate(c * 0.12, -c * 0.32);
    final e = o.translate(c * 0.37, -c * 0.04);
    final f = o.translate(c * 0.25, c * 0.27);
    final g = o.translate(-c * 0.19, c * 0.30);
    final peak = o.translate(c * 0.06, -c * 0.04);
    final rim = Path()..addPolygon([a, b, d, e, f, g], true);
    canvas
      ..drawPath(
        rim.shift(Offset(0, c * 0.09)),
        canvasPaint..color = Palette.ink,
      )
      ..drawPath(rim, canvasPaint..color = const Color(0xFF554566));
    for (final (points, color) in [
      ([a, b, d, peak], const Color(0xFF8B7AA1)),
      ([d, e, peak], const Color(0xFFA091B5)),
      ([a, peak, f, g], const Color(0xFF69577D)),
      ([peak, e, f], const Color(0xFF453853)),
    ]) {
      canvas.drawPath(
        Path()..addPolygon(points, true),
        canvasPaint..color = color,
      );
    }
  }

  void _drawExit(Canvas canvas, Square s) {
    final c = layout.cell;
    final o = layout.center(s).toOffset();
    final pulse = 0.5 + 0.5 * math.sin(time() * 3);
    final paint = Paint();
    canvas
      ..drawCircle(
        o,
        c * 0.33,
        paint..color = Palette.exit.withValues(alpha: 0.10),
      )
      ..drawCircle(
        o,
        c * (0.33 + pulse * 0.05),
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = c * 0.027
          ..color = Palette.exit.withValues(alpha: 0.64),
      )
      ..drawPath(
        Path()..addPolygon([
          o.translate(-c * 0.13, c * 0.19),
          o.translate(-c * 0.13, -c * 0.18),
          o.translate(c * 0.17, -c * 0.10),
          o.translate(-c * 0.13, 0),
        ], false),
        paint
          ..strokeWidth = c * 0.037
          ..strokeJoin = StrokeJoin.round
          ..color = Palette.exit,
      );
  }

  @override
  void onRemove() {
    _tiles?.dispose();
    _tiles = null;
    super.onRemove();
  }
}
