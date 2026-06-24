import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


import '../../../logic/game_state_storage.dart';
import '../../../model/app_model.dart';
import '../../../model/app_themes.dart';
import '../../chess_view.dart';

class MainMenuButtons extends StatefulWidget {
  final AppModel appModel;

  MainMenuButtons(this.appModel);

  @override
  _MainMenuButtonsState createState() => _MainMenuButtonsState();
}

class _MainMenuButtonsState extends State<MainMenuButtons> {
  bool _hasSavedGame = false;

  @override
  void initState() {
    super.initState();
    _checkSavedGame();
  }

  void _checkSavedGame() async {
    final hasSaved = await GameStateStorage.hasSavedGame();
    if (mounted) {
      setState(() {
        _hasSavedGame = hasSaved;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.appModel.theme;

    return Container(
      width: double.infinity,
      child: Column(
        children: [
          if (_hasSavedGame) ...[
            _buildButton(
              label: 'Resume Game',
              isPrimary: false,
              theme: theme,
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) {
                      return ChessView(widget.appModel, isResuming: true);
                    },
                  ),
                ).then((_) => _checkSavedGame());
              },
            ),
            const SizedBox(height: 12),
          ],
          _buildButton(
            label: 'Start Game',
            isPrimary: true,
            theme: theme,
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) {
                    return ChessView(widget.appModel);
                  },
                ),
              ).then((_) => _checkSavedGame());
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
  }) {
    final primaryBg = theme.moveHint.withOpacity(1.0);
    final secondaryBg = theme.lightTile.withOpacity(0.12);
    final secondaryBorder = theme.lightTile;

    final isDark = ThemeData.estimateBrightnessForColor(isPrimary ? primaryBg : secondaryBg) == Brightness.dark;
    final textColor = isPrimary
        ? (isDark ? Colors.white : const Color(0xFF241A00))
        : theme.lightTile;

    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: isPrimary ? primaryBg : secondaryBg,
        borderRadius: BorderRadius.circular(30),
        border: isPrimary ? null : Border.all(color: secondaryBorder, width: 1.5),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: primaryBg.withOpacity(0.3),
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
              fontFamily: 'Inter',
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

