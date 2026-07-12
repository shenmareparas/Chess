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
        return Center(
          child: Material(
            color: Colors.transparent,
            child: GlassPanel(
              borderRadius: 24,
              padding: const EdgeInsets.all(20),
              color: const Color(0x80201F1F),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Restart Game?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE5E2E1),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Are you sure you want to restart? Your current game progress will be lost.',
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
                        // Restart Button
                        Expanded(
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              appModel.newGame();
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
                                'Restart',
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
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: anim1.drive(
            Tween<double>(begin: 0.94, end: 1.0).chain(
              CurveTween(curve: Curves.easeOutCubic),
            ),
          ),
          child: FadeTransition(
            opacity: anim1.drive(
              Tween<double>(begin: 0.0, end: 1.0).chain(
                CurveTween(curve: Curves.easeOut),
              ),
            ),
            child: RepaintBoundary(child: child),
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
