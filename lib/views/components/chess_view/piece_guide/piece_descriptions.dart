import '../../../../logic/chess_piece.dart';

class PieceInfo {
  final ChessPieceType type;
  final String name;
  final String role;
  final String title;
  final String summary;
  final String valueText;
  final String movePattern;
  final String details;
  final String combatTip;
  final String? specialRuleTitle;
  final String? specialRule;

  const PieceInfo({
    required this.type,
    required this.name,
    required this.role,
    required this.title,
    required this.summary,
    required this.valueText,
    required this.movePattern,
    required this.details,
    required this.combatTip,
    this.specialRuleTitle,
    this.specialRule,
  });
}

const List<ChessPieceType> pieceGuideOrder = [
  ChessPieceType.pawn,
  ChessPieceType.knight,
  ChessPieceType.bishop,
  ChessPieceType.rook,
  ChessPieceType.queen,
  ChessPieceType.king,
];

const Map<ChessPieceType, PieceInfo> pieceDescriptions = {
  ChessPieceType.pawn: PieceInfo(
    type: ChessPieceType.pawn,
    name: 'Pawn',
    role: 'Frontline Infantry',
    title: 'How to Move the Pawn',
    summary:
        'The foundation of chess strategy: anchors board control, marches forward, and holds the game-changing potential of promotion.',
    valueText: '1 Point',
    movePattern:
        '1 square straight forward (optionally 2 squares from original rank)',
    details:
        'Pawns march strictly forward into open squares, but capture one square diagonally ahead. A pawn cannot move backward, make diagonal moves without capturing, or jump over pieces.',
    combatTip:
        'Create interlocking pawn chains (where pawns defend each other diagonally) to claim the center and shield your king.',
    specialRuleTitle: 'Promotion & En Passant',
    specialRule:
        '• Promotion: Reaching the enemy\'s 8th rank immediately transforms the pawn into a Queen, Rook, Bishop, or Knight of your choice.\n'
        '• En Passant: When an enemy pawn leaps two squares forward adjacent to yours, you may capture it diagonally behind as if it had only moved one square (must be played immediately on that turn).',
  ),
  ChessPieceType.knight: PieceInfo(
    type: ChessPieceType.knight,
    name: 'Knight',
    role: 'Tactical Cavalry',
    title: 'How to Move the Knight',
    summary:
        'The agile trickster of the board: executes sudden L-shaped leaps and bypasses all intervening obstacles.',
    valueText: '3 Points',
    movePattern:
        '"L-Shape": 2 squares along a rank/file + 1 square at 90 degrees',
    details:
        'The knight is uniquely untethered by blocked pathways: it leaps directly to its destination square, capturing whatever enemy occupies it. Every move alternates square color (light to dark, dark to light).',
    combatTip:
        'Place knights in central outpost squares where pawns cannot chase them away. Their leaping geometry makes them masters of royal forks.',
    specialRuleTitle: 'Unblockable Leap',
    specialRule:
        'The knight is the only piece in chess that can jump over other pieces (both friendly and opponent) regardless of board congestion.',
  ),
  ChessPieceType.bishop: PieceInfo(
    type: ChessPieceType.bishop,
    name: 'Bishop',
    role: 'Long-Range Sniper',
    title: 'How to Move the Bishop',
    summary:
        'The open-board specialist: sweeps across long diagonals with devastating speed and precision.',
    valueText: '3 Points',
    movePattern:
        'Any number of unoccupied squares diagonally in all 4 directions',
    details:
        'Each player commands two bishops: one bound to light squares and one to dark squares. A bishop cannot change colors throughout the game or jump over blocking pieces.',
    combatTip:
        'Bishops thrive on open diagonals without pawn blockades. Possessing the "Bishop Pair" in an open endgame yields a tremendous positional advantage.',
    specialRuleTitle: 'Color Binding',
    specialRule:
        'Because diagonal steps always preserve parity, each bishop stays permanently dedicated to the square color it began on for the entire game.',
  ),
  ChessPieceType.rook: PieceInfo(
    type: ChessPieceType.rook,
    name: 'Rook',
    role: 'Heavy Siege Artillery',
    title: 'How to Move the Rook',
    summary:
        'A devastating major piece: dominates open files and ranks to cut off enemy escape corridors.',
    valueText: '5 Points',
    movePattern: 'Any number of unoccupied squares horizontally or vertically',
    details:
        'The rook travels in straight, perpendicular lines. It cannot jump over other pieces. In conjunction with your king, it forms the bedrock of rook-and-king checkmating matrices.',
    combatTip:
        'Seize open or half-open files early. In the middle-to-late game, landing a rook on the opponent\'s 7th rank puts severe pressure on undefended pawns and the enemy king.',
    specialRuleTitle: 'Castling Maneuver',
    specialRule:
        'The rook collaborates with an unmoved king to execute Castling: the king jumps two squares towards the rook, and the rook hops over the king to an adjacent square.',
  ),
  ChessPieceType.queen: PieceInfo(
    type: ChessPieceType.queen,
    name: 'Queen',
    role: 'Supreme Commander',
    title: 'How to Move the Queen',
    summary:
        'The undisputed offensive heavyweight: merges the full movement range of both the Rook and Bishop.',
    valueText: '9 Points',
    movePattern:
        'Any distance in straight lines horizontally, vertically, or diagonally',
    details:
        'The queen is the most versatile attacking weapon in the game. She can project immense pressure across the entire board in a single move, but cannot leap over other pieces.',
    combatTip:
        'Avoid deploying your queen too early in the opening, where enemy minor pieces and pawns can harass her while developing with tempo.',
    specialRuleTitle: 'Tactical Versatility',
    specialRule:
        'With 8 directional attack vectors, the queen excels at simultaneous multi-target attacks (double attacks and forks) that force decisive material gains.',
  ),
  ChessPieceType.king: PieceInfo(
    type: ChessPieceType.king,
    name: 'King',
    role: 'Monarch & Heart of the Army',
    title: 'How to Move the King',
    summary:
        'The center of the game: must be shielded early on, but becomes a powerful active leader in endgames.',
    valueText: 'Priceless',
    movePattern:
        '1 square in any direction (horizontal, vertical, or diagonal)',
    details:
        'The king may never step into check (attacked square) or remain in check. When threatened, you must immediately escape by moving the king, blocking with another piece, or capturing the attacker.',
    combatTip:
        'Castle early to tuck your king into safety behind an intact pawn shield. When major pieces leave the board in the endgame, activate your king aggressively toward the center.',
    specialRuleTitle: 'Castling & Safety Rules',
    specialRule:
        '• Castling: If the king and rook have not moved, squares between them are empty, and the king does not pass through or land in check, you can castle kingside or queenside.\n'
        '• Checkmate: If the king is under direct attack with zero legal moves to resolve the threat, the game ends immediately in defeat.',
  ),
};
