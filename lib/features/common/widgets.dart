import 'package:material_ui/material_ui.dart';

import '../../core/piece.dart';
import '../../game/components/token_painter.dart';
import '../../game/palette.dart';

const arcadeLabel = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w800,
  letterSpacing: 1.65,
  color: Palette.muted,
);

const arcadeNumber = TextStyle(
  fontSize: 25,
  fontWeight: FontWeight.w900,
  color: Palette.white,
  fontFeatures: [FontFeature.tabularFigures()],
);

class PieceIcon extends StatelessWidget {
  const PieceIcon(this.piece, {super.key, this.size = 28, this.asHead = false});

  final PieceType piece;
  final double size;
  final bool asHead;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _TokenPainter(piece, asHead)),
  );
}

class _TokenPainter extends CustomPainter {
  const _TokenPainter(this.piece, this.asHead);
  final PieceType piece;
  final bool asHead;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide * 0.40;
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

class ArcadeIconButton extends StatelessWidget {
  const ArcadeIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: IconButton.outlined(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(44),
        foregroundColor: Palette.white,
        backgroundColor: Palette.panel,
        side: const BorderSide(color: Palette.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    ),
  );
}

class CountUp extends StatelessWidget {
  const CountUp(
    this.value, {
    super.key,
    this.style,
    this.ms = 320,
    this.reducedMotion = false,
  });

  final int value;
  final TextStyle? style;
  final int ms;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    if (reducedMotion || MediaQuery.disableAnimationsOf(context)) {
      return Text('$value', style: style);
    }
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: Duration(milliseconds: ms),
      curve: Curves.easeOut,
      builder: (_, v, _) => Text('$v', style: style),
    );
  }
}

class ArcadeBackground extends StatelessWidget {
  const ArcadeBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.68, -0.38),
          radius: 1.02,
          colors: [Color(0xFF291948), Palette.background],
        ),
      ),
      child: CustomPaint(painter: const _BackdropGrid(), child: child),
    ),
  );
}

class _BackdropGrid extends CustomPainter {
  const _BackdropGrid();

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 32.0;
    final paint = Paint()..color = const Color(0x147F66AD);
    for (var x = 16.0; x < size.width; x += spacing) {
      for (var y = 16.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BackdropGrid oldDelegate) => false;
}
