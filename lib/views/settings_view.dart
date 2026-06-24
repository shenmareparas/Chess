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

class SettingsView extends StatelessWidget {
  const SettingsView({Key? key}) : super(key: key);

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
                padding: const EdgeInsets.all(28),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Reset Settings?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE5E2E1),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Are you sure you want to reset all settings to their defaults?',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFFC3C8C2),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Color(0xFFE5E2E1),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              color: theme.lightTile.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(12),
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                appModel.resetSettingsToDefaults();
                              },
                              child: const Text(
                                'Reset',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
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
        return Transform.scale(
          scale: 0.94 + 0.06 * anim1.value,
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
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
                  child: CustomPaint(
                    painter: DotGridPainter(
                      color: theme.lightTile.withValues(alpha: 0.04),
                    ),
                  ),
                ),

                // 2. Glowing Blur Backgrounds
                Positioned(
                  top: 150,
                  right: -50,
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
                              const Text(
                                'Settings',
                                style: TextStyle(
                                  fontFamily: 'Playfair Display',
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE5E2E1),
                                  letterSpacing: 0.5,
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
                          child: CupertinoScrollbar(
                            child: ListView(
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
                                        fontFamily: 'Inter',
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
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                BottomPadding(),
                              ],
                            ),
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
