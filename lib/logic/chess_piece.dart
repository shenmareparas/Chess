import '../model/player.dart';

enum ChessPieceType { pawn, rook, knight, bishop, king, queen, promotion }

class ChessPiece {
  int id;
  ChessPieceType type;
  Player player;
  int moveCount = 0;
  int tile;

  ChessPiece(this.id, this.type, this.player, this.tile);
}
