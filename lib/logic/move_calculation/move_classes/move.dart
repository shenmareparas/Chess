import '../../chess_piece.dart';

class Move {
  int from;
  int to;
  ChessPieceType promotionType;

  Move(this.from, this.to, {this.promotionType = ChessPieceType.promotion});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Move && from == other.from && to == other.to;
  @override
  int get hashCode => from * 64 + to;
}
