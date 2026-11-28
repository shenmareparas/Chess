import 'dart:async';
import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' as dc;
import 'package:material_ui/material_ui.dart';

import '../../../logic/chessground_adapter.dart';
import '../../../model/app_model.dart';

class ChessBoardWidget extends StatefulWidget {
  final AppModel appModel;
  final Widget? topWidget;
  final Widget? bottomWidget;
  final Widget? leftWidget;
  final Widget? rightWidget;

  const ChessBoardWidget(
    this.appModel, {
    super.key,
    this.topWidget,
    this.bottomWidget,
    this.leftWidget,
    this.rightWidget,
  });

  @override
  State<ChessBoardWidget> createState() => _ChessBoardWidgetState();
}

class _ChessBoardWidgetState extends State<ChessBoardWidget>
    with SingleTickerProviderStateMixin {
  late final ChessboardController _controller;
  late final AnimationController _rotationController;
  late final Animation<double> _rotationTurns;
  late bool _lastInverted;

  @override
  void initState() {
    super.initState();
    _lastInverted = widget.appModel.isBoardInverted;
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 1.0,
    );
    _rotationTurns = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );
    _controller = ChessboardController(
      game: ChessgroundAdapter.buildGameData(widget.appModel),
    );
    widget.appModel.addListener(_onAppModelChanged);
    _ensurePieceThemeLoaded(widget.appModel.pieceTheme);
  }

  void _ensurePieceThemeLoaded(String pieceTheme) {
    ChessgroundAdapter.preloadPieceTheme(pieceTheme).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _checkBoardRotation() {
    final currentInverted = widget.appModel.isBoardInverted;
    if (currentInverted != _lastInverted) {
      _lastInverted = currentInverted;
      if (widget.appModel.animateBoardRotation &&
          widget.appModel.enableRotationAnimation) {
        _rotationController.forward(from: 0.0);
      } else {
        _rotationController.value = 1.0;
      }
    }
  }

  @override
  void didUpdateWidget(ChessBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appModel != widget.appModel) {
      oldWidget.appModel.removeListener(_onAppModelChanged);
      widget.appModel.addListener(_onAppModelChanged);
    }
    _checkBoardRotation();
    _syncController(animate: false);
  }

  @override
  void dispose() {
    widget.appModel.removeListener(_onAppModelChanged);
    _rotationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onAppModelChanged() {
    if (!mounted) return;
    _ensurePieceThemeLoaded(widget.appModel.pieceTheme);
    final bool shouldAnimate = !widget.appModel.snapNextBoardUpdate;
    widget.appModel.snapNextBoardUpdate = false;
    _checkBoardRotation();
    _syncController(animate: shouldAnimate);
    setState(() {});
  }

  void _syncController({required bool animate}) {
    final newGame = ChessgroundAdapter.buildGameData(widget.appModel);
    final oldGame = _controller.game;
    if (newGame.fen != oldGame.fen ||
        newGame.playerSide != oldGame.playerSide ||
        newGame.sideToMove != oldGame.sideToMove ||
        newGame.lastMove != oldGame.lastMove ||
        newGame.kingSquareInCheck != oldGame.kingSquareInCheck ||
        newGame.validMoves.length != oldGame.validMoves.length) {
      _controller.updatePosition(
        newGame,
        animate: animate,
        resetPremove: widget.appModel.historyViewIndex != null ||
            widget.appModel.gameOver,
      );
    }
  }

  void _handleMove(dc.Move move, {bool? viaDragAndDrop}) {
    final controller = widget.appModel.gameController;
    if (controller == null || move is! dc.NormalMove) return;

    final (
      fromTile,
      toTile,
    ) = ChessgroundAdapter.chessgroundMoveToInternalTiles(
      move,
      controller.board,
    );

    // autoQueenPromotion is enabled on ChessboardSettings solely to suppress
    // chessground's inline PromotionSelector; passing promotionType: null
    // triggers the GlassPanel PromotionDialog.
    controller.executeMove(fromTile, toTile, promotionType: null);
  }

  void _handleTouchedSquare(dc.Square square) {
    final appModel = widget.appModel;
    final controller = appModel.gameController;
    if (controller == null ||
        appModel.gameOver ||
        appModel.isAIsTurn ||
        appModel.historyViewIndex != null) {
      return;
    }

    final tile = ChessgroundAdapter.squareToTile(square);
    final piece = controller.board.tiles[tile];
    if (piece != null && piece.player == appModel.turn) {
      final moves = controller.board.movesForPiece(piece);
      if (moves.isEmpty) {
        controller.triggerWarningTile(tile);
      } else {
        appModel.haptic.selection();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appModel = widget.appModel;
    final warningTile = appModel.gameController?.warningTile;
    final checkHintTile =
        appModel.showHints ? appModel.gameController?.checkHintTile : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double verticalReserve = (widget.topWidget != null ? 42.0 : 0.0) +
            (widget.bottomWidget != null ? 42.0 : 0.0);
        final double horizontalReserve =
            (widget.leftWidget != null ? 44.0 : 0.0) +
                (widget.rightWidget != null ? 44.0 : 0.0);
        final double maxSide = math.min(
          constraints.maxWidth - horizontalReserve,
          constraints.maxHeight - verticalReserve,
        );
        final double boardSize = maxSide.clamp(0.0, double.infinity);

        final settings = ChessboardSettings(
          pieceAssets: ChessgroundAdapter.buildPieceAssets(appModel.pieceTheme),
          colorScheme: ChessgroundAdapter.buildColorScheme(appModel.theme),
          enableCoordinates: false,
          animationDuration: const Duration(milliseconds: 200),
          showLastMove: appModel.showHints,
          showValidMoves: appModel.showHints,
          pieceOrientationBehavior: ChessgroundAdapter.buildPieceOrientation(
            appModel,
          ),
          pieceShiftMethod: PieceShiftMethod.either,
          autoQueenPromotion: true,
          enablePremoves: appModel.playingWithAI,
          dragFeedbackOffset: const Offset(0.0, -1.0),
        );

        final Widget board = SizedBox(
          width: boardSize,
          height: boardSize,
          child: Stack(
            children: [
              Positioned.fill(
                child: RotationTransition(
                  turns: _rotationTurns,
                  child: Stack(
                    children: [
                      Chessboard(
                        size: boardSize,
                        orientation: ChessgroundAdapter.buildOrientation(
                          appModel.isBoardInverted,
                        ),
                        controller: _controller,
                        settings: settings,
                        onMove: appModel.historyViewIndex == null
                            ? _handleMove
                            : null,
                        onTouchedSquare: _handleTouchedSquare,
                      ),
                      if (checkHintTile != null)
                        _buildCheckOverlay(
                          checkHintTile,
                          boardSize,
                          appModel.isBoardInverted,
                          appModel.theme.checkHint,
                        ),
                      if (warningTile != null)
                        _buildWarningOverlay(
                          warningTile,
                          boardSize,
                          appModel.isBoardInverted,
                        ),
                    ],
                  ),
                ),
              ),
              if (appModel.showNotation)
                Positioned.fill(
                  child: _NotationOverlay(
                    lightTileColor: appModel.theme.lightTile,
                    darkTileColor: appModel.theme.darkTile,
                    isRotated: appModel.isBoardInverted,
                    size: boardSize,
                  ),
                ),
            ],
          ),
        );

        Widget boardLayout = board;

        if (widget.leftWidget != null || widget.rightWidget != null) {
          boardLayout = Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.leftWidget != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: widget.leftWidget,
                ),
              board,
              if (widget.rightWidget != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: widget.rightWidget,
                ),
            ],
          );
        }

        if (widget.topWidget != null || widget.bottomWidget != null) {
          boardLayout = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.topWidget != null)
                SizedBox(width: boardSize, child: widget.topWidget),
              boardLayout,
              if (widget.bottomWidget != null)
                SizedBox(width: boardSize, child: widget.bottomWidget),
            ],
          );
        }

        return Center(child: boardLayout);
      },
    );
  }

  Widget _buildTileOverlay(
    int tile,
    double boardSize,
    bool isInverted,
    Widget child,
  ) {
    final tileSize = boardSize / 8;
    final rawCol = tile % 8;
    final rawRow = tile ~/ 8;
    final col = isInverted ? 7 - rawCol : rawCol;
    final row = isInverted ? 7 - rawRow : rawRow;
    return Positioned(
      left: col * tileSize,
      top: row * tileSize,
      width: tileSize,
      height: tileSize,
      child: IgnorePointer(child: child),
    );
  }

  Widget _buildCheckOverlay(
    int tile,
    double boardSize,
    bool isInverted,
    Color checkColor,
  ) {
    return _buildTileOverlay(
      tile,
      boardSize,
      isInverted,
      Container(
        decoration: BoxDecoration(
          color: checkColor.withValues(alpha: 0.45),
          border: Border.all(color: checkColor, width: 2.0),
        ),
      ),
    );
  }

  Widget _buildWarningOverlay(int tile, double boardSize, bool isInverted) {
    return _buildTileOverlay(
      tile,
      boardSize,
      isInverted,
      Container(color: const Color(0xAAFF3B30)),
    );
  }
}

class _NotationOverlay extends StatefulWidget {
  final Color lightTileColor;
  final Color darkTileColor;
  final bool isRotated;
  final double size;

  const _NotationOverlay({
    required this.lightTileColor,
    required this.darkTileColor,
    required this.isRotated,
    required this.size,
  });

  @override
  _NotationOverlayState createState() => _NotationOverlayState();
}

class _NotationOverlayState extends State<_NotationOverlay> {
  late bool _visibleRotated;
  double _opacity = 1.0;
  Timer? _fadeTimer;

  @override
  void initState() {
    super.initState();
    _visibleRotated = widget.isRotated;
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(_NotationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRotated != widget.isRotated) {
      // Cancel any in-flight fade timer before starting a new one.
      // Without this, rapid board rotations within the 600 ms window
      // would stack multiple timers that all attempt setState.
      _fadeTimer?.cancel();
      setState(() {
        _opacity = 0.0;
      });
      _fadeTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _visibleRotated = widget.isRotated;
            _opacity = 1.0;
          });
        }
        _fadeTimer = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        duration: Duration(milliseconds: _opacity == 0.0 ? 100 : 300),
        opacity: _opacity,
        child: Stack(
          children: [
            // Files (Letters)
            for (int i = 0; i < 8; i++) _buildFileLetter(i),
            // Ranks (Numbers)
            for (int i = 0; i < 8; i++) _buildRankNumber(i),
          ],
        ),
      ),
    );
  }

  Widget _buildFileLetter(int i) {
    final sitsOnDarkTile = i % 2 == 0;
    final textColor =
        sitsOnDarkTile ? widget.lightTileColor : widget.darkTileColor;
    final shadowColor =
        sitsOnDarkTile ? widget.darkTileColor : widget.lightTileColor;
    final textShadows = [
      Shadow(color: shadowColor, offset: const Offset(1, 1), blurRadius: 1.0),
      Shadow(color: shadowColor, offset: const Offset(-1, 1), blurRadius: 1.0),
      Shadow(color: shadowColor, offset: const Offset(1, -1), blurRadius: 1.0),
      Shadow(color: shadowColor, offset: const Offset(-1, -1), blurRadius: 1.0),
    ];

    return Positioned(
      left: (i * widget.size / 8),
      bottom: 2,
      width: widget.size / 8 - 2,
      child: Text(
        String.fromCharCode(
          (_visibleRotated ? 'h' : 'a').codeUnitAt(0) +
              (_visibleRotated ? -i : i),
        ),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          shadows: textShadows,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildRankNumber(int i) {
    final sitsOnLightTile = i % 2 == 0;
    final textColor =
        sitsOnLightTile ? widget.darkTileColor : widget.lightTileColor;
    final shadowColor =
        sitsOnLightTile ? widget.lightTileColor : widget.darkTileColor;
    final textShadows = [
      Shadow(color: shadowColor, offset: const Offset(1, 1), blurRadius: 1.0),
      Shadow(color: shadowColor, offset: const Offset(-1, 1), blurRadius: 1.0),
      Shadow(color: shadowColor, offset: const Offset(1, -1), blurRadius: 1.0),
      Shadow(color: shadowColor, offset: const Offset(-1, -1), blurRadius: 1.0),
    ];

    return Positioned(
      top: (i * widget.size / 8) + 2,
      left: 4,
      height: widget.size / 8,
      child: Text(
        (_visibleRotated ? i + 1 : 8 - i).toString(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          shadows: textShadows,
        ),
      ),
    );
  }
}
