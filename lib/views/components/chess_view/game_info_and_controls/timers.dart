import 'package:flutter/material.dart';

import '../../../../model/app_model.dart';
import '../../../../model/player.dart';
import 'timer_widget.dart';

class Timers extends StatelessWidget {
  final AppModel appModel;

  Timers(this.appModel);

  @override
  Widget build(BuildContext context) {
    if (appModel.timeLimit == 0) return const SizedBox.shrink();

    final theme = appModel.theme;
    final turn = appModel.turn;

    // Check active states
    final isP1Active = turn == Player.player1;
    final isP2Active = turn == Player.player2;

    // Label logic (P1 is White, P2 is Black)
    final p1Label = appModel.playingWithAI
        ? (appModel.playerSide == Player.player1 ? 'YOU' : 'AI')
        : 'WHITE';
    final p2Label = appModel.playingWithAI
        ? (appModel.playerSide == Player.player2 ? 'YOU' : 'AI')
        : 'BLACK';

    return Column(
      children: [
        Row(
          children: [
            TimerWidget(
              timeLeft: appModel.player1TimeLeft,
              isActive: isP1Active,
              label: p1Label,
              theme: theme,
            ),
            const SizedBox(width: 12),
            TimerWidget(
              timeLeft: appModel.player2TimeLeft,
              isActive: isP2Active,
              label: p2Label,
              theme: theme,
            ),
          ],
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}
