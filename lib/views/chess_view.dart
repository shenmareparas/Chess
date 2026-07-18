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
import 'components/shared/glass_panel.dart';
import 'settings_view.dart';

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
  bool _hasPlayedConfetti = false;

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
        appModel.saveGameStateImmediate();
        appModel.timerService.pause();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (!appModel.gameOver) {
        appModel.timerService.resume();
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

        if (chessGame != null &&
            appModel.gameController != null &&
            chessGame!.controller != appModel.gameController) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initFlameGame();
          });
          return Container(
            decoration: BoxDecoration(gradient: theme.background),
          );
        }

        if (appModel.promotionRequested) {
          appModel.promotionRequested = false;
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _showPromotionDialog(appModel));
        }

        if (appModel.gameOver &&
            appModel.userWon &&
            appModel.historyViewIndex == null) {
          if (!_hasPlayedConfetti) {
            _confettiController.play();
            _hasPlayedConfetti = true;
          }
        } else {
          _confettiController.stop();
          if (!appModel.gameOver) {
            _hasPlayedConfetti = false;
          }
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
              // ── Static background ──────────────────────────────────────
              // Driven by Selector so it only rebuilds on theme change,
              // NOT on every move / AI turn / timer tick.
              Positioned.fill(
                child: Selector<AppModel, AppTheme>(
                  selector: (_, m) => m.theme,
                  builder: (_, theme, __) => _ChessBackground(theme: theme),
                ),
              ),

              // ── Game content ───────────────────────────────────────────
              SafeArea(
                child: Column(
                  children: [
                    // Top App Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: appModel.playerCount == 1
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Stockfish L${appModel.aiDifficulty}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: theme.lightTile
                                                .withValues(alpha: 0.6),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '(${AppModel.getDifficultyElo(appModel.aiDifficulty)} ELO)',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                            color: theme.lightTile
                                                .withValues(alpha: 0.45),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                          GameStatus(),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) =>
                                          const SettingsView(),
                                    ),
                                  );
                                },
                                child: Icon(
                                  Icons.settings_rounded,
                                  color: theme.lightTile,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        child: Center(
                          child: ChessBoardWidget(appModel, chessGame!),
                        ),
                      ),
                    ),

                    // Controls and Buttons at the bottom
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: GameInfoAndControls(appModel),
                    ),
                    BottomPadding(),
                  ],
                ),
              ),

              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  key: ValueKey('${theme.name}_confetti'),
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: _getConfettiColors(theme),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Color> _getConfettiColors(AppTheme theme) {
    final List<Color> result = [];
    final candidates = [
      theme.lightTile,
      theme.moveHint,
      theme.latestMove,
      theme.notation,
    ];
    for (final color in candidates) {
      final hsv = HSVColor.fromColor(color);
      final saturation = hsv.saturation > 0.6 ? hsv.saturation : 0.6;
      final value = hsv.value > 0.8 ? hsv.value : 0.8;
      result.add(hsv.withSaturation(saturation).withValue(value).toColor());
    }
    return result;
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

/// Static decorative background for [ChessView].
///
/// Separated from the game-content [Consumer] so it is only rebuilt when the
/// theme changes — not on every move, AI result, or timer tick.
class _ChessBackground extends StatelessWidget {
  final AppTheme theme;

  const _ChessBackground({required this.theme});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          // Gradient fill
          Container(
            decoration: BoxDecoration(gradient: theme.background),
          ),

          // Dot grid
          Positioned.fill(
            child: CustomPaint(
              painter: DotGridPainter(
                color: theme.lightTile.withValues(alpha: 0.04),
              ),
            ),
          ),

          // Glow blobs — RepaintBoundary keeps the expensive boxShadow on its
          // own GPU layer so the Selector's infrequent rebuilds don't cause jank.
          Positioned(
            top: 150,
            right: -50,
            child: RepaintBoundary(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.lightTile.withValues(alpha: 0.05),
                      blurRadius: 120,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 100,
            left: -50,
            child: RepaintBoundary(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.darkTile.withValues(alpha: 0.04),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showExitDialog(BuildContext context) {
  final appModel = Provider.of<AppModel>(context, listen: false);
  appModel.timerService.pause();
  showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    barrierDismissible: true,
    barrierLabel: '',
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (dialogContext, anim1, anim2) {
      return Selector<AppModel, AppTheme>(
        selector: (_, m) => m.theme,
        builder: (dialogContext, theme, child) => Center(
          child: Material(
            color: Colors.transparent,
            child: GlassPanel(
              borderRadius: 24,
              padding: const EdgeInsets.all(20),
              color: const Color(0x80201F1F),
              animation: anim1,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Leave Game',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE5E2E1),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Would you like to save your progress\nbefore exiting? You can resume\nfrom this exact position later',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFC3C8C2),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Actions Column
                    Column(
                      children: [
                        // Save & Exit (Solid Premium Button)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            final appModel =
                                Provider.of<AppModel>(context, listen: false);
                            appModel.saveAndExitChessView();
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            width: double.infinity,
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F0),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x20000000),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ]),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_rounded,
                                    color: const Color(0xFF131313), size: 18),
                                const SizedBox(width: 8),
                                const Text(
                                  'Save & Exit',
                                  style: TextStyle(
                                    color: Color(0xFF131313),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Exit Without Saving (Glass / Outline Button)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            final appModel =
                                Provider.of<AppModel>(context, listen: false);
                            appModel.exitChessView();
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            width: double.infinity,
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0x30F5F5F0),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close_rounded,
                                    color: const Color(0xFFE5E2E1), size: 18),
                                const SizedBox(width: 8),
                                const Text(
                                  'Exit Without Saving',
                                  style: TextStyle(
                                    color: Color(0xFFE5E2E1),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Cancel (Clean Text Button)
                        CupertinoButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFF8D928C),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return FadeTransition(
        opacity: anim1.drive(
          CurveTween(curve: Curves.easeOut),
        ),
        child: child,
      );
    },
  ).then((_) {
    if (!appModel.gameOver) {
      appModel.timerService.resume();
    }
  });
}
