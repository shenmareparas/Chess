import 'package:flutter/cupertino.dart';

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
  final ScrollController scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height > 700 ? 204 : 134,
      ),
      child: ListView(
        controller: scrollController,
        physics: ClampingScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: [
          Timers(widget.appModel),
          MovesUndoRedoRow(widget.appModel),
          RestartExitButtons(widget.appModel),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    }
  }
}
