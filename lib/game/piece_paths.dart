import 'dart:ui';

import '../core/piece.dart';

/// Original chess-piece silhouettes as vector paths in a unit box (0..1).
/// Drawn in code so they look the same on every platform (no font glyphs).
abstract final class PiecePaths {
  static final Map<PieceType, Path> _cache = {};

  /// Silhouette path for [p] in a 1×1 box.
  static Path of(PieceType p) => _cache.putIfAbsent(p, () => _build(p));

  /// Where the character's eyes sit (unit box) for each piece.
  static List<Offset> eyes(PieceType p) => switch (p) {
    PieceType.knight => const [Offset(0.40, 0.37)],
    PieceType.pawn => const [Offset(0.45, 0.31), Offset(0.55, 0.31)],
    PieceType.rook => const [Offset(0.43, 0.52), Offset(0.57, 0.52)],
    PieceType.bishop => const [Offset(0.44, 0.47), Offset(0.56, 0.47)],
    PieceType.queen => const [Offset(0.44, 0.67), Offset(0.56, 0.67)],
    PieceType.king => const [Offset(0.44, 0.45), Offset(0.56, 0.45)],
  };

  static Path _base() => Path()
    ..addRRect(
      RRect.fromLTRBR(0.24, 0.76, 0.76, 0.87, const Radius.circular(0.05)),
    );

  static Path _build(PieceType p) {
    final path = _base();
    switch (p) {
      case PieceType.pawn:
        path
          ..addOval(
            Rect.fromCircle(center: const Offset(0.5, 0.31), radius: 0.13),
          )
          ..addPolygon(const [
            Offset(0.40, 0.44),
            Offset(0.60, 0.44),
            Offset(0.68, 0.77),
            Offset(0.32, 0.77),
          ], true);
      case PieceType.rook:
        path
          ..addPolygon(const [
            Offset(0.33, 0.36),
            Offset(0.67, 0.36),
            Offset(0.70, 0.77),
            Offset(0.30, 0.77),
          ], true)
          ..addRect(const Rect.fromLTRB(0.26, 0.28, 0.74, 0.38));
        for (final x in const [0.26, 0.44, 0.62]) {
          path.addRRect(
            RRect.fromLTRBR(
              x,
              0.16,
              x + 0.12,
              0.30,
              const Radius.circular(0.02),
            ),
          );
        }
      case PieceType.bishop:
        path
          ..addOval(
            Rect.fromCircle(center: const Offset(0.5, 0.15), radius: 0.06),
          )
          ..moveTo(0.5, 0.21)
          ..cubicTo(0.72, 0.34, 0.70, 0.58, 0.61, 0.64)
          ..lineTo(0.39, 0.64)
          ..cubicTo(0.30, 0.58, 0.28, 0.34, 0.5, 0.21)
          ..close()
          ..addRRect(
            RRect.fromLTRBR(
              0.35,
              0.63,
              0.65,
              0.70,
              const Radius.circular(0.03),
            ),
          )
          ..addPolygon(const [
            Offset(0.42, 0.69),
            Offset(0.58, 0.69),
            Offset(0.64, 0.77),
            Offset(0.36, 0.77),
          ], true);
      case PieceType.queen:
        path
          ..addPolygon(const [
            Offset(0.30, 0.60),
            Offset(0.22, 0.30),
            Offset(0.305, 0.47),
            Offset(0.37, 0.24),
            Offset(0.435, 0.46),
            Offset(0.5, 0.20),
            Offset(0.565, 0.46),
            Offset(0.63, 0.24),
            Offset(0.695, 0.47),
            Offset(0.78, 0.30),
            Offset(0.70, 0.60),
          ], true)
          ..addPolygon(const [
            Offset(0.31, 0.58),
            Offset(0.69, 0.58),
            Offset(0.73, 0.77),
            Offset(0.27, 0.77),
          ], true);
        for (final (x, y) in const [
          (0.22, 0.28),
          (0.37, 0.22),
          (0.5, 0.18),
          (0.63, 0.22),
          (0.78, 0.28),
        ]) {
          path.addOval(Rect.fromCircle(center: Offset(x, y), radius: 0.045));
        }
      case PieceType.king:
        path
          ..addRect(const Rect.fromLTRB(0.465, 0.06, 0.535, 0.27))
          ..addRect(const Rect.fromLTRB(0.40, 0.11, 0.60, 0.18))
          ..moveTo(0.29, 0.58)
          ..cubicTo(0.20, 0.26, 0.80, 0.26, 0.71, 0.58)
          ..close()
          ..addPolygon(const [
            Offset(0.33, 0.56),
            Offset(0.67, 0.56),
            Offset(0.72, 0.77),
            Offset(0.28, 0.77),
          ], true);
      case PieceType.knight:
        path
          ..moveTo(0.30, 0.78)
          ..lineTo(0.74, 0.78)
          ..cubicTo(0.78, 0.52, 0.72, 0.28, 0.55, 0.20)
          ..lineTo(0.53, 0.10)
          ..lineTo(0.45, 0.19)
          ..cubicTo(0.35, 0.22, 0.25, 0.34, 0.20, 0.47)
          ..lineTo(0.19, 0.55)
          ..cubicTo(0.21, 0.62, 0.30, 0.63, 0.36, 0.57)
          ..lineTo(0.47, 0.50)
          ..cubicTo(0.44, 0.60, 0.33, 0.68, 0.30, 0.78)
          ..close();
    }
    path.fillType = PathFillType.nonZero;
    return path;
  }

  /// Draws [p]'s silhouette filling [rect] with [paint].
  static void draw(Canvas canvas, PieceType p, Rect rect, Paint paint) {
    canvas
      ..save()
      ..translate(rect.left, rect.top)
      ..scale(rect.width, rect.height);
    canvas.drawPath(of(p), paint);
    canvas.restore();
  }
}
