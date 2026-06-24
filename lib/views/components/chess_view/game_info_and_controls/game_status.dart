import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../../model/app_model.dart';
import '../../../../model/player.dart';

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
      builder: (context, state, child) {
        final appModel = Provider.of<AppModel>(context, listen: false);
        final theme = appModel.theme;
        final statusText = _getStatus(state).toUpperCase();

        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x28201F1F),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0x14F5F5F0),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.lightTile.withValues(alpha: 0.08),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PulseDot(color: theme.lightTile),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.lightTile,
                    letterSpacing: 1.5,
                  ),
                ),
                if (!state.gameOver &&
                    state.playerCount == 1 &&
                    state.isAIsTurn) ...[
                  const SizedBox(width: 8),
                  CupertinoActivityIndicator(
                    radius: 8,
                    color: theme.lightTile,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _getStatus(_StatusState s) {
    if (!s.gameOver) {
      if (s.playerCount == 1) {
        if (s.isAIsTurn) {
          return 'AI is thinking';
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

class _PulseDot extends StatefulWidget {
  final Color color;

  const _PulseDot({required this.color});

  @override
  _PulseDotState createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Opacity(
        opacity: _animation.value,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.5),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
