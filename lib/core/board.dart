import 'piece.dart';
import 'square.dart';

enum TileKind { empty, food, rock, exit }

/// What sits on one square of the board (the snake is stored separately).
class Tile {
  const Tile._(this.kind, this.piece);

  const Tile.food(PieceType piece) : this._(TileKind.food, piece);

  static const empty = Tile._(TileKind.empty, null);
  static const rock = Tile._(TileKind.rock, null);
  static const exit = Tile._(TileKind.exit, null);

  final TileKind kind;

  /// The food piece, only set when [kind] is [TileKind.food].
  final PieceType? piece;

  bool get isFood => kind == TileKind.food;
  bool get isRock => kind == TileKind.rock;
  bool get isExit => kind == TileKind.exit;

  /// Level-file character for this tile.
  String get char => switch (kind) {
    TileKind.empty => '.',
    TileKind.rock => '#',
    TileKind.exit => 'E',
    TileKind.food => piece!.letter,
  };

  static Tile fromChar(String c) => switch (c) {
    '.' => empty,
    '#' => rock,
    'E' => exit,
    _ => Tile.food(PieceType.fromLetter(c)),
  };

  @override
  bool operator ==(Object other) =>
      other is Tile && other.kind == kind && other.piece == piece;

  @override
  int get hashCode => Object.hash(kind, piece);

  @override
  String toString() => char;
}

/// Immutable 8×8 grid of tiles.
class Board {
  Board._(this._tiles);

  /// A board with every square empty.
  factory Board.empty() => Board._(List<Tile>.filled(64, Tile.empty));

  /// Parses 8 rows of 8 characters; the first row is rank 8.
  factory Board.fromRows(List<String> rows) {
    if (rows.length != 8) {
      throw FormatException('Board needs 8 rows, got ${rows.length}');
    }
    final tiles = List<Tile>.filled(64, Tile.empty);
    for (var i = 0; i < 8; i++) {
      final row = rows[i];
      if (row.length != 8) {
        throw FormatException('Row ${i + 1} needs 8 chars', row);
      }
      final rank = 7 - i;
      for (var f = 0; f < 8; f++) {
        tiles[rank * 8 + f] = Tile.fromChar(row[f]);
      }
    }
    return Board._(tiles);
  }

  final List<Tile> _tiles;

  Tile operator [](Square s) => _tiles[s.index];

  /// Returns a copy with [s] set to [tile].
  Board withTile(Square s, Tile tile) {
    final copy = List<Tile>.of(_tiles);
    copy[s.index] = tile;
    return Board._(copy);
  }

  /// Squares holding food.
  Iterable<Square> get foodSquares =>
      Square.all.where((s) => _tiles[s.index].isFood);

  int get foodCount => _tiles.where((t) => t.isFood).length;

  /// The exit square, if any.
  Square? get exitSquare {
    for (final s in Square.all) {
      if (_tiles[s.index].isExit) return s;
    }
    return null;
  }

  /// 8 rows, rank 8 first (level-file format).
  List<String> toRows() => [
    for (var rank = 7; rank >= 0; rank--)
      [for (var f = 0; f < 8; f++) _tiles[rank * 8 + f].char].join(),
  ];

  /// Compact key for hashing/search.
  String get key => _tiles.map((t) => t.char).join();

  @override
  bool operator ==(Object other) => other is Board && other.key == key;

  @override
  int get hashCode => key.hashCode;
}
