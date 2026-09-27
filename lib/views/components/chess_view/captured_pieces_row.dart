import 'package:material_ui/material_ui.dart';

import '../../../logic/chess_piece.dart';
import '../../../logic/shared_functions.dart';
import '../../../model/app_model.dart';
import '../../../model/app_themes.dart';
import '../../../model/player.dart';

/// Displays the pieces captured from [player]'s side as small icons.
class CapturedPiecesRow extends StatelessWidget {
  final AppModel appModel;
  final Player player;
  final String pieceTheme;
  final AppTheme theme;
  final bool flipped;

  const CapturedPiecesRow({
    required this.appModel,
    required this.player,
    required this.pieceTheme,
    required this.theme,
    this.flipped = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final captured = appModel.capturedPiecesFor(player);
    if (captured.isEmpty) {
      return const SizedBox(height: 34);
    }

    // Group captured pieces by piece type preserving the canonical order
    final Map<ChessPieceType, int> counts = {};
    for (final type in captured) {
      counts[type] = (counts[type] ?? 0) + 1;
    }

    final entries = counts.entries.toList();
    final displayedEntries = flipped ? entries.reversed.toList() : entries;

    // Use a frosted glass backdrop with theme tile tint so black and white pieces both pop
    final isBlack = player == Player.player2;
    final pillBg = isBlack
        ? Color.alphaBlend(
            theme.lightTile.withValues(alpha: 0.16),
            const Color(0xB81A1D20),
          )
        : Color.alphaBlend(
            theme.darkTile.withValues(alpha: 0.22),
            const Color(0xB8141416),
          );

    return SizedBox(
      height: 34,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: isBlack
                  ? theme.lightTile.withValues(alpha: 0.35)
                  : theme.lightTile.withValues(alpha: 0.20),
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: displayedEntries
                  .map((entry) => _PieceGroupTombstone(
                        pieceType: entry.key,
                        count: entry.value,
                        player: player,
                        pieceTheme: pieceTheme,
                        theme: theme,
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _PieceGroupTombstone extends StatelessWidget {
  final ChessPieceType pieceType;
  final int count;
  final Player player;
  final String pieceTheme;
  final AppTheme theme;

  const _PieceGroupTombstone({
    required this.pieceType,
    required this.count,
    required this.player,
    required this.pieceTheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isWhite = player == Player.player1;
    final color = isWhite ? 'white' : 'black';
    final name = pieceTypeToString(pieceType);
    final imagePath =
        'assets/images/pieces/${formatPieceTheme(pieceTheme)}/${name}_$color.png';

    // Black pieces receive a subtle soft ambient glow so their dark silhouettes
    // are crisp and unmistakably distinct against any dark theme background.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: isWhite
                ? null
                : BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.lightTile.withValues(alpha: 0.28),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
            child: Image.asset(
              imagePath,
              width: 24,
              height: 24,
              errorBuilder: (_, __, ___) =>
                  const SizedBox(width: 24, height: 24),
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isWhite
                  ? theme.lightTile
                  : theme.lightTile.withValues(alpha: 0.9),
              shadows: const [
                Shadow(
                  color: Color(0x99000000),
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
