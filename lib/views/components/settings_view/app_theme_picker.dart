import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../model/app_model.dart';
import '../../../model/app_themes.dart';
import '../shared/text_variable.dart';

class AppThemePicker extends StatefulWidget {
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
          children: [
            Container(
              alignment: Alignment.center,
              child: TextRegular('App Theme'),
              padding: EdgeInsets.symmetric(vertical: 10),
            ),
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(15)),
                color: Color(0x20000000),
              ),
              child: CupertinoPicker(
                scrollController: _scrollController,
                selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                  background: Color(0x20000000),
                ),
                itemExtent: 50,
                onSelectedItemChanged: Provider.of<AppModel>(context, listen: false).setTheme,
                children: themeList
                    .map(
                      (theme) => Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.all(10),
                        child: TextRegular(theme.name ?? ""),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
