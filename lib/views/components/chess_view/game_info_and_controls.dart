import 'package:cupertino_ui/cupertino_ui.dart';

import '../../../model/app_model.dart';
import 'game_info_and_controls/moves_undo_redo_row.dart';
import 'game_info_and_controls/restart_exit_buttons.dart';
import 'game_info_and_controls/timers.dart';

class GameInfoAndControls extends StatefulWidget {
  final AppModel appModel;

  GameInfoAndControls(this.appModel);

  @override
  _GameInfoAndControlsState createState() => _GameInfoAndControlsState();
}

class _GameInfoAndControlsState extends State<GameInfoAndControls> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(GameInfoAndControls oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final hasTimer = widget.appModel.timeLimit != 0;
    final extraHeight = hasTimer ? 74 : 0;
    final screenHeight = MediaQuery.of(context).size.height;

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
          Timers(widget.appModel),
          MovesUndoRedoRow(widget.appModel),
          RestartExitButtons(widget.appModel),
        ],
      ),
    );
  }
}
