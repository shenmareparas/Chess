import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';

import '../../../logic/chess_game.dart';
import '../../../model/app_model.dart';

class ChessBoardWidget extends StatelessWidget {
  final AppModel appModel;
  final ChessGame chessGame;

  ChessBoardWidget(this.appModel, this.chessGame);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedRotation(
          turns: appModel.isBoardInverted ? 0.5 : 0,
          duration: appModel.animateBoardRotation
              ? Duration(milliseconds: 600)
              : Duration.zero,
          curve: Curves.easeInOut,
          child: Container(
            decoration: appModel.theme.name != 'Video Chess'
                ? BoxDecoration(
                    border: Border.all(
                      color: appModel.theme.border,
                      width: 4,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        color: Color(0x88000000),
                      ),
                    ],
                  )
                : BoxDecoration(),
            child: ClipRRect(
              borderRadius: appModel.theme.name != 'Video Chess'
                  ? BorderRadius.circular(4)
                  : BorderRadius.zero,
              child: Container(
                width: MediaQuery.of(context).size.width - 68,
                height: MediaQuery.of(context).size.width - 68,
                child: GameWidget(game: chessGame),
              ),
            ),
          ),
        ),
        if (appModel.showNotation)
          Container(
            width: MediaQuery.of(context).size.width - 68,
            height: MediaQuery.of(context).size.width - 68,
            child: _NotationOverlay(
              appModel.theme.notation,
              isRotated: appModel.isBoardInverted,
            ),
          ),
      ],
    );
  }
}

class _NotationOverlay extends StatefulWidget {
  final Color color;
  final bool isRotated;

  const _NotationOverlay(this.color, {required this.isRotated});

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
    } else {
      // If color changed but flip didn't (e.g. theme change), update state immediately if needed
      if (oldWidget.color != widget.color) {
        setState(() {});
      }
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
            for (int i = 0; i < 8; i++)
              Positioned(
                left: (i * (MediaQuery.of(context).size.width - 68) / 8),
                bottom: 1,
                width: (MediaQuery.of(context).size.width - 68) / 8,
                child: Text(
                  String.fromCharCode(
                      (_visibleRotated ? 'h' : 'a').codeUnitAt(0) +
                          (_visibleRotated ? -i : i)),
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            // Ranks (Numbers)
            for (int i = 0; i < 8; i++)
              Positioned(
                top: (i * (MediaQuery.of(context).size.width - 68) / 8) + 2,
                left: 6,
                height: (MediaQuery.of(context).size.width - 68) / 8,
                child: Text(
                  (_visibleRotated ? i + 1 : 8 - i).toString(),
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
