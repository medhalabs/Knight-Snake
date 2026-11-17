/// A square on the 8×8 board. File 0–7 = a–h, rank 0–7 = 1–8.
class Square {
  const Square(this.file, this.rank)
    : assert(file >= 0 && file < 8),
      assert(rank >= 0 && rank < 8);

  /// Creates a square from its 0–63 index (`rank * 8 + file`).
  factory Square.fromIndex(int index) {
    if (index < 0 || index > 63) {
      throw RangeError.range(index, 0, 63, 'index');
    }
    return Square(index % 8, index ~/ 8);
  }

  /// Parses chess notation like `a1` or `h8`.
  factory Square.parse(String name) {
    final s = name.trim().toLowerCase();
    if (s.length != 2) throw FormatException('Bad square', name);
    final file = s.codeUnitAt(0) - 0x61; // 'a'
    final rank = s.codeUnitAt(1) - 0x31; // '1'
    if (file < 0 || file > 7 || rank < 0 || rank > 7) {
      throw FormatException('Bad square', name);
    }
    return Square(file, rank);
  }

  final int file;
  final int rank;

  int get index => rank * 8 + file;

  /// Chess name, e.g. `e4`.
  String get name =>
      '${String.fromCharCode(0x61 + file)}${String.fromCharCode(0x31 + rank)}';

  /// Whether a square offset by ([df], [dr]) is on the board.
  static bool onBoard(int file, int rank) =>
      file >= 0 && file < 8 && rank >= 0 && rank < 8;

  /// The square offset by ([df], [dr]), or null if off the board.
  Square? offset(int df, int dr) {
    final f = file + df;
    final r = rank + dr;
    return onBoard(f, r) ? Square(f, r) : null;
  }

  /// All 64 squares, a1..h1, a2..h2, …
  static final List<Square> all = List.unmodifiable(
    List<Square>.generate(64, Square.fromIndex),
  );

  @override
  bool operator ==(Object other) =>
      other is Square && other.file == file && other.rank == rank;

  @override
  int get hashCode => index;

  @override
  String toString() => name;
}
