import 'package:en_passant/model/app_model.dart';
import 'package:en_passant/views/components/chess_view/chess_board_widget.dart';
import 'package:en_passant/views/components/chess_view/game_info_and_controls.dart';
import 'package:en_passant/views/components/chess_view/promotion_dialog.dart';
import 'package:en_passant/views/components/shared/rounded_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'components/chess_view/game_info_and_controls/game_status.dart';
import 'components/shared/bottom_padding.dart';

class ChessView extends StatefulWidget {
  final AppModel appModel;

  ChessView(this.appModel);

  @override
  _ChessViewState createState() => _ChessViewState(appModel);
}

class _ChessViewState extends State<ChessView> with WidgetsBindingObserver {
  AppModel appModel;

  _ChessViewState(this.appModel);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (!appModel.gameOver) {
        appModel.saveGameState();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, appModel, child) {
        if (appModel.promotionRequested) {
          appModel.promotionRequested = false;
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _showPromotionDialog(appModel));
        }
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            if (appModel.gameOver) {
              appModel.exitChessView();
              Navigator.of(context).pop();
            } else {
              showExitDialog(context);
            }
          },
          child: Container(
            decoration: BoxDecoration(gradient: appModel.theme.background),
            padding: EdgeInsets.all(30),
            child: Column(
              children: [
                Spacer(),
                ChessBoardWidget(appModel),
                SizedBox(height: 30),
                GameStatus(),
                Spacer(),
                GameInfoAndControls(appModel),
                BottomPadding(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPromotionDialog(AppModel appModel) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return PromotionDialog(appModel);
      },
    );
  }
}

void showExitDialog(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    barrierDismissible: true,
    barrierLabel: '',
    transitionDuration: Duration(milliseconds: 250),
    pageBuilder: (dialogContext, anim1, anim2) {
      return Consumer<AppModel>(
        builder: (dialogContext, appModel, child) => Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(maxWidth: 340),
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: appModel.theme.background,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Leave Game?',
                    style: TextStyle(
                      fontSize: 32,
                      fontFamily: 'Jura',
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Would you like to save your progress?',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Jura',
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 35),
                  RoundedButton(
                    'Save & Exit',
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      appModel.saveAndExitChessView();
                      Navigator.of(context).pop();
                    },
                  ),
                  SizedBox(height: 15),
                  RoundedButton(
                    'Exit',
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      appModel.exitChessView();
                      Navigator.of(context).pop();
                    },
                  ),
                  SizedBox(height: 15),
                  RoundedButton(
                    'Cancel',
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return Transform.scale(
        scale: 0.95 + 0.05 * anim1.value,
        child: FadeTransition(
          opacity: anim1,
          child: child,
        ),
      );
    },
  );
}
