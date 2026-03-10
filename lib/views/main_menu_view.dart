import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../model/app_model.dart';
import '../model/app_themes.dart';
import 'components/main_menu_view/game_options.dart';
import 'components/main_menu_view/main_menu_buttons.dart';
import 'components/shared/bottom_padding.dart';

class MainMenuView extends StatefulWidget {
  @override
  _MainMenuViewState createState() => _MainMenuViewState();
}

class _MainMenuViewState extends State<MainMenuView> {
  @override
  Widget build(BuildContext context) {
    return Selector<AppModel, AppTheme>(
      selector: (_, m) => m.theme,
      builder: (context, theme, child) {
        return Container(
          decoration: BoxDecoration(gradient: theme.background),
          padding: EdgeInsets.all(30),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(
                    10, MediaQuery.of(context).padding.top + 10, 10, 0),
                child: Image.asset('assets/images/logo.png'),
              ),
              SizedBox(height: 20),
              Consumer<AppModel>(
                builder: (context, appModel, child) => GameOptions(appModel),
              ),
              SizedBox(height: 10),
              Consumer<AppModel>(
                builder: (context, appModel, child) => MainMenuButtons(appModel),
              ),
              BottomPadding(),
            ],
          ),
        );
      },
    );
  }
}
