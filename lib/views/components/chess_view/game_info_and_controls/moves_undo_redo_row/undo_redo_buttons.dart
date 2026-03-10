import 'package:flutter/cupertino.dart';

import '../../../../../model/app_model.dart';
import 'rounded_icon_button.dart';

class UndoRedoButtons extends StatelessWidget {
  final AppModel appModel;

  bool get undoEnabled {
    return appModel.gameController != null &&
        appModel.gameController!.board.moveStack.isNotEmpty &&
        (!appModel.playingWithAI ||
            appModel.gameController!.board.moveStack.length > 1);
  }

  bool get redoEnabled {
    return appModel.gameController != null &&
        appModel.gameController!.board.redoStack.isNotEmpty &&
        (!appModel.playingWithAI ||
            appModel.gameController!.board.redoStack.length > 1);
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
    if (appModel.gameController != null) {
      if (appModel.playingWithAI) {
        appModel.gameController!.undoTwoMoves();
      } else {
        appModel.gameController!.undoMove();
      }
    }
  }

  void redo() {
    if (appModel.gameController != null) {
      if (appModel.playingWithAI) {
        appModel.gameController!.redoTwoMoves();
      } else {
        appModel.gameController!.redoMove();
      }
    }
  }
}
