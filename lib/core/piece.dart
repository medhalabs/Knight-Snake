/// Chess piece types used as snake heads and as food.
enum PieceType {
  pawn('p', 10),
  knight('n', 30),
  bishop('b', 30),
  rook('r', 50),
  queen('q', 90),
  king('k', 60);

  const PieceType(this.letter, this.points);

  /// Board letter used in level files (`p n b r q k`).
  final String letter;

  /// Base points for eating this piece.
  final int points;

  /// Pawns are snacks: eating one keeps the current head type.
  bool get keepsHead => this == PieceType.pawn;

  /// Whether this type can be a snake head in v1.
  bool get canBeHead => this != PieceType.pawn;

  static PieceType fromLetter(String letter) {
    final l = letter.toLowerCase();
    for (final p in values) {
      if (p.letter == l) return p;
    }
    throw FormatException('Unknown piece letter', letter);
  }

  static PieceType fromName(String name) {
    for (final p in values) {
      if (p.name == name) return p;
    }
    throw FormatException('Unknown piece name', name);
  }
}
