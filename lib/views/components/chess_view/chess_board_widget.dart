import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:material_ui/material_ui.dart';

import '../../../logic/chess_game.dart';
import '../../../model/app_model.dart';

class ChessBoardWidget extends StatelessWidget {
  final AppModel appModel;
  final ChessGame chessGame;
  final Widget? topWidget;
  final Widget? bottomWidget;
  final Widget? leftWidget;
  final Widget? rightWidget;

  ChessBoardWidget(
    this.appModel,
    this.chessGame, {
    this.topWidget,
    this.bottomWidget,
    this.leftWidget,
    this.rightWidget,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double verticalReserve = (topWidget != null ? 42.0 : 0.0) +
            (bottomWidget != null ? 42.0 : 0.0);
        final double horizontalReserve = (leftWidget != null ? 44.0 : 0.0) +
            (rightWidget != null ? 44.0 : 0.0);
        final double maxSide = math.min(
          constraints.maxWidth - horizontalReserve,
          constraints.maxHeight - verticalReserve,
        );
        final double boardSize = maxSide.clamp(0.0, double.infinity);

        final Widget board = SizedBox(
          width: boardSize,
          height: boardSize,
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedRotation(
                  turns: appModel.isBoardInverted ? 0.5 : 0,
                  duration: appModel.animateBoardRotation
                      ? const Duration(milliseconds: 600)
                      : Duration.zero,
                  curve: Curves.easeInOut,
                  child: SizedBox(
                    width: boardSize,
                    height: boardSize,
                    child: GameWidget(game: chessGame),
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

        if (leftWidget != null || rightWidget != null) {
          boardLayout = Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leftWidget != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: leftWidget,
                ),
              board,
              if (rightWidget != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: rightWidget,
                ),
            ],
          );
        }

        if (topWidget != null || bottomWidget != null) {
          boardLayout = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (topWidget != null)
                SizedBox(
                  width: boardSize,
                  child: topWidget,
                ),
              boardLayout,
              if (bottomWidget != null)
                SizedBox(
                  width: boardSize,
                  child: bottomWidget,
                ),
            ],
          );
        }

        return Center(
          child: boardLayout,
        );
      },
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
        String.fromCharCode((_visibleRotated ? 'h' : 'a').codeUnitAt(0) +
            (_visibleRotated ? -i : i)),
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
