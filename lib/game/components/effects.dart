import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../core/rng.dart';
import '../palette.dart';

class FloatingText extends PositionComponent {
  FloatingText(
    this.text, {
    required Vector2 at,
    required this.cell,
    required this.reducedMotion,
    this.reason,
    this.color = Palette.white,
    this.victory = false,
  }) : super(position: at, priority: victory ? 60 : 50);

  final String text;
  final String? reason;
  final Color color;
  final double cell;
  final bool reducedMotion;
  final bool victory;
  double _t = 0;

  double get _life => victory ? 0.92 : 0.64;

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (_t >= _life) return;
    final t = _t / _life;
    final alpha = reducedMotion ? 1.0 : ((1 - t) * 4).clamp(0.0, 1.0);
    final drift = reducedMotion || victory ? 0.0 : t * cell * 0.36;
    final scale = reducedMotion
        ? 1.0
        : 1 + math.sin(math.pi * math.min(1, t * 3.5)) * 0.16;
    final titleSize = cell * (victory ? 0.66 : 0.42);
    canvas
      ..save()
      ..translate(0, -drift)
      ..scale(scale);
    _label(canvas, text, titleSize, color, alpha, Offset.zero);
    if (reason case final detail?) {
      _label(
        canvas,
        detail,
        cell * 0.24,
        Palette.star,
        alpha,
        Offset(0, cell * 0.42),
      );
    }
    canvas.restore();
  }

  void _label(
    Canvas canvas,
    String text,
    double size,
    Color color,
    double alpha,
    Offset at,
  ) {
    final style = TextStyle(
      fontSize: size,
      fontFamily: 'Roboto',
      fontWeight: FontWeight.w900,
      letterSpacing: size * 0.065,
    );
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size * 0.22
      ..color = Palette.ink.withValues(alpha: alpha * 0.95);
    final back = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(foreground: outline),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final front = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(color: color.withValues(alpha: alpha)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final origin = at - Offset(front.width / 2, front.height / 2);
    back.paint(canvas, origin);
    front.paint(canvas, origin);
    back.dispose();
    front.dispose();
  }
}

class ImpactRing extends PositionComponent {
  ImpactRing({
    required Vector2 at,
    required this.cell,
    required this.color,
    this.strength = 1,
  }) : super(position: at, priority: 30);

  final double cell;
  final Color color;
  final double strength;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt / 0.38;
    if (_t >= 1) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (_t >= 1) return;
    final back = 1 - _t;
    final r = cell * (0.34 + (1 - back * back) * 0.64 * strength);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * (0.014 + back * 0.045)
      ..color = color.withValues(alpha: back * 0.85);
    canvas
      ..drawCircle(Offset.zero, r, paint)
      ..drawCircle(
        Offset.zero,
        r * 0.84,
        paint
          ..strokeWidth = cell * 0.024
          ..color = color.withValues(alpha: back * 0.38),
      );
  }
}

class _Particle {
  _Particle(this.v, this.color, this.size, this.spin);
  Offset p = Offset.zero;
  Offset v;
  final Color color;
  final double size;
  final double spin;
}

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
  final List<_Particle> _particles = [];
  double _t = 0;

  double get _life => confetti ? 1.25 : 0.54;
  double _random() => _rng.nextInt(10000) / 10000;

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < count; i++) {
      final angle = _random() * math.pi * 2;
      final speed =
          cell * (confetti ? 2.5 + _random() * 4 : 1.4 + _random() * 3);
      _particles.add(
        _Particle(
          Offset(
            math.cos(angle) * speed,
            math.sin(angle) * speed - (confetti ? cell * 2.4 : 0),
          ),
          colors[i % colors.length],
          cell * (0.032 + _random() * 0.05),
          2 + _random() * 9,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    _t += dt;
    final friction = math.max(0.0, 1 - dt * 1.5);
    final gravity = cell * (confetti ? 6 : 2.5);
    for (final p in _particles) {
      p
        ..v = Offset(p.v.dx * friction, p.v.dy + gravity * dt)
        ..p = p.p + p.v * dt;
    }
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (_t >= _life) return;
    final alpha = ((1 - _t / _life) * 1.8).clamp(0.0, 1.0);
    final paint = Paint();
    for (final p in _particles) {
      paint.color = p.color.withValues(alpha: alpha);
      if (confetti) {
        canvas
          ..save()
          ..translate(p.p.dx, p.p.dy)
          ..rotate(p.spin * _t)
          ..drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: p.size * 2.3,
                height: p.size,
              ),
              Radius.circular(p.size * 0.25),
            ),
            paint,
          )
          ..restore();
      } else {
        final tail = p.p - p.v * 0.026;
        canvas.drawLine(
          tail,
          p.p,
          paint
            ..strokeCap = StrokeCap.round
            ..strokeWidth = p.size * 1.35,
        );
      }
    }
  }
}
