import 'package:flutter/cupertino.dart';

import '../../../../../model/app_model.dart';
import 'rounded_icon_button.dart';

class UndoRedoButtons extends StatelessWidget {
  final AppModel appModel;

  bool get undoEnabled {
    if (appModel.playingWithAI) {
      return (appModel.game?.board.moveStack.length ?? 0) > 1 &&
          !appModel.isAIsTurn;
    } else {
      return appModel.game?.board.moveStack.isNotEmpty ?? false;
    }
  }

  bool get redoEnabled {
    if (appModel.playingWithAI) {
      return (appModel.game?.board.redoStack.length ?? 0) > 1 &&
          !appModel.isAIsTurn;
    } else {
      return appModel.game?.board.redoStack.isNotEmpty ?? false;
    }
  }

  UndoRedoButtons(this.appModel);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RoundedIconButton(
            CupertinoIcons.arrow_counterclockwise,
            onPressed: undoEnabled ? () => undo() : null,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: RoundedIconButton(
            CupertinoIcons.arrow_clockwise,
            onPressed: redoEnabled ? () => redo() : null,
          ),
        ),
      ],
    );
  }

  void undo() {
    if (appModel.playingWithAI) {
      appModel.game?.undoTwoMoves();
    } else {
      appModel.game?.undoMove();
    }
  }

  void redo() {
    if (appModel.playingWithAI) {
      appModel.game?.redoTwoMoves();
    } else {
      appModel.game?.redoMove();
    }
  }
}
