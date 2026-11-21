import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:provider/provider.dart';

import '../../../../model/app_model.dart';
import 'moves_undo_redo_row/move_list.dart';
import 'moves_undo_redo_row/rounded_icon_button.dart';
import 'moves_undo_redo_row/undo_redo_buttons.dart';

class MovesUndoRedoRow extends StatelessWidget {
  final AppModel appModel;

  const MovesUndoRedoRow(this.appModel);

  @override
  Widget build(BuildContext context) {
    return Selector<AppModel, (int?, bool, bool)>(
      selector: (_, m) =>
          (m.historyViewIndex, m.allowUndoRedo, m.showMoveHistory),
      builder: (context, data, _) {
        final (historyViewIndex, allowUndoRedo, showMoveHistory) = data;
        final showResumeButton = historyViewIndex != null;
        final showUndoRedo = allowUndoRedo && !showResumeButton;

        return ExcludeSemantics(
          child: Column(
            children: [
              Row(
                children: [
                  showMoveHistory
                      ? Expanded(child: MoveList(appModel))
                      : const SizedBox.shrink(),
                  if (showMoveHistory && (showUndoRedo || showResumeButton))
                    const SizedBox(width: 10),
                  if (showResumeButton)
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: RoundedIconButton(
                              CupertinoIcons.chevron_left,
                              onPressed: (historyViewIndex > 0)
                                  ? appModel.stepHistoryBackward
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: RoundedIconButton(
                              CupertinoIcons.chevron_right,
                              onPressed: appModel.stepHistoryForward,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (allowUndoRedo)
                    Expanded(child: UndoRedoButtons(appModel))
                  else
                    const SizedBox.shrink(),
                ],
              ),
              showMoveHistory || allowUndoRedo || showResumeButton
                  ? const SizedBox(height: 10)
                  : const SizedBox.shrink(),
            ],
          ),
        );
      },
    );
  }
}
