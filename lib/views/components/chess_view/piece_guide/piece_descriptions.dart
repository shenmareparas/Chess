import '../../../../logic/chess_piece.dart';

class PieceInfo {
  final ChessPieceType type;
  final String name;
  final String title;
  final String summary;
  final String valueText;
  final String movePattern;
  final String details;
  final String? specialRuleTitle;
  final String? specialRule;

  const PieceInfo({
    required this.type,
    required this.name,
    required this.title,
    required this.summary,
    required this.valueText,
    required this.movePattern,
    required this.details,
    this.specialRuleTitle,
    this.specialRule,
  });
}

const List<ChessPieceType> pieceGuideOrder = [
  ChessPieceType.pawn,
  ChessPieceType.rook,
  ChessPieceType.king,
  ChessPieceType.queen,
  ChessPieceType.bishop,
  ChessPieceType.knight,
];

const Map<ChessPieceType, PieceInfo> pieceDescriptions = {
  ChessPieceType.pawn: PieceInfo(
    type: ChessPieceType.pawn,
    name: 'Pawn',
    title: 'How to Move the Pawn',
    summary:
        'The foot soldier of chess: advances forward, captures diagonally, and can promote upon reaching the end.',
    valueText: '1 Point',
    movePattern: '1 square forward (or 2 on its initial move)',
    details:
        'Pawns only move directly forward, but uniquely capture one square diagonally. Unlike other pieces, they cannot retreat backwards.',
    specialRuleTitle: 'Promotion & En Passant',
    specialRule:
        'Promotion: Reaching the opposite end transforms the pawn into a Queen, Rook, Bishop, or Knight.\n'
        'En Passant: If an opposing pawn advances two squares adjacent to yours, you can capture it diagonally on your very next turn as if it moved only one square.',
  ),
  ChessPieceType.rook: PieceInfo(
    type: ChessPieceType.rook,
    name: 'Rook',
    title: 'How to Move the Rook',
    summary:
        'A long-range powerhouse that controls open ranks and files across the entire board.',
    valueText: '5 Points',
    movePattern: 'Any distance along ranks (rows) and files (columns)',
    details:
        'The rook moves in straight horizontal and vertical lines for any number of unoccupied squares. It cannot jump over any piece.',
    specialRuleTitle: 'Castling',
    specialRule:
        'If neither your King nor Rook has moved yet and the pathway between them is clear and safe, they can execute a special simultaneous defensive maneuver.',
  ),
  ChessPieceType.king: PieceInfo(
    type: ChessPieceType.king,
    name: 'King',
    title: 'How to Move the King',
    summary:
        'The ultimate target: protect your King at all costs, as its capture (Checkmate) ends the game.',
    valueText: 'Priceless',
    movePattern: '1 square in any direction (up, down, sides, diagonal)',
    details:
        'The king is the most vital piece on the board. A king may never move into an attacked square (check). When placed in check, you must move him to safety, block the threat, or capture the attacker.',
    specialRuleTitle: 'Castling',
    specialRule:
        'Can make a synchronized double-move with an unmoved rook to tuck the king into safety behind friendly pawns.',
  ),
  ChessPieceType.queen: PieceInfo(
    type: ChessPieceType.queen,
    name: 'Queen',
    title: 'How to Move the Queen',
    summary:
        'The most dominant attacking piece: combines the unrestricted power of both the Rook and Bishop.',
    valueText: '9 Points',
    movePattern:
        'Any distance in straight lines horizontally, vertically, or diagonally',
    details:
        'The queen can travel in any direction as far as unoccupied squares allow. She is irreplaceable for tactics, fork attacks, and delivering checkmates.',
    specialRuleTitle: null,
    specialRule: null,
  ),
  ChessPieceType.bishop: PieceInfo(
    type: ChessPieceType.bishop,
    name: 'Bishop',
    title: 'How to Move the Bishop',
    summary:
        'The diagonal sniper: glides across diagonals and permanently controls one square color.',
    valueText: '3 Points',
    movePattern: 'Any distance diagonally',
    details:
        'Because bishops move strictly along diagonals, a bishop stays on squares of its starting color for the entire match. One controls light squares, the other dark squares.',
    specialRuleTitle: null,
    specialRule: null,
  ),
  ChessPieceType.knight: PieceInfo(
    type: ChessPieceType.knight,
    name: 'Knight',
    title: 'How to Move the Knight',
    summary:
        'The tricky jumper: moves in an eccentric "L-shape" and leaps over any intervening pieces.',
    valueText: '3 Points',
    movePattern:
        '"L-Shape": 2 squares in one direction + 1 square perpendicular',
    details:
        'The knight always lands on a square of the opposite color from where it began. Its unusual movement makes it lethal in closed board positions with crowded pawns.',
    specialRuleTitle: 'Leaping Ability',
    specialRule:
        'The only piece on the board capable of jumping directly over friendly or enemy pieces without being blocked.',
  ),
};
