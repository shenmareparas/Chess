import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../../model/app_model.dart';
import '../chess_view/promotion_dialog.dart';
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

  int _easterEggTapCount = 0;
  Timer? _easterEggResetTimer;
  late FToast _fToast;

  @override
  void initState() {
    super.initState();
    _fToast = FToast();
    _fToast.init(context);
    final appModel = Provider.of<AppModel>(context, listen: false);
    _scrollController =
        FixedExtentScrollController(initialItem: appModel.pieceThemeIndex);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _easterEggResetTimer?.cancel();
    _fToast.removeCustomToast();
    super.dispose();
  }

  void _onPiecePreviewTap(AppModel appModel) {
    _easterEggResetTimer?.cancel();
    _easterEggTapCount++;
    if (_easterEggTapCount >= 7) {
      _easterEggTapCount = 0;
      _fToast.removeCustomToast();
      showCupertinoDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => PromotionDialog(appModel),
      );
    } else {
      _easterEggResetTimer = Timer(const Duration(seconds: 2), () {
        _easterEggTapCount = 0;
      });
      // Start showing the countdown toast on the 4th tap (3 steps remaining)
      if (_easterEggTapCount >= 4) {
        final stepsRemaining = 7 - _easterEggTapCount;
        _fToast.removeCustomToast();
        _fToast.showToast(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xCC201F1F),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: CupertinoColors.white.withValues(alpha: 0.12),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              'You are $stepsRemaining step${stepsRemaining == 1 ? "" : "s"} away from promotion preview',
              style: const TextStyle(
                color: Color(0xFFE5E2E1),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          gravity: ToastGravity.BOTTOM,
          toastDuration: const Duration(milliseconds: 1200),
        );
      }
    }
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
                  GestureDetector(
                    onTap: () => _onPiecePreviewTap(appModel),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      height: 120,
                      width: 80,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GameWidget(
                          game: _piecePreview!,
                        ),
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
