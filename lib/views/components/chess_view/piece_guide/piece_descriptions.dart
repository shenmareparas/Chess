import 'package:material_ui/material_ui.dart';

import '../../../../logic/chess_piece.dart';

class SpecialRuleItem {
  final String title;
  final String description;
  final IconData icon;

  const SpecialRuleItem({
    required this.title,
    required this.description,
    this.icon = Icons.stars_rounded,
  });
}

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
  final List<String> quickStats;
  final List<SpecialRuleItem> specialRules;

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
    this.quickStats = const [],
    this.specialRules = const [],
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
    role: 'Pawn',
    title: 'How to Play the Pawn',
    summary:
        'The foundation of chess strategy. Pawns control space, build defensive chains, and hold the game-winning power of promotion.',
    valueText: '1 Point',
    movePattern:
        'Moves 1 square forward (or 2 on its first move). Captures 1 square diagonally forward.',
    details:
        'Pawns advance strictly forward into empty squares, but can only capture diagonally ahead. They are the only pieces that can never move backward. On its very first move of the game, a pawn has the option to advance two squares instead of one.',
    combatTip:
        'Control central squares (e4, d4, e5, d5) early. Build diagonal pawn chains where each pawn protects the one ahead. In the endgame, push passed pawns to force a Queen promotion.',
    specialRuleTitle: 'Promotion & En Passant',
    specialRule:
        '• Promotion: Reaching the enemy\'s back rank (8th rank) immediately transforms the pawn into a Queen, Rook, Bishop, or Knight of your choice.\n'
        '• En Passant: If an opposing pawn advances two squares and lands directly beside yours, you can capture it diagonally behind on your very next turn as if it had only moved one square.',
    quickStats: ['1 Sq Forward', 'Diagonal Capture', 'Promotion at Rank 8'],
    specialRules: [
      SpecialRuleItem(
        title: 'Pawn Promotion',
        description:
            'Reaching the opposite 8th rank immediately transforms the pawn into a Queen, Rook, Bishop, or Knight of your choice.',
        icon: Icons.upgrade_rounded,
      ),
      SpecialRuleItem(
        title: 'En Passant',
        description:
            'If an enemy pawn advances two squares and lands directly beside yours, you can capture it diagonally behind on your very next turn.',
        icon: Icons.swap_calls_rounded,
      ),
    ],
  ),
  ChessPieceType.knight: PieceInfo(
    type: ChessPieceType.knight,
    name: 'Knight',
    role: 'Minor Piece',
    title: 'How to Play the Knight',
    summary:
        'The agile leaper of the board. Jumps directly over other pieces, thriving in crowded positions and delivering lethal forks.',
    valueText: '3 Points',
    movePattern:
        '"L-Shape": 2 squares in one direction, then 1 square perpendicular. Always lands on the opposite color.',
    details:
        'The knight is untethered by blocked pathways: it leaps directly to its destination square, ignoring any pieces in between. Because every move alternates square color (light to dark, dark to light), a knight requires multiple turns to reach squares of the same color.',
    combatTip:
        'Plant knights on central outposts (squares anchored by friendly pawns where enemy pawns cannot chase them away). Knights are masters of the "royal fork" — simultaneously attacking the enemy King and Queen or Rook.',
    specialRuleTitle: 'Leaping Ability',
    specialRule:
        'The knight is the only piece in chess that can jump over other pieces (both friendly and opponent). This unique ability lets knights develop on move 1 without moving any pawns first.',
    quickStats: ['L-Shape Leap', 'Jumps Over Pieces', 'Alternates Colors'],
    specialRules: [
      SpecialRuleItem(
        title: 'Unrestricted Leaping',
        description:
            'The only piece that can jump over other pieces (friendly and opponent), allowing it to enter the game on move 1 without moving pawns.',
        icon: Icons.sports_gymnastics_rounded,
      ),
      SpecialRuleItem(
        title: 'Royal Fork Geometry',
        description:
            'Its unique L-shape allows the knight to attack opposing pieces without placing itself in their line of fire, making it deadly for royal forks.',
        icon: Icons.call_split_rounded,
      ),
    ],
  ),
  ChessPieceType.bishop: PieceInfo(
    type: ChessPieceType.bishop,
    name: 'Bishop',
    role: 'Minor Piece',
    title: 'How to Play the Bishop',
    summary:
        'A long-range diagonal attacker. Dominates open boards and controls entire diagonals when unobstructed by pawns.',
    valueText: '3 Points',
    movePattern:
        'Any distance diagonally along unobstructed squares of its starting color.',
    details:
        'Each player begins with one light-squared bishop and one dark-squared bishop. A bishop remains bound to its starting square color for the entire game and cannot jump over blocking pieces. In open positions, bishops can strike across the entire board in a single move.',
    combatTip:
        'Keep diagonals clear by placing your pawns on the opposite color of your bishop. Possessing the "Bishop Pair" (both bishops against a knight and bishop) is a major positional advantage in open endgames.',
    specialRuleTitle: 'Color Binding & Fianchetto',
    specialRule:
        'Because a bishop can only visit 32 of the 64 squares, placing it on the board\'s longest diagonals (fianchetto on b2/g2 or b7/g7) maximizes its scope and puts pressure on the center and opposing corners.',
    quickStats: ['Diagonal Reach', 'Color-Bound (32 Sq)', 'Open Board Power'],
    specialRules: [
      SpecialRuleItem(
        title: 'Color Parity',
        description:
            'Each bishop is permanently confined to the 32 squares of its starting color (light or dark). Together, the Bishop Pair covers the entire board.',
        icon: Icons.palette_outlined,
      ),
      SpecialRuleItem(
        title: 'Fianchetto Setup',
        description:
            'Placing the bishop on the board\'s longest diagonals (b2/g2 or b7/g7) creates lethal cross-board pressure on the center and opposing rooks.',
        icon: Icons.radar_rounded,
      ),
    ],
  ),
  ChessPieceType.rook: PieceInfo(
    type: ChessPieceType.rook,
    name: 'Rook',
    role: 'Major Piece',
    title: 'How to Play the Rook',
    summary:
        'A heavy major piece. Controls open files and ranks, exerts massive pressure on the 7th rank, and partners with the King in castling.',
    valueText: '5 Points',
    movePattern:
        'Any distance horizontally or vertically along unobstructed ranks and files.',
    details:
        'Rooks move in straight perpendicular lines along ranks and files. They start tucked into the corners, requiring minor pieces and pawns to clear out before they activate. When two rooks double up on the same file, they form a powerful battery.',
    combatTip:
        'Seize open files (columns without pawns) as early as possible. In the middlegame and endgame, landing a rook on the opponent\'s 7th rank attacks defending pawns and traps the enemy king on the back rank.',
    specialRuleTitle: 'Castling Maneuver',
    specialRule:
        'The rook collaborates with an unmoved king to execute Castling: the king moves two squares toward the rook, and the rook hops directly over the king to the adjacent square, achieving king safety and rook activation in a single turn.',
    quickStats: ['Ranks & Files', 'Castling Partner', '7th Rank Invasions'],
    specialRules: [
      SpecialRuleItem(
        title: 'Castling Maneuver',
        description:
            'Coordinates with an unmoved king: king slides two squares towards the rook, and the rook hops directly over to the adjacent square in one turn.',
        icon: Icons.shield_rounded,
      ),
      SpecialRuleItem(
        title: 'Rook Battery',
        description:
            'Stacking both rooks on the same open file doubles their tactical firepower and controls the entire column.',
        icon: Icons.view_column_rounded,
      ),
    ],
  ),
  ChessPieceType.queen: PieceInfo(
    type: ChessPieceType.queen,
    name: 'Queen',
    role: 'Major Piece',
    title: 'How to Play the Queen',
    summary:
        'The most powerful piece on the board. Combines the full mobility of both Rook and Bishop to project decisive multi-target threats.',
    valueText: '9 Points',
    movePattern:
        'Any distance in all 8 directions: horizontally, vertically, or diagonally.',
    details:
        'The queen projects immense tactical force across the entire board in a single move. However, she cannot leap over other pieces. Because of her high value, exposing her too early often makes her a target for harassment by enemy minor pieces.',
    combatTip:
        'Resist bringing your queen out too early in the opening. Early queen sorties allow your opponent to develop pieces with "tempo" while attacking your queen. Deploy her when lines are open to deliver coordinated finishing attacks.',
    specialRuleTitle: 'Double Attacks & Pins',
    specialRule:
        'With 8 directional attack vectors, the queen is the ultimate weapon for forks, pins, and skewers. Coordinate queen attacks with a supporting minor piece or rook to safely breach the enemy defense.',
    quickStats: [
      'All 8 Directions',
      'Highest Mobility',
      'Double-Attack Threat',
    ],
    specialRules: [
      SpecialRuleItem(
        title: 'Double Attacks & Pins',
        description:
            'With 8 directional lines of attack, the queen is the ultimate weapon for simultaneous double attacks, pins, and skewers.',
        icon: Icons.bolt_rounded,
      ),
      SpecialRuleItem(
        title: 'Opening Patience',
        description:
            'Bringing the queen out on moves 2–4 allows opponents to develop minor pieces with tempo while chasing her. Deploy her when lines open up.',
        icon: Icons.warning_amber_rounded,
      ),
    ],
  ),
  ChessPieceType.king: PieceInfo(
    type: ChessPieceType.king,
    name: 'King',
    role: 'The Monarch',
    title: 'How to Play the King',
    summary:
        'The centerpiece of the game. Must be shielded safely early on, but transforms into an active, aggressive leader in the endgame.',
    valueText: 'Invaluable',
    movePattern:
        '1 square in any direction (horizontal, vertical, or diagonal).',
    details:
        'The king can never step into an attacked square (check) or remain in check. When threatened, you must immediately escape by moving the king, blocking with another piece, or capturing the attacker. If no legal move can remove the check, it is checkmate.',
    combatTip:
        'Castle early to tuck your king safely behind an intact pawn shield. When major pieces leave the board in the endgame, activate your king aggressively toward the center to control critical squares and escort pawns to promotion.',
    specialRuleTitle: 'Castling & Checkmate',
    specialRule:
        '• Castling: If the king and rook have not moved, intervening squares are empty, and the king does not move into, out of, or through check, you can castle kingside or queenside.\n'
        '• Checkmate: If the king is under direct attack with zero legal moves to resolve the threat, the game ends immediately in defeat.',
    quickStats: ['1 Sq Radius', 'Castling Right', 'Game Critical'],
    specialRules: [
      SpecialRuleItem(
        title: 'Castling Security',
        description:
            'Tucks the king into corner safety behind a pawn shield while activating a rook. Requires empty squares and no check threats along the path.',
        icon: Icons.shield_rounded,
      ),
      SpecialRuleItem(
        title: 'Check & Checkmate',
        description:
            'The king can never move into or remain in check. If attacked with zero legal moves to resolve the threat, the game ends in checkmate.',
        icon: Icons.crisis_alert_rounded,
      ),
    ],
  ),
};
