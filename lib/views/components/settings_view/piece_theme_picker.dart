import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../model/app_model.dart';
import '../shared/glass_panel.dart';
import 'piece_preview.dart';

class PieceThemePicker extends StatefulWidget {
  const PieceThemePicker({Key? key}) : super(key: key);

  @override
  _PieceThemePickerState createState() => _PieceThemePickerState();
}

class _PieceThemePickerState extends State<PieceThemePicker> {
  late FixedExtentScrollController _scrollController;
  PiecePreview? _piecePreview;
  String? _lastPieceTheme;

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
        final theme = appModel.theme;

        if (_scrollController.hasClients &&
            _scrollController.selectedItem != appModel.pieceThemeIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpToItem(appModel.pieceThemeIndex);
            }
          });
        }

        final currentPieceTheme = appModel.pieceTheme;
        if (_piecePreview == null || _lastPieceTheme != currentPieceTheme) {
          _piecePreview = PiecePreview(appModel);
          _lastPieceTheme = currentPieceTheme;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Piece Theme',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.lightTile,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            GlassPanel(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 120,
                      child: CupertinoPicker(
                        scrollController: _scrollController,
                        selectionOverlay: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color:
                                CupertinoColors.white.withValues(alpha: 0.03),
                          ),
                        ),
                        itemExtent: 44,
                        onSelectedItemChanged: appModel.setPieceTheme,
                        children: appModel.pieceThemes
                            .map(
                              (t) => Container(
                                alignment: Alignment.center,
                                child: Text(
                                  t,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFE5E2E1),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    height: 120,
                    width: 80,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GameWidget(
                        game: _piecePreview!,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
