import 'dart:ui' show DisplayFeatureType;

import 'package:confetti/confetti.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../model/app_model.dart';
import '../model/app_themes.dart';
import '../model/player.dart';
import 'components/chess_view/captured_pieces_row.dart';
import 'components/chess_view/chess_board_widget.dart';
import 'components/chess_view/game_info_and_controls.dart';
import 'components/chess_view/game_info_and_controls/game_status.dart';
import 'components/chess_view/promotion_dialog.dart';
import 'components/shared/bottom_padding.dart';
import 'components/shared/glass_panel.dart';
import 'piece_guide_view.dart';
import 'settings_view.dart';

bool _isFoldableOrLargeScreen(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final hasFoldFeature = mediaQuery.displayFeatures.any(
    (f) =>
        f.type == DisplayFeatureType.fold || f.type == DisplayFeatureType.hinge,
  );
  final isLargeOrUnfolded = mediaQuery.size.shortestSide >= 600;
  return hasFoldFeature || isLargeOrUnfolded;
}

class ChessView extends StatefulWidget {
  final AppModel appModel;
  final bool isResuming;

  ChessView(this.appModel, {this.isResuming = false});

  @override
  _ChessViewState createState() => _ChessViewState(appModel);
}

class _ChessViewState extends State<ChessView> with WidgetsBindingObserver {
  AppModel appModel;
  late ConfettiController _confettiController;
  bool _hasPlayedConfetti = false;
  // Confetti colors only change with the theme. Cache to avoid recomputing
  // (via HSVColor transforms) on every listener notification.
  List<Color>? _cachedConfettiColors;
  String? _cachedConfettiThemeName;

  _ChessViewState(this.appModel);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );

    // Ensure status and navigation bars stay hidden in immersive mode as configured globally
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Listen for model changes to handle side-effects OUTSIDE of build().
    // Promotion dialogs and confetti must never be triggered from build().
    appModel.addListener(_onAppModelChanged);

    // Defer game initialization to after the page transition completes.
    // This prevents heavy work (board setup) from blocking the navigation animation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isResuming) {
        appModel.restoreGameState().then((_) {
          if (mounted) appModel.update();
        });
      } else {
        appModel.newGame(notify: true);
      }
    });
  }

  /// Handles side-effects that must NOT run inside [build]:
  /// - Pawn promotion dialog (sets `promotionRequested = false` safely)
  /// - Win confetti (plays / stops the controller)
  void _onAppModelChanged() {
    if (!mounted) return;

    // ── Promotion dialog ──────────────────────────────────────────────────
    if (appModel.promotionRequested) {
      appModel.promotionRequested = false;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showPromotionDialog(appModel),
      );
    }

    // ── Confetti ──────────────────────────────────────────────────────────
    if (appModel.gameOver &&
        appModel.userWon &&
        appModel.historyViewIndex == null) {
      if (!_hasPlayedConfetti) {
        _confettiController.play();
        _hasPlayedConfetti = true;
      }
    } else {
      if (_hasPlayedConfetti) {
        _confettiController.stop();
      }
      if (!appModel.gameOver) {
        _hasPlayedConfetti = false;
      }
    }
  }

  @override
  void dispose() {
    appModel.removeListener(_onAppModelChanged);
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (appModel.isExiting) return;
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
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (appModel.isFullscreen && !_isFoldableOrLargeScreen(context)) {
        appModel.setFullscreen(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (appModel.isFullscreen && !_isFoldableOrLargeScreen(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            appModel.isFullscreen &&
            !_isFoldableOrLargeScreen(context)) {
          appModel.setFullscreen(false);
        }
      });
    }

    // Narrow selector: only rebuild the top-level scaffold when the "ready"
    // state changes (null → non-null gameController) or when the game is
    // reset (controller identity changes). Timer ticks, moves, and other
    // frequent notifications do NOT trigger a full rebuild here.
    return Selector<AppModel, (bool, Object?)>(
      selector: (_, m) => (m.gameController != null, m.gameController),
      builder: (context, readyData, child) {
        final isReady = readyData.$1;
        final theme = appModel.theme;

        // Show themed background while game initializes.
        if (!isReady) {
          return Container(
            decoration: BoxDecoration(gradient: theme.background),
          );
        }

        // NOTE: promotion dialog and confetti are now handled by
        // _onAppModelChanged() — never mutate state inside build().

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            if (appModel.gameOver) {
              appModel.handleGameExit(
                onNavigateBack: () {
                  if (context.mounted) Navigator.of(context).pop();
                },
              );
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
              Selector<AppModel, bool>(
                selector: (_, m) => m.isFullscreen,
                builder: (context, isFullscreen, _) {
                  return SafeArea(
                    top: !isFullscreen,
                    child: Column(
                      children: [
                        if (!isFullscreen)
                          Selector<AppModel, (AppTheme, int)>(
                            selector: (_, m) => (m.theme, m.aiDifficulty),
                            builder: (_, data, __) => _buildTopBar(data.$1),
                          ),
                        Expanded(
                          child: Align(
                            alignment: isFullscreen
                                ? Alignment.topCenter
                                : Alignment.center,
                            child: Selector<AppModel,
                                (bool, bool, AppTheme, bool, bool, bool, bool)>(
                              selector: (_, m) => (
                                m.showCapturedPieces,
                                m.isBoardInverted,
                                m.theme,
                                m.showNotation,
                                m.sideCapturedPieces && isFullscreen,
                                m.flipSideCapturedPieces,
                                m.enableRotationAnimation,
                              ),
                              builder: (_, boardData, ___) {
                                final showCapturedPieces = boardData.$1;
                                final isSideCaptured = boardData.$5;
                                final isFlipped = boardData.$6;
                                final topPlayer = appModel.isBoardInverted
                                    ? Player.player1
                                    : Player.player2;
                                final bottomPlayer = appModel.isBoardInverted
                                    ? Player.player2
                                    : Player.player1;

                                final leftSidePlayer =
                                    isFlipped ? topPlayer : bottomPlayer;
                                final rightSidePlayer =
                                    isFlipped ? bottomPlayer : topPlayer;

                                return Padding(
                                  padding: EdgeInsets.only(
                                    top: isFullscreen ? 8.0 : 0.0,
                                  ),
                                  child: ChessBoardWidget(
                                    key: ValueKey(appModel.gameController),
                                    appModel,
                                    topWidget:
                                        showCapturedPieces && !isSideCaptured
                                            ? _buildCapturedPiecesWidget(
                                                player: topPlayer,
                                                isVertical: false,
                                                isTop: true,
                                              )
                                            : null,
                                    bottomWidget:
                                        showCapturedPieces && !isSideCaptured
                                            ? _buildCapturedPiecesWidget(
                                                player: bottomPlayer,
                                                isVertical: false,
                                                isBottom: true,
                                              )
                                            : null,
                                    leftWidget:
                                        showCapturedPieces && isSideCaptured
                                            ? _buildCapturedPiecesWidget(
                                                player: leftSidePlayer,
                                                isVertical: true,
                                              )
                                            : null,
                                    rightWidget:
                                        showCapturedPieces && isSideCaptured
                                            ? _buildCapturedPiecesWidget(
                                                player: rightSidePlayer,
                                                isVertical: true,
                                              )
                                            : null,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: GameInfoAndControls(appModel),
                        ),
                        BottomPadding(),
                      ],
                    ),
                  );
                },
              ),

              Selector<AppModel, AppTheme>(
                selector: (_, m) => m.theme,
                builder: (_, currentTheme, __) => Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    key: ValueKey('${currentTheme.name}_confetti'),
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: _getConfettiColors(currentTheme),
                  ),
                ),
              ),

              // ── Floating Action Buttons on Right Side (Fullscreen) ─────
              Positioned(
                top: 14,
                right: 16,
                child: Selector<AppModel, (bool, AppTheme, bool, bool)>(
                  selector: (_, m) => (
                    m.isFullscreen,
                    m.theme,
                    m.sideCapturedPieces,
                    m.flipSideCapturedPieces,
                  ),
                  builder: (_, data, __) {
                    final isFullscreen = data.$1;
                    final theme = data.$2;
                    final sideCaptured = data.$3;
                    final flipSideCaptured = data.$4;
                    if (!isFullscreen) return const SizedBox.shrink();
                    return SafeArea(
                      bottom: false,
                      left: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildExitFullscreenButton(theme),
                          const SizedBox(height: 10),
                          _buildSideCapturedPiecesButton(theme, sideCaptured),
                          const SizedBox(height: 10),
                          _buildFlipSideCapturedPiecesButton(
                            theme,
                            flipSideCaptured,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SizedBox(
        height: 44,
        child: NavigationToolbar(
          leading: appModel.playerCount == 1
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Stockfish L${appModel.aiDifficulty}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.lightTile.withValues(alpha: 0.6),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '(${AppModel.getDifficultyElo(appModel.aiDifficulty)} ELO)',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: theme.lightTile.withValues(alpha: 0.45),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                )
              : null,
          middle: FittedBox(fit: BoxFit.scaleDown, child: GameStatus()),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isFoldableOrLargeScreen(context)) ...[
                Tooltip(
                  message: 'Fullscreen',
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      appModel.haptic.light();
                      appModel.toggleFullscreen();
                    },
                    minimumSize: const Size(36, 36),
                    child: Icon(
                      Icons.fullscreen_rounded,
                      color: theme.lightTile,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Tooltip(
                message: 'Chess Guide',
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    appModel.haptic.light();
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const PieceGuideView(),
                      ),
                    );
                  },
                  child: Icon(
                    Icons.help_outline_rounded,
                    color: theme.lightTile,
                    size: 24,
                  ),
                  minimumSize: const Size(36, 36),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Settings',
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const SettingsView(),
                      ),
                    );
                  },
                  child: Icon(
                    Icons.settings_rounded,
                    color: theme.lightTile,
                    size: 24,
                  ),
                  minimumSize: const Size(36, 36),
                ),
              ),
            ],
          ),
          centerMiddle: true,
          middleSpacing: 8.0,
        ),
      ),
    );
  }

  Widget _buildCapturedPiecesWidget({
    required Player player,
    required bool isVertical,
    bool isTop = false,
    bool isBottom = false,
  }) {
    return Selector<AppModel, (int, bool, int?, AppTheme, String)>(
      selector: (_, m) => (
        m.moveMetaList.length,
        m.isPieceRotated,
        m.historyViewIndex,
        m.theme,
        m.pieceTheme,
      ),
      builder: (_, data, ___) {
        final isPieceRotated = data.$2;
        final currentTheme = data.$4;
        final currentPieceTheme = data.$5;
        final row = CapturedPiecesRow(
          appModel: appModel,
          player: player,
          pieceTheme: currentPieceTheme,
          theme: currentTheme,
          isVertical: isVertical,
          flipped: isPieceRotated,
          rotatePieces: isPieceRotated,
        );
        if (isTop) {
          return Padding(padding: const EdgeInsets.only(bottom: 6), child: row);
        }
        if (isBottom) {
          return Padding(padding: const EdgeInsets.only(top: 6), child: row);
        }
        return row;
      },
    );
  }

  Widget _buildExitFullscreenButton(AppTheme theme) {
    return Tooltip(
      message: 'Exit Fullscreen',
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0x80201F1F),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 8, spreadRadius: 1),
          ],
        ),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            appModel.haptic.light();
            appModel.toggleFullscreen();
          },
          child: Icon(
            Icons.fullscreen_exit_rounded,
            color: theme.lightTile,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildSideCapturedPiecesButton(AppTheme theme, bool sideCaptured) {
    return Tooltip(
      message: sideCaptured
          ? 'Move dead pieces to top/bottom'
          : 'Move dead pieces to sides',
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: sideCaptured
              ? theme.lightTile.withValues(alpha: 0.25)
              : const Color(0x80201F1F),
          shape: BoxShape.circle,
          border: Border.all(
            color: sideCaptured
                ? theme.lightTile.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 8, spreadRadius: 1),
          ],
        ),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            appModel.haptic.light();
            appModel.toggleSideCapturedPieces();
          },
          child: Icon(
            sideCaptured
                ? Icons.table_rows_rounded
                : Icons.view_sidebar_rounded,
            color: theme.lightTile,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildFlipSideCapturedPiecesButton(AppTheme theme, bool flipped) {
    return Tooltip(
      message: 'Flip left and right dead pieces',
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: flipped
              ? theme.lightTile.withValues(alpha: 0.25)
              : const Color(0x80201F1F),
          shape: BoxShape.circle,
          border: Border.all(
            color: flipped
                ? theme.lightTile.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 8, spreadRadius: 1),
          ],
        ),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            appModel.haptic.light();
            if (!appModel.sideCapturedPieces) {
              appModel.setSideCapturedPieces(true);
            } else {
              appModel.toggleFlipSideCapturedPieces();
            }
          },
          child: Icon(
            Icons.swap_horiz_rounded,
            color: theme.lightTile,
            size: 22,
          ),
        ),
      ),
    );
  }

  /// Returns confetti colors derived from the active theme.
  /// Result is cached by theme name so it is only recomputed on theme change,
  /// not on every Consumer<AppModel> rebuild (moves, timer ticks, etc.).
  List<Color> _getConfettiColors(AppTheme theme) {
    if (_cachedConfettiThemeName != theme.name) {
      _cachedConfettiThemeName = theme.name;
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
      _cachedConfettiColors = result;
    }
    return _cachedConfettiColors!;
  }

  void _showPromotionDialog(AppModel appModel) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      barrierDismissible: false,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, anim1, anim2) {
        return PromotionDialog(appModel, animation: anim1);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1.drive(CurveTween(curve: Curves.easeOut)),
          child: child,
        );
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
          Container(decoration: BoxDecoration(gradient: theme.background)),

          // Dot grid
          Positioned.fill(
            child: CustomPaint(
              painter: DotGridPainter(
                color: theme.lightTile.withValues(alpha: 0.04),
              ),
            ),
          ),

          // Glow blobs — RepaintBoundary keeps the gradient layer isolated
          // so the Selector's infrequent rebuilds don't cause jank.
          Positioned(
            top: 150,
            right: -50,
            child: RepaintBoundary(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.lightTile.withValues(alpha: 0.08),
                      theme.lightTile.withValues(alpha: 0.0),
                    ],
                  ),
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
                  gradient: RadialGradient(
                    colors: [
                      theme.darkTile.withValues(alpha: 0.07),
                      theme.darkTile.withValues(alpha: 0.0),
                    ],
                  ),
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
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            final appModel = Provider.of<AppModel>(
                              context,
                              listen: false,
                            );
                            await appModel.saveAndExitChessView();
                            appModel.showExitInterstitialAd(
                              onAdDismissed: () {
                                if (context.mounted)
                                  Navigator.of(context).pop();
                              },
                            );
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
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.save_rounded,
                                  color: const Color(0xFF131313),
                                  size: 18,
                                ),
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
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            final appModel = Provider.of<AppModel>(
                              context,
                              listen: false,
                            );
                            await appModel.exitChessView();
                            appModel.showExitInterstitialAd(
                              onAdDismissed: () {
                                if (context.mounted)
                                  Navigator.of(context).pop();
                              },
                            );
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
                                Icon(
                                  Icons.close_rounded,
                                  color: const Color(0xFFE5E2E1),
                                  size: 18,
                                ),
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
        opacity: anim1.drive(CurveTween(curve: Curves.easeOut)),
        child: child,
      );
    },
  ).then((_) {
    if (!appModel.gameOver && !appModel.isExiting) {
      appModel.timerService.resume();
    }
  });
}
