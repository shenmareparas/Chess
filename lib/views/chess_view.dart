import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/chess_game.dart';
import '../model/app_model.dart';
import '../model/app_themes.dart';
import 'components/chess_view/chess_board_widget.dart';
import 'components/chess_view/game_info_and_controls.dart';
import 'components/chess_view/game_info_and_controls/game_status.dart';
import 'components/chess_view/promotion_dialog.dart';
import 'components/shared/bottom_padding.dart';
import 'components/shared/rounded_button.dart';

class ChessView extends StatefulWidget {
  final AppModel appModel;
  final bool isResuming;

  ChessView(this.appModel, {this.isResuming = false});

  @override
  _ChessViewState createState() => _ChessViewState(appModel);
}

class _ChessViewState extends State<ChessView> with WidgetsBindingObserver {
  AppModel appModel;
  ChessGame? chessGame;
  late ConfettiController _confettiController;

  _ChessViewState(this.appModel);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));

    // Defer game initialization to after the page transition completes.
    // This prevents heavy work (sprite creation, board setup) from
    // blocking the navigation animation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isResuming) {
        appModel.restoreGameState().then((_) => _initFlameGame());
      } else {
        appModel.newGame(notify: false);
        _initFlameGame();
      }
    });
  }

  void _initFlameGame() {
    if (appModel.gameController != null) {
      setState(() {
        chessGame = ChessGame(appModel.gameController!, appModel);
      });
      // Defer notifying listeners if needed to let the flame engine setup
      Future.delayed(Duration(milliseconds: 50), () {
         if (mounted) appModel.update();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
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
        final theme = appModel.theme;
        // Show themed background while game initializes
        if (appModel.gameController == null || chessGame == null) {
          return Container(
            decoration: BoxDecoration(gradient: theme.background),
          );
        }

        if (appModel.promotionRequested) {
          appModel.promotionRequested = false;
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _showPromotionDialog(appModel));
        }

        if (appModel.gameOver && appModel.userWon) {
          _confettiController.play();
        } else {
          _confettiController.stop();
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
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(gradient: theme.background),
                padding: EdgeInsets.all(30),
                child: Column(
                  children: [
                    Spacer(),
                    ChessBoardWidget(appModel, chessGame!),
                    SizedBox(height: 30),
                    GameStatus(),
                    Spacer(),
                    GameInfoAndControls(appModel),
                    BottomPadding(),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: [
                    theme.lightTile,
                    theme.darkTile,
                    theme.moveHint,
                    theme.latestMove,
                  ],
                ),
              ),
            ],
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
      return Selector<AppModel, AppTheme>(
        selector: (_, m) => m.theme,
        builder: (dialogContext, theme, child) => Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(maxWidth: 340),
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: theme.background,
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
                  SizedBox(height: 15),
                  Consumer<AppModel>(
                    builder: (context, appModel, child) => RoundedButton(
                      'Save & Exit',
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        appModel.saveAndExitChessView();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  SizedBox(height: 15),
                  Consumer<AppModel>(
                    builder: (context, appModel, child) => RoundedButton(
                      'Exit',
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        appModel.exitChessView();
                        Navigator.of(context).pop();
                      },
                    ),
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
