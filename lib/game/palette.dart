import 'dart:ui';

import '../core/piece.dart';

/// Candy palette shared by the Flame game and the widgets.
abstract final class Palette {
  static const boardLight = Color(0xFFFFF6E8);
  static const boardDark = Color(0xFFCDEBD7);
  static const boardEdge = Color(0xFF9FD3B4);
  static const coord = Color(0x995B8A70);

  static const skyTop = Color(0xFFBDE6FF);
  static const skyBottom = Color(0xFFFFE3F1);

  static const foodToken = Color(0xFF2E3450);
  static const foodRim = Color(0xFF4A5378);
  static const foodSilhouette = Color(0xFFE9ECF8);

  static const rock = Color(0xFFB9BEC9);
  static const rockShade = Color(0xFF959BA8);
  static const rockLight = Color(0xFFDDE1E8);

  static const exit = Color(0xFFFFC93C);
  static const ink = Color(0xFF2B2D42);
  static const white = Color(0xFFFFFFFF);
  static const star = Color(0xFFFFC21A);
  static const starOff = Color(0xFFD9D9E3);
  static const danger = Color(0xFFFF5A5F);

  /// Head color per piece type (GAME_PLAN §5).
  static Color head(PieceType p) => switch (p) {
    PieceType.knight => const Color(0xFF8E5CF7),
    PieceType.bishop => const Color(0xFF14B8A6),
    PieceType.rook => const Color(0xFFFB8C2A),
    PieceType.queen => const Color(0xFFF0509A),
    PieceType.king => const Color(0xFFF5B800),
    PieceType.pawn => const Color(0xFF4CC36A),
  };

  /// Lighter tint used for the body gradient.
  static Color tint(Color c, double amount) =>
      Color.lerp(c, const Color(0xFFFFFFFF), amount)!;

  static Color shade(Color c, double amount) =>
      Color.lerp(c, const Color(0xFF000000), amount)!;
}
