import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../model/app_model.dart';
import '../../../chess_view.dart';
import '../../shared/glass_panel.dart';

class RestartExitButtons extends StatelessWidget {
  final AppModel appModel;

  const RestartExitButtons(this.appModel);

  void _showRestartConfirmation(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, anim1, anim2) {
        final theme = appModel.theme;
        return Center(
          child: Material(
            color: Colors.transparent,
            child: GlassPanel(
              borderRadius: 32,
              padding: const EdgeInsets.all(28),
              color: const Color(0x80201F1F),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Luminous Icon Header
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: theme.darkTile.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.lightTile.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.lightTile.withValues(alpha: 0.15),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.restart_alt_rounded,
                        color: theme.lightTile,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Restart Game?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE5E2E1),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Are you sure you want to restart? Your current game progress will be lost.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFFC3C8C2),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    Column(
                      children: [
                        // Restart Button
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            appModel.newGame();
                          },
                          child: Container(
                            width: double.infinity,
                            height: 54,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F0),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x20000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.restart_alt_rounded,
                                    color: const Color(0xFF131313), size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Restart',
                                  style: TextStyle(
                                    color: Color(0xFF131313),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Cancel Button
                        CupertinoButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFF8D928C),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
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
    final theme = appModel.theme;

    return Row(
      children: [
        // Restart Button
        Expanded(
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _showRestartConfirmation(context),
            child: GlassPanel(
              padding: EdgeInsets.zero,
              borderRadius: 14,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restart_alt_rounded,
                      color: theme.lightTile,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Restart',
                      style: TextStyle(
                        color: theme.lightTile,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Exit Button
        Expanded(
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              if (appModel.gameOver) {
                appModel.exitChessView();
                Navigator.pop(context);
              } else {
                showExitDialog(context);
              }
            },
            child: GlassPanel(
              padding: EdgeInsets.zero,
              borderRadius: 14,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFFC5C5C),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Exit',
                      style: TextStyle(
                        color: Color(0xFFFC5C5C),
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
