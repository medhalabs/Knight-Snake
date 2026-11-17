import 'package:flutter_test/flutter_test.dart';
import 'package:knightsnake/core/rng.dart';

void main() {
  test('known sequence for seed 1 (same on VM and web)', () {
    final rng = XorShift32(1);
    expect(
      [for (var i = 0; i < 4; i++) rng.nextUint32()],
      [270369, 67634689, 2647435461, 307599695],
    );
  });

  test('same seed gives same sequence; different seed differs', () {
    final a = XorShift32(42);
    final b = XorShift32(42);
    final c = XorShift32(43);
    final sa = [for (var i = 0; i < 20; i++) a.nextUint32()];
    final sb = [for (var i = 0; i < 20; i++) b.nextUint32()];
    final sc = [for (var i = 0; i < 20; i++) c.nextUint32()];
    expect(sa, sb);
    expect(sa, isNot(sc));
  });

  test('values stay unsigned 32-bit and seed 0 is fixed up', () {
    final rng = XorShift32(0);
    for (var i = 0; i < 1000; i++) {
      final v = rng.nextUint32();
      expect(v, inInclusiveRange(1, 0xFFFFFFFF));
    }
  });

  test('nextInt is in range and roughly uniform', () {
    final rng = XorShift32(7);
    final counts = List<int>.filled(6, 0);
    for (var i = 0; i < 6000; i++) {
      counts[rng.nextInt(6)]++;
    }
    for (final c in counts) {
      expect(c, inInclusiveRange(850, 1150));
    }
    expect(() => rng.nextInt(0), throwsArgumentError);
  });

  test('pick returns list items', () {
    final rng = XorShift32(3);
    for (var i = 0; i < 50; i++) {
      expect(['a', 'b', 'c'], contains(rng.pick(['a', 'b', 'c'])));
    }
  });
}
