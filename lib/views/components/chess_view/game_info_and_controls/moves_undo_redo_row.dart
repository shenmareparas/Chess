import 'package:flutter/cupertino.dart';

import '../../../../model/app_model.dart';
import 'moves_undo_redo_row/move_list.dart';
import 'moves_undo_redo_row/rounded_icon_button.dart';
import 'moves_undo_redo_row/undo_redo_buttons.dart';

class MovesUndoRedoRow extends StatelessWidget {
  final AppModel appModel;

  MovesUndoRedoRow(this.appModel);

  @override
  Widget build(BuildContext context) {
    final showResumeButton = appModel.historyViewIndex != null;
    final showUndoRedo = appModel.allowUndoRedo && !showResumeButton;

    return ExcludeSemantics(
      child: Column(
        children: [
          Row(
            children: [
              appModel.showMoveHistory
                  ? Expanded(child: MoveList(appModel))
                  : Container(),
              if (appModel.showMoveHistory &&
                  (showUndoRedo || showResumeButton))
                const SizedBox(width: 10),
              if (showResumeButton)
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: RoundedIconButton(
                          CupertinoIcons.chevron_left,
                          onPressed: (appModel.historyViewIndex != null &&
                                  appModel.historyViewIndex! > 0)
                              ? () {
                                  appModel.haptic.light();
                                  final int currentTurnIndex =
                                      (appModel.historyViewIndex! / 2).floor();
                                  if (appModel.historyViewIndex == 1) {
                                    appModel.selectHistoryTurn(0);
                                  } else if (currentTurnIndex > 0) {
                                    appModel.selectHistoryTurn(
                                        currentTurnIndex - 1);
                                  } else {
                                    appModel.setHistoryViewIndex(0,
                                        snap: true, playAudio: false);
                                  }
                                }
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: RoundedIconButton(
                          CupertinoIcons.chevron_right,
                          onPressed: () {
                            appModel.haptic.light();
                            final int currentTurnIndex =
                                appModel.historyViewIndex! < 0
                                    ? -1
                                    : (appModel.historyViewIndex! / 2).floor();
                            final int totalTurns =
                                (appModel.moveMetaList.length / 2).ceil();
                            if (currentTurnIndex < totalTurns - 1) {
                              appModel.selectHistoryTurn(currentTurnIndex + 1);
                            } else {
                              appModel.setHistoryViewIndex(null);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                )
              else if (appModel.allowUndoRedo)
                Expanded(child: UndoRedoButtons(appModel))
              else
                Container(),
            ],
          ),
          appModel.showMoveHistory || appModel.allowUndoRedo || showResumeButton
              ? SizedBox(height: 10)
              : Container(),
        ],
      ),
    );
  }
}
