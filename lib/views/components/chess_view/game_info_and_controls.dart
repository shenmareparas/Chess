import 'package:cupertino_ui/cupertino_ui.dart';

import '../../../model/app_model.dart';
import 'game_info_and_controls/moves_undo_redo_row.dart';
import 'game_info_and_controls/restart_exit_buttons.dart';
import 'game_info_and_controls/timers.dart';

class GameInfoAndControls extends StatelessWidget {
  final AppModel appModel;

  const GameInfoAndControls(this.appModel);

  @override
  Widget build(BuildContext context) {
    final hasTimer = appModel.timeLimit != 0;
    final extraHeight = hasTimer ? 74 : 0;
    final screenHeight = MediaQuery.sizeOf(context).height;

    // Adaptively scale max height based on available screen height so controls fit cleanly without truncation
    final double maxAllowedHeight = screenHeight > 800
        ? (204 + extraHeight).toDouble()
        : (screenHeight * 0.35 + extraHeight * 0.5).clamp(140.0, 280.0);

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxAllowedHeight,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Timers(appModel),
          MovesUndoRedoRow(appModel),
          RestartExitButtons(appModel),
        ],
      ),
    );
  }
}
