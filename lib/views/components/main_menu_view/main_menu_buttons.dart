import 'package:en_passant/logic/game_state_storage.dart';
import 'package:en_passant/model/app_model.dart';
import 'package:en_passant/views/components/shared/rounded_button.dart';
import 'package:flutter/cupertino.dart';
import '../../chess_view.dart';
import '../../settings_view.dart';

class MainMenuButtons extends StatefulWidget {
  final AppModel appModel;

  MainMenuButtons(this.appModel);

  @override
  _MainMenuButtonsState createState() => _MainMenuButtonsState();
}

class _MainMenuButtonsState extends State<MainMenuButtons> {
  bool _hasSavedGame = false;

  @override
  void initState() {
    super.initState();
    _checkSavedGame();
  }

  void _checkSavedGame() async {
    final hasSaved = await GameStateStorage.hasSavedGame();
    if (mounted) {
      setState(() {
        _hasSavedGame = hasSaved;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(
        children: [
          if (_hasSavedGame) ...[
            RoundedButton(
              'Resume Game',
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) {
                      widget.appModel.restoreGameState(context);
                      return ChessView(widget.appModel);
                    },
                  ),
                ).then((_) => _checkSavedGame());
              },
            ),
            SizedBox(height: 10),
          ],
          RoundedButton(
            'Start',
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) {
                    widget.appModel.newGame(context, notify: false);
                    return ChessView(widget.appModel);
                  },
                ),
              ).then((_) => _checkSavedGame());
            },
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: RoundedButton(
                  'Settings',
                  onPressed: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => SettingsView(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
