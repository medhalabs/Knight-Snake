import 'dart:ui';

import '../core/piece.dart';

abstract final class Palette {
  static const background = Color(0xFF100D20);
  static const panel = Color(0xFF1C1731);
  static const panelLight = Color(0xFF26203E);
  static const line = Color(0xFF403458);
  static const white = Color(0xFFF7F0FF);
  static const muted = Color(0xFFB8ACC9);
  static const ink = Color(0xFF160E2A);
  static const violet = Color(0xFFC4A1FF);
  static const mint = Color(0xFFAAFFBF);
  static const star = Color(0xFFFFD47D);
  static const starOff = Color(0xFF786B91);
  static const danger = Color(0xFFFF819D);

  static const boardLight = Color(0xFF32264D);
  static const boardDark = Color(0xFF241B3B);
  static const coord = Color(0xFFAB98C5);
  static const exit = star;

  static Color head(PieceType p) => switch (p) {
    PieceType.knight => const Color(0xFFAC83FF),
    PieceType.bishop => const Color(0xFF51E7D1),
    PieceType.rook => const Color(0xFFFFA66A),
    PieceType.queen => const Color(0xFFFF87CC),
    PieceType.king => star,
    PieceType.pawn => mint,
  };

  static Color tint(Color c, double amount) => Color.lerp(c, white, amount)!;
  static Color shade(Color c, double amount) =>
      Color.lerp(c, const Color(0xFF090615), amount)!;
}
