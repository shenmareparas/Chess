import 'package:en_passant/model/app_model.dart';
import 'package:en_passant/model/player.dart';
import 'package:en_passant/views/components/shared/text_variable.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// State tuple for GameStatus — only rebuilds when these fields change.
typedef _StatusState = ({
  bool gameOver,
  int playerCount,
  bool isAIsTurn,
  Player turn,
  bool stalemate,
  int aiDifficulty,
});

class GameStatus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Selector<AppModel, _StatusState>(
      selector: (_, m) => (
        gameOver: m.gameOver,
        playerCount: m.playerCount,
        isAIsTurn: m.isAIsTurn,
        turn: m.turn,
        stalemate: m.stalemate,
        aiDifficulty: m.aiDifficulty,
      ),
      builder: (context, state, child) => Row(
        children: [
          TextRegular(_getStatus(state)),
          !state.gameOver && state.playerCount == 1 && state.isAIsTurn
              ? CupertinoActivityIndicator(radius: 12)
              : Container()
        ],
        mainAxisAlignment: MainAxisAlignment.center,
      ),
    );
  }

  String _getStatus(_StatusState s) {
    if (!s.gameOver) {
      if (s.playerCount == 1) {
        if (s.isAIsTurn) {
          return 'AI [Level ${s.aiDifficulty}] is thinking ';
        } else {
          return 'Your turn';
        }
      } else {
        if (s.turn == Player.player1) {
          return 'White\'s turn';
        } else {
          return 'Black\'s turn';
        }
      }
    } else {
      if (s.stalemate) {
        return 'Stalemate';
      } else {
        if (s.playerCount == 1) {
          if (s.isAIsTurn) {
            return 'You Win!';
          } else {
            return 'You Lose :(';
          }
        } else {
          if (s.turn == Player.player1) {
            return 'Black wins!';
          } else {
            return 'White wins!';
          }
        }
      }
    }
  }
}
