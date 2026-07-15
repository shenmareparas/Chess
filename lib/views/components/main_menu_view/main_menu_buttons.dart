import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/app_model.dart';
import '../../../model/app_themes.dart';
import '../../chess_view.dart';

class MainMenuButtons extends StatelessWidget {
  final AppModel appModel;
  final bool hasSavedGame;
  final VoidCallback onGameReturned;
  final VoidCallback? onResetScroll;

  const MainMenuButtons(
    this.appModel, {
    Key? key,
    required this.hasSavedGame,
    required this.onGameReturned,
    this.onResetScroll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = appModel.theme;
    // Rebuild only when imagesReady flips — avoids unnecessary rebuilds from
    // other AppModel changes (move meta, timers, etc.)
    final imagesReady = Selector<AppModel, bool>(
      selector: (_, m) => m.imagesReady,
      builder: (context, ready, _) => _buildButtons(context, theme, ready),
    );
    return imagesReady;
  }

  Widget _buildButtons(BuildContext context, AppTheme theme, bool ready) {
    return Container(
      width: double.infinity,
      child: Column(
        children: [
          if (hasSavedGame) ...[
            _buildButton(
              label: 'Resume Game',
              isPrimary: false,
              theme: theme,
              secondaryAlpha: 0.45,
              ready: ready,
              onPressed: () {
                appModel.haptic.light();
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) {
                      return ChessView(appModel, isResuming: true);
                    },
                  ),
                ).then((_) {
                  onGameReturned();
                });
                Future.delayed(
                  const Duration(milliseconds: 300),
                  () => onResetScroll?.call(),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
          _buildButton(
            label: 'Start Game',
            isPrimary: true,
            theme: theme,
            ready: ready,
            onPressed: () {
              appModel.haptic.light();
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) {
                    return ChessView(appModel);
                  },
                ),
              ).then((_) {
                onGameReturned();
              });
              Future.delayed(
                const Duration(milliseconds: 300),
                () => onResetScroll?.call(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required bool isPrimary,
    required AppTheme theme,
    required VoidCallback onPressed,
    required bool ready,
    double secondaryAlpha = 0.12,
  }) {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final resolvedAlpha =
        isAndroid ? (secondaryAlpha * 1.6).clamp(0.0, 0.9) : secondaryAlpha;

    final primaryBg = theme.moveHint.withValues(alpha: 1.0);
    final secondaryBg = theme.lightTile.withValues(alpha: resolvedAlpha);
    final secondaryBorder = theme.lightTile;

    final isDark = ThemeData.estimateBrightnessForColor(
            isPrimary ? primaryBg : secondaryBg) ==
        Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF241A00);
    final disabledTextColor = textColor.withValues(alpha: 0.45);

    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: isPrimary
            ? primaryBg.withValues(alpha: ready ? 1.0 : 0.55)
            : secondaryBg,
        borderRadius: BorderRadius.circular(30),
        border:
            isPrimary ? null : Border.all(color: secondaryBorder, width: 1.5),
        boxShadow: (isPrimary && ready)
            ? [
                BoxShadow(
                  color: primaryBg.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        // Null onPressed disables the button visually and functionally.
        onPressed: ready ? onPressed : null,
        child: Center(
          child: ready
              ? Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                )
              : SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: disabledTextColor,
                  ),
                ),
        ),
      ),
    );
  }
}
