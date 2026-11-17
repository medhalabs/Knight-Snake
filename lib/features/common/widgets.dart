import 'package:material_ui/material_ui.dart';

import '../../core/piece.dart';
import '../../game/components/token_painter.dart';
import '../../game/palette.dart';

/// A piece token drawn with the same vector paths as the board.
class PieceIcon extends StatelessWidget {
  const PieceIcon(this.piece, {super.key, this.size = 28, this.asHead = false});

  final PieceType piece;
  final double size;

  /// Colored head token (true) or dark food token (false).
  final bool asHead;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _TokenPainter(piece, asHead)),
  );
}

class _TokenPainter extends CustomPainter {
  _TokenPainter(this.piece, this.asHead);
  final PieceType piece;
  final bool asHead;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide * 0.46;
    if (asHead) {
      TokenPainter.head(canvas, c, r, piece);
    } else {
      TokenPainter.food(canvas, c, r, piece);
    }
  }

  @override
  bool shouldRepaint(_TokenPainter old) =>
      old.piece != piece || old.asHead != asHead;
}

/// White rounded pill used across the HUD.
class Pill extends StatelessWidget {
  const Pill({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(40),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

/// Round candy button with an icon (≥ 48 px touch target).
class CandyButton extends StatelessWidget {
  const CandyButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.color = const Color(0xFF8E5CF7),
    this.size = 52,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: onPressed == null ? Palette.starOff : color,
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Icon(icon, color: Colors.white, size: size * 0.52),
          ),
        ),
      ),
    ),
  );
}

/// Counts up (never jumps) to [value].
class CountUp extends StatelessWidget {
  const CountUp(this.value, {super.key, this.style, this.ms = 500});
  final int value;
  final TextStyle? style;
  final int ms;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<int>(
    tween: IntTween(begin: 0, end: value),
    duration: Duration(milliseconds: ms),
    curve: Curves.easeOut,
    builder: (_, v, _) => Text('$v', style: style),
  );
}

/// Soft sky gradient used behind every screen.
class SkyBackground extends StatelessWidget {
  const SkyBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Palette.skyTop, Palette.skyBottom],
      ),
    ),
    child: child,
  );
}
