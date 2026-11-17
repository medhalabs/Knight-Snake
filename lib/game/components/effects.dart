import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../core/rng.dart';
import '../palette.dart';

TextPainter _label(String text, double size, Color fill, {Color? outline}) {
  final style = TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w900,
    letterSpacing: size * 0.02,
  );
  return TextPainter(
    text: TextSpan(
      children: [
        TextSpan(
          text: text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size * 0.18
              ..strokeJoin = StrokeJoin.round
              ..color = outline ?? Palette.ink,
          ),
        ),
      ],
    ),
    textDirection: TextDirection.ltr,
  )..layout();
}

void _paintOutlined(
  Canvas canvas,
  String text,
  double size,
  Color fill,
  Offset center,
  double alpha,
) {
  final back = _label(text, size, fill);
  final front = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: size * 0.02,
        color: fill,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final at = center - Offset(front.width / 2, front.height / 2);
  canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, alpha));
  back.paint(canvas, at);
  front.paint(canvas, at);
  canvas.restore();
}

/// `+60` with an optional reason line (e.g. `COMBO ×2`) that floats up.
class FloatingText extends PositionComponent {
  FloatingText(
    this.text,
    this.reason, {
    required Vector2 at,
    required this.cell,
  }) : super(position: at, priority: 50);

  final String text;
  final String? reason;
  final double cell;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    position.y -= dt * cell * 0.9;
    if (_t > 1.1) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = _t < 0.8 ? 1.0 : (1 - (_t - 0.8) / 0.3).clamp(0.0, 1.0);
    final s = math.min(1.0, 0.6 + _t * 4);
    _paintOutlined(
      canvas,
      text,
      cell * 0.38 * s,
      Palette.white,
      Offset.zero,
      alpha,
    );
    if (reason != null) {
      _paintOutlined(
        canvas,
        reason!,
        cell * 0.24 * s,
        Palette.star,
        Offset(0, cell * 0.34),
        alpha,
      );
    }
  }
}

/// Big praise word in the middle of the board (NICE!, GREAT!, CHECKMATE!).
class PraiseText extends PositionComponent {
  PraiseText(
    this.text, {
    required Vector2 at,
    required this.fontSize,
    this.color,
  }) : super(position: at, priority: 60);

  final String text;
  final double fontSize;
  final Color? color;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    if (_t > 1.3) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final grow = _t < 0.25 ? _t / 0.25 : 1.0;
    final scale = grow < 1
        ? 0.3 + 0.9 * grow
        : 1.2 - 0.2 * math.min(1, (_t - 0.25) * 4);
    final alpha = _t < 1.0 ? 1.0 : (1 - (_t - 1.0) / 0.3).clamp(0.0, 1.0);
    canvas
      ..save()
      ..rotate(-0.06)
      ..scale(scale);
    _paintOutlined(
      canvas,
      text,
      fontSize,
      color ?? Palette.star,
      Offset.zero,
      alpha,
    );
    canvas.restore();
  }
}

class _Particle {
  _Particle(this.p, this.v, this.color, this.size, this.spin, this.square);
  Offset p;
  Offset v;
  final Color color;
  final double size;
  final double spin;
  final bool square;
}

/// Particle burst (eat) or confetti (win). Uses a seeded RNG.
class Burst extends PositionComponent {
  Burst({
    required Vector2 at,
    required this.colors,
    required this.cell,
    this.count = 16,
    this.confetti = false,
    int seed = 1,
  }) : _rng = XorShift32(seed),
       super(position: at, priority: 40);

  final List<Color> colors;
  final double cell;
  final int count;
  final bool confetti;
  final XorShift32 _rng;
  final List<_Particle> _ps = [];
  double _t = 0;

  double get _life => confetti ? 2.2 : 0.7;
  double _r() => _rng.nextInt(10000) / 10000;

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < count; i++) {
      final a = _r() * math.pi * 2;
      final speed = cell * (confetti ? 3 + _r() * 5 : 1.5 + _r() * 2.5);
      final v = Offset(
        math.cos(a) * speed,
        math.sin(a) * speed - (confetti ? cell * 4 : 0),
      );
      _ps.add(
        _Particle(
          Offset.zero,
          v,
          colors[i % colors.length],
          cell * (confetti ? 0.09 + _r() * 0.06 : 0.06 + _r() * 0.06),
          _r() * 10,
          confetti,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    _t += dt;
    final g = cell * (confetti ? 7 : 3);
    for (final p in _ps) {
      p
        ..v = Offset(p.v.dx * (1 - dt * 1.5), p.v.dy + g * dt)
        ..p = p.p + p.v * dt;
    }
    if (_t > _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1 - _t / _life).clamp(0.0, 1.0);
    for (final p in _ps) {
      final paint = Paint()..color = p.color.withValues(alpha: alpha);
      if (p.square) {
        canvas
          ..save()
          ..translate(p.p.dx, p.p.dy)
          ..rotate(p.spin * _t)
          ..drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size * 2,
              height: p.size,
            ),
            paint,
          )
          ..restore();
      } else {
        canvas.drawCircle(p.p, p.size, paint);
      }
    }
  }
}
