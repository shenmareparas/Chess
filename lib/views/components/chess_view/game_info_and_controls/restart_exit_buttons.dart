import 'package:flutter/cupertino.dart';

import '../../../../model/app_model.dart';
import '../../../chess_view.dart';
import '../../shared/rounded_button.dart';
import 'rounded_alert_button.dart';

class RestartExitButtons extends StatelessWidget {
  final AppModel appModel;

  RestartExitButtons(this.appModel);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RoundedAlertButton(
            'Restart',
            onConfirm: () {
              appModel.newGame();
            },
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: appModel.gameOver
              ? RoundedButton(
                  'Exit',
                  onPressed: () {
                    appModel.exitChessView();
                    Navigator.pop(context);
                  },
                )
              : RoundedButton(
                  'Exit',
                  onPressed: () {
                    showExitDialog(context);
                  },
                ),
        ),
      ],
    );
  }
}
