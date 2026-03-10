import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../model/app_model.dart';
import '../shared/text_variable.dart';
import 'piece_preview.dart';

class PieceThemePicker extends StatefulWidget {
  @override
  _PieceThemePickerState createState() => _PieceThemePickerState();
}

class _PieceThemePickerState extends State<PieceThemePicker> {
  late FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final appModel = Provider.of<AppModel>(context, listen: false);
    _scrollController =
        FixedExtentScrollController(initialItem: appModel.pieceThemeIndex);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, appModel, child) {
        if (_scrollController.hasClients &&
            _scrollController.selectedItem != appModel.pieceThemeIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpToItem(appModel.pieceThemeIndex);
            }
          });
        }
        return Column(
          children: [
            Container(
              alignment: Alignment.center,
              child: TextRegular('Piece Theme'),
              padding: EdgeInsets.symmetric(vertical: 10),
            ),
            ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(15)),
              child: Container(
                height: 120,
                decoration: BoxDecoration(color: Color(0x20000000)),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: _scrollController,
                        selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                          background: Color(0x20000000),
                        ),
                        itemExtent: 50,
                        onSelectedItemChanged: appModel.setPieceTheme,
                        children: appModel.pieceThemes
                            .map(
                              (theme) => Container(
                                alignment: Alignment.center,
                                padding: EdgeInsets.all(10),
                                child: TextRegular(theme),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    Container(
                      height: 120,
                      width: 80,
                      child: GameWidget(
                        game: PiecePreview(appModel),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
