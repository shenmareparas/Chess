import 'package:flutter/material.dart';

import '../../../logic/shared_functions.dart';
import '../../../model/app_model.dart';

class PiecePreview extends StatelessWidget {
  final AppModel appModel;

  const PiecePreview(this.appModel, {Key? key}) : super(key: key);

  Map<int, String> get imageMap {
    final themeFormatted = formatPieceTheme(appModel.pieceTheme);
    return {
      0: 'assets/images/pieces/$themeFormatted/king_black.png',
      1: 'assets/images/pieces/$themeFormatted/queen_white.png',
      2: 'assets/images/pieces/$themeFormatted/rook_white.png',
      3: 'assets/images/pieces/$themeFormatted/bishop_black.png',
      4: 'assets/images/pieces/$themeFormatted/knight_black.png',
      5: 'assets/images/pieces/$themeFormatted/pawn_white.png',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = appModel.theme;
    return SizedBox(
      width: 80,
      height: 120,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (row) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(2, (col) {
              final index = row * 2 + col;
              final isLight = (row + col) % 2 == 0;
              final tileColor = isLight ? theme.lightTile : theme.darkTile;
              final imagePath = imageMap[index];

              return Container(
                width: 40,
                height: 40,
                color: tileColor,
                padding: const EdgeInsets.all(5),
                child: imagePath != null
                    ? Image.asset(
                        imagePath,
                        width: 30,
                        height: 30,
                        fit: BoxFit.contain,
                      )
                    : null,
              );
            }),
          );
        }),
      ),
    );
  }
}
