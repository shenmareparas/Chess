import 'package:en_passant/model/app_model.dart';
import 'package:en_passant/model/app_themes.dart';
import 'package:en_passant/views/components/shared/text_variable.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

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
    return Consumer<AppModel>(
      builder: (context, appModel, child) {
        if (_scrollController.hasClients &&
            _scrollController.selectedItem != appModel.themeIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpToItem(appModel.themeIndex);
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
                onSelectedItemChanged: appModel.setTheme,
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
