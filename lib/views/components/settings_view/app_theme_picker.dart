import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/app_model.dart';
import '../../../model/app_themes.dart';
import '../shared/glass_panel.dart';

class AppThemePicker extends StatefulWidget {
  const AppThemePicker({Key? key}) : super(key: key);

  @override
  _AppThemePickerState createState() => _AppThemePickerState();
}

class _AppThemePickerState extends State<AppThemePicker> {
  late FixedExtentScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final appModel = Provider.of<AppModel>(context, listen: false);
    _scrollController =
        FixedExtentScrollController(initialItem: appModel.themeIndex);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<AppModel>(context);
    final theme = appModel.theme;

    return Selector<AppModel, int>(
      selector: (_, m) => m.themeIndex,
      builder: (context, themeIndex, child) {
        if (_scrollController.hasClients &&
            _scrollController.selectedItem != themeIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpToItem(themeIndex);
            }
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'App Theme',
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
              child: SizedBox(
                height: 120,
                child: CupertinoPicker(
                  scrollController: _scrollController,
                  selectionOverlay: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.lightTile.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white.withValues(alpha: 0.03),
                    ),
                  ),
                  itemExtent: 44,
                  onSelectedItemChanged: (index) {
                    Provider.of<AppModel>(context, listen: false).setTheme(index);
                  },
                  children: themeList
                      .map(
                        (t) => Container(
                          alignment: Alignment.center,
                          child: Text(
                            t.name ?? "",
                            style: const TextStyle(
                              fontSize: 18,
                              fontFamily: 'Inter',
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
          ],
        );
      },
    );
  }
}
