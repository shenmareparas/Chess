import '../model/player.dart';

enum ChessPieceType { pawn, rook, knight, bishop, king, queen, promotion }

// Const lookup tables for piece values indexed by ChessPieceType.index.
// Avoids repeated switch-case evaluation inside the hot search loop.
const _kMaterialValues = <int>[
  100, // pawn   (index 0)
  500, // rook   (index 1)
  320, // knight (index 2)
  330, // bishop (index 3)
  20000, // king   (index 4)
  900, // queen  (index 5)
  0, // promotion placeholder (index 6)
];

class ChessPiece {
  int id;
  ChessPieceType type;
  Player player;
  int moveCount = 0;
  int tile;

  /// Signed piece value (+ve for player1, -ve for player2).
  /// Used in the incremental board evaluation.
  int get value {
    final raw = _kMaterialValues[type.index];
    return (player == Player.player1) ? raw : -raw;
  }

  /// Unsigned material value, used for MVV-LVA capture ordering.
  int get materialValue => _kMaterialValues[type.index];

  ChessPiece(this.id, this.type, this.player, this.tile);
}
