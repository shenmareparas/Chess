import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/game_state_storage.dart';
import '../model/app_model.dart';
import '../model/app_themes.dart';
import 'components/main_menu_view/game_options.dart';
import 'components/main_menu_view/main_menu_buttons.dart';
import 'components/shared/bottom_padding.dart';
import 'components/shared/glass_panel.dart';
import 'settings_view.dart';

class MainMenuView extends StatefulWidget {
  @override
  _MainMenuViewState createState() => _MainMenuViewState();
}

class _MainMenuViewState extends State<MainMenuView> {
  late final ScrollController _scrollController;
  bool _hasSavedGame = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _checkSavedGame();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkSavedGame() async {
    final hasSaved = await GameStateStorage.hasSavedGame();
    if (mounted) {
      setState(() {
        _hasSavedGame = hasSaved;
      });
    }
  }

  void _resetScroll() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<AppModel>(context);
    return Selector<AppModel, AppTheme>(
      selector: (_, m) => m.theme,
      builder: (context, theme, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: theme.background,
            ),
            child: Stack(
              children: [
                // 1. Dot Grid Background
                Positioned.fill(
                  child: CustomPaint(
                    painter: DotGridPainter(
                        color: theme.lightTile.withValues(alpha: 0.05)),
                  ),
                ),

                // 2. Glowing Blur Background
                Positioned(
                  top: 100,
                  left: MediaQuery.of(context).size.width * 0.2,
                  child: RepaintBoundary(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.lightTile.withValues(
                                alpha: 0.06), // Very soft theme-colored glow
                            blurRadius: 100,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Main Content
                SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // Scrollable Options List
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: GameOptions(
                            appModel,
                            hasSavedGame: _hasSavedGame,
                            scrollController: _scrollController,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Floating Settings Button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  right: 20,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => SettingsView(),
                        ),
                      );
                      Future.delayed(
                        const Duration(milliseconds: 300),
                        () => _resetScroll(),
                      );
                    },
                    child: Builder(
                      builder: (context) {
                        final bgTop = theme.background?.colors.first ??
                            const Color(0xFF0A0F0C);
                        final isDarkBg =
                            ThemeData.estimateBrightnessForColor(bgTop) ==
                                Brightness.dark;
                        return Icon(
                          Icons.settings,
                          color: isDarkBg
                              ? const Color(0xFFC3C8C2)
                              : const Color(0xFF313030),
                          size: 24,
                        );
                      },
                    ),
                  ),
                ),

                // 4. Floating Bottom Action Buttons
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MainMenuButtons(
                          appModel,
                          hasSavedGame: _hasSavedGame,
                          onGameReturned: _checkSavedGame,
                          onResetScroll: _resetScroll,
                        ),
                        BottomPadding(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
