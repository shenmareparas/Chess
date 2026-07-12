import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: isPrimary ? primaryBg : secondaryBg,
        borderRadius: BorderRadius.circular(30),
        border:
            isPrimary ? null : Border.all(color: secondaryBorder, width: 1.5),
        boxShadow: isPrimary
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
        onPressed: onPressed,
        child: Center(
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
