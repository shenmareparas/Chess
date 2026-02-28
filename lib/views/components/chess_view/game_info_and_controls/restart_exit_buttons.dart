import 'package:en_passant/model/app_model.dart';
import 'package:en_passant/views/components/chess_view/game_info_and_controls/rounded_alert_button.dart';
import 'package:en_passant/views/chess_view.dart';
import 'package:en_passant/views/components/shared/rounded_button.dart';
import 'package:flutter/cupertino.dart';

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
              appModel.newGame(context);
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
