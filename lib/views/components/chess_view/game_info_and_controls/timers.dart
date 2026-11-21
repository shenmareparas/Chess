import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../../model/app_model.dart';
import '../../../../model/app_themes.dart';
import '../../../../model/player.dart';
import 'timer_widget.dart';

class Timers extends StatelessWidget {
  final AppModel appModel;

  Timers(this.appModel);

  @override
  Widget build(BuildContext context) {
    if (appModel.timeLimit == 0) return const SizedBox.shrink();

    return Selector<AppModel, (AppTheme, Player)>(
      selector: (_, m) => (m.theme, m.turn),
      builder: (_, data, __) {
        final (theme, turn) = data;

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
                  delayLeft: appModel.timerService.player1DelayLeft,
                  isActive: isP1Active,
                  label: p1Label,
                  theme: theme,
                ),
                const SizedBox(width: 12),
                TimerWidget(
                  timeLeft: appModel.player2TimeLeft,
                  delayLeft: appModel.timerService.player2DelayLeft,
                  isActive: isP2Active,
                  label: p2Label,
                  theme: theme,
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
        );
      },
    );
  }
}
