import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/app_model.dart';
import '../model/app_themes.dart';
import 'components/settings_view/app_theme_picker.dart';
import 'components/settings_view/piece_theme_picker.dart';
import 'components/settings_view/toggles.dart';
import 'components/shared/bottom_padding.dart';
import 'components/shared/glass_panel.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showResetConfirmation(BuildContext context, AppModel appModel) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, anim1, anim2) {
        return Selector<AppModel, AppTheme>(
          selector: (_, m) => m.theme,
          builder: (dialogContext, theme, child) => Center(
            child: Material(
              color: Colors.transparent,
              child: GlassPanel(
                borderRadius: 24,
                padding: const EdgeInsets.all(20),
                color: const Color(0x80201F1F),
                animation: anim1,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Reset Settings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE5E2E1),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Are you sure you want to reset all settings to their defaults?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFC3C8C2),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          // Cancel Button
                          Expanded(
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Container(
                                height: 46,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFC3C8C2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Reset Button
                          Expanded(
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                appModel.resetSettingsToDefaults();
                              },
                              child: Container(
                                height: 46,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F0),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x33000000),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Reset',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E211F),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1.drive(
            CurveTween(curve: Curves.easeOut),
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AppModel, AppTheme>(
      selector: (_, m) => m.theme,
      builder: (context, theme, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(gradient: theme.background),
            child: Stack(
              children: [
                // 1. Dot Grid Background
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: DotGridPainter(
                        color: theme.lightTile.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                ),

                // 2. Glowing Blur Backgrounds
                Positioned(
                  top: 150,
                  right: -50,
                  child: RepaintBoundary(
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.lightTile.withValues(alpha: 0.05),
                            blurRadius: 120,
                            spreadRadius: 30,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Scrollable Content
                Positioned.fill(
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        // Glassy App Bar
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => Navigator.pop(context),
                                child: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: theme.lightTile,
                                  size: 22,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (_scrollController.hasClients) {
                                    _scrollController.animateTo(
                                      0,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                },
                                behavior: HitTestBehavior.opaque,
                                child: const Text(
                                  'Settings',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE5E2E1),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Consumer<AppModel>(
                                builder: (context, appModel, child) =>
                                    CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () =>
                                      _showResetConfirmation(context, appModel),
                                  child: Icon(
                                    Icons.refresh_rounded,
                                    color: theme.lightTile,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            physics: const BouncingScrollPhysics(),
                            children: [
                              const AppThemePicker(),
                              const SizedBox(height: 24),
                              const PieceThemePicker(),
                              const SizedBox(height: 24),
                              Consumer<AppModel>(
                                builder: (context, appModel, child) =>
                                    Toggles(appModel),
                              ),
                              const SizedBox(height: 32),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Made with ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFC3C8C2),
                                    ),
                                  ),
                                  Icon(
                                    Icons.favorite_rounded,
                                    color: theme.lightTile,
                                    size: 13,
                                  ),
                                  const Text(
                                    ' by Paras Shenmare',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFC3C8C2),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              BottomPadding(),
                            ],
                          ),
                        ),
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
