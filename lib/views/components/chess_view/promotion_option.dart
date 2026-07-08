import 'package:flutter/material.dart';

import '../../../logic/chess_piece.dart';
import '../../../logic/shared_functions.dart';
import '../../../model/app_model.dart';
import '../../../model/player.dart';

class PromotionOption extends StatelessWidget {
  final AppModel appModel;
  final ChessPieceType promotionType;

  PromotionOption(this.appModel, this.promotionType);

  @override
  Widget build(BuildContext context) {
    final theme = appModel.theme;
    final pieceName = _getPieceName(promotionType);

    return InkWell(
      onTap: () {
        if (appModel.gameController != null) {
          appModel.gameController!.promote(promotionType);
        } else {
          debugPrint('Promotion selected: $promotionType (No active game)');
        }
        appModel.update();
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.lightTile.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Image(
                height: 44,
                width: 44,
                image: AssetImage(
                  'assets/images/pieces/${formatPieceTheme(appModel.pieceTheme)}' +
                      '/${pieceTypeToString(promotionType)}_${_playerColor()}.png',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pieceName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _playerColor() {
    return appModel.turn == Player.player1 ? 'white' : 'black';
  }

  String _getPieceName(ChessPieceType type) {
    switch (type) {
      case ChessPieceType.queen:
        return 'Queen';
      case ChessPieceType.rook:
        return 'Rook';
      case ChessPieceType.bishop:
        return 'Bishop';
      case ChessPieceType.knight:
        return 'Knight';
      default:
        return '';
    }
  }
}
