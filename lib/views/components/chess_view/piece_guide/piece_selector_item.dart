import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../logic/chess_piece.dart';
import '../../../../logic/shared_functions.dart';

class PieceSelectorItem extends StatelessWidget {
  final ChessPieceType type;
  final bool isSelected;
  final String pieceTheme;
  final String pieceColor; // 'white' or 'black'
  final Color activeRingColor;
  final Color? glowColor;
  final VoidCallback onTap;

  const PieceSelectorItem({
    super.key,
    required this.type,
    required this.isSelected,
    required this.pieceTheme,
    required this.pieceColor,
    required this.activeRingColor,
    this.glowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath =
        'assets/images/pieces/${formatPieceTheme(pieceTheme)}/${pieceTypeToString(type)}_$pieceColor.png';
    final isBlack = pieceColor == 'black';
    final pieceName = pieceTypeToString(type)[0].toUpperCase() +
        pieceTypeToString(type).substring(1);

    return Tooltip(
      message: pieceName,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        onPressed: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? activeRingColor.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.04),
            border: Border.all(
              color: isSelected
                  ? activeRingColor
                  : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeRingColor.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(7.0),
              child: Container(
                decoration: isBlack && glowColor != null
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: glowColor!.withValues(alpha: 0.35),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      )
                    : null,
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
