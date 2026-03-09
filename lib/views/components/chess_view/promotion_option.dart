import 'package:en_passant/logic/chess_piece.dart';
import 'package:en_passant/logic/shared_functions.dart';
import 'package:en_passant/model/app_model.dart';
import 'package:en_passant/model/player.dart';
import 'package:flutter/material.dart';

class PromotionOption extends StatelessWidget {
  final AppModel appModel;
  final ChessPieceType promotionType;

  PromotionOption(this.appModel, this.promotionType);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        appModel.game?.promote(promotionType);
        appModel.update();
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Center(
          child: Image(
            height: 40,
            image: AssetImage(
              'assets/images/pieces/${formatPieceTheme(appModel.pieceTheme)}' +
                  '/${pieceTypeToString(promotionType)}_${_playerColor()}.png',
            ),
          ),
        ),
      ),
    );
  }

  String _playerColor() {
    return appModel.turn == Player.player1 ? 'white' : 'black';
  }
}
