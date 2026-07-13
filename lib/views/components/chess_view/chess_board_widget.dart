import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../logic/chess_game.dart';
import '../../../model/app_model.dart';

class ChessBoardWidget extends StatelessWidget {
  final AppModel appModel;
  final ChessGame chessGame;

  ChessBoardWidget(this.appModel, this.chessGame);

  @override
  Widget build(BuildContext context) {
    final double boardSize = MediaQuery.of(context).size.width - 8;
    return Stack(
      children: [
        AnimatedRotation(
          turns: appModel.isBoardInverted ? 0.5 : 0,
          duration: appModel.animateBoardRotation
              ? Duration(milliseconds: 600)
              : Duration.zero,
          curve: Curves.easeInOut,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: appModel.theme.border,
                width: 4,
              ),
            ),
            child: Container(
              width: boardSize,
              height: boardSize,
              child: GameWidget(game: chessGame),
            ),
          ),
        ),
        if (appModel.showNotation)
          Positioned(
            left: 4,
            top: 4,
            width: boardSize,
            height: boardSize,
            child: _NotationOverlay(
              lightTileColor: appModel.theme.lightTile,
              darkTileColor: appModel.theme.darkTile,
              isRotated: appModel.isBoardInverted,
              size: boardSize,
            ),
          ),
      ],
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

  @override
  void initState() {
    super.initState();
    _visibleRotated = widget.isRotated;
  }

  @override
  void didUpdateWidget(_NotationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRotated != widget.isRotated) {
      setState(() {
        _opacity = 0.0;
      });
      Future.delayed(Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _visibleRotated = widget.isRotated;
            _opacity = 1.0;
          });
        }
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
