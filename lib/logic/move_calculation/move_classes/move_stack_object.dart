import '../../chess_piece.dart';
import 'move.dart';

class MoveStackObject {
  Move move;
  ChessPiece? movedPiece;
  ChessPiece? takenPiece;
  ChessPiece? enPassantPiece;
  bool castled = false;
  bool promotion = false;
  ChessPieceType? promotionType;
  bool enPassant = false;
  List<List<Move>>? possibleOpenings;
  int previousHash = 0;
  int previousBoardValue = 0;
  bool previousInEndGame = false;

  MoveStackObject(this.move, this.movedPiece, this.takenPiece,
      this.enPassantPiece, this.possibleOpenings);
}
