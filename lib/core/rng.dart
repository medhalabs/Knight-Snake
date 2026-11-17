/// Seeded xorshift32 random number generator.
///
/// All arithmetic is masked to 32 bits so the sequence is identical on the
/// Dart VM and on the web (where ints are JS doubles).
class XorShift32 {
  XorShift32(int seed) : _state = _fixSeed(seed);

  int _state;

  /// Current internal state (for saving/restoring).
  int get state => _state;

  static int _fixSeed(int seed) {
    final s = seed & 0xFFFFFFFF;
    return s == 0 ? 0x9E3779B9 : s;
  }

  /// Next unsigned 32-bit value.
  int nextUint32() {
    var x = _state;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= (x << 5) & 0xFFFFFFFF;
    _state = x & 0xFFFFFFFF;
    return _state;
  }

  /// Uniform int in `[0, max)`. [max] must be in 1..2^32.
  int nextInt(int max) {
    if (max <= 0) throw ArgumentError.value(max, 'max', 'must be > 0');
    // Rejection sampling to avoid modulo bias.
    final limit = 0x100000000 - (0x100000000 % max);
    while (true) {
      final v = nextUint32();
      if (v < limit) return v % max;
    }
  }

  /// Picks a random element of [items] (must be non-empty).
  T pick<T>(List<T> items) => items[nextInt(items.length)];
}
