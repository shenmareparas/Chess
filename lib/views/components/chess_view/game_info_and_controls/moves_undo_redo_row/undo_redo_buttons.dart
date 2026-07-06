import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../logic/ad_service.dart';
import '../../../../../model/app_model.dart';
import '../../../shared/glass_panel.dart';
import 'rounded_icon_button.dart';

class UndoRedoButtons extends StatelessWidget {
  final AppModel appModel;

  bool get _undoEnabled {
    return appModel.gameController != null &&
        appModel.gameController!.board.moveStack.isNotEmpty &&
        (!appModel.playingWithAI ||
            appModel.gameController!.board.moveStack.length > 1);
  }

  bool get _redoEnabled {
    return appModel.gameController != null &&
        appModel.gameController!.board.redoStack.isNotEmpty &&
        (!appModel.playingWithAI ||
            appModel.gameController!.board.redoStack.length > 1);
  }

  UndoRedoButtons(this.appModel);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              RoundedIconButton(
                CupertinoIcons.arrow_counterclockwise,
                // Always provide a callback so tapping when out of undos
                // opens the ad dialog rather than doing nothing.
                onPressed: _undoEnabled ? () => _handleUndo(context) : null,
              ),
              // Undo bank badge — shows remaining free undos.
              if (_undoEnabled)
                Positioned(
                  top: 6,
                  right: 10,
                  child: _UndoBadge(count: appModel.availableUndos),
                ),
            ],
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: RoundedIconButton(
            CupertinoIcons.arrow_clockwise,
            onPressed: _redoEnabled ? () => _redo() : null,
          ),
        ),
      ],
    );
  }

  // ── Undo Handling ──

  /// Main entry-point for an undo request.
  ///
  /// - If the player still has free undos: execute the undo and decrement.
  /// - If the player has 0 undos: show a Cupertino dialog offering to watch an ad.
  void _handleUndo(BuildContext context) {
    if (appModel.availableUndos > 0) {
      _executeUndo();
      appModel.decrementUndo();
    } else {
      _showOutOfUndosDialog(context);
    }
  }

  /// Performs the actual undo move on the game board.
  void _executeUndo() {
    if (appModel.gameController != null) {
      if (appModel.playingWithAI) {
        appModel.gameController!.undoTwoMoves();
      } else {
        appModel.gameController!.undoMove();
      }
    }
  }

  // ── Out-of-Undos Dialog ──

  void _showOutOfUndosDialog(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, anim1, anim2) {
        final theme = appModel.theme;
        return Center(
          child: Material(
            color: Colors.transparent,
            child: GlassPanel(
              borderRadius: 32,
              padding: const EdgeInsets.all(28),
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
                        Icons.smart_display_rounded,
                        color: theme.lightTile,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Out of Undos',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE5E2E1),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'You\'ve used all your free undos for this game. Watch a short ad to earn 1 extra undo.',
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
                        // Watch Ad Button
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _requestAdUndo(context);
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
                                Icon(Icons.play_arrow_rounded,
                                    color: const Color(0xFF131313), size: 22),
                                const SizedBox(width: 6),
                                const Text(
                                  'Watch Ad',
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
                          onPressed: () => Navigator.of(dialogContext).pop(),
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

  /// Asks [AdService] to show a rewarded interstitial ad.
  /// On reward earned: grants an undo in the model, allowing the player
  /// to execute it manually when they are ready.
  void _requestAdUndo(BuildContext context) {
    AdService.instance.showRewardedUndoAd(
      onRewardEarned: () {
        // Grant the undo from the ad to the bank.
        appModel.grantUndoFromAd();
      },
      onAdNotAvailable: () {
        // Ad not ready yet (e.g. offline/loading failure) — grant the undo anyway to prevent the user from being stuck.
        appModel.grantUndoFromAd();
        _showAdNotReadyDialog(context);
      },
    );
  }

  void _showAdNotReadyDialog(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, anim1, anim2) {
        final theme = appModel.theme;
        return Center(
          child: Material(
            color: Colors.transparent,
            child: GlassPanel(
              borderRadius: 32,
              padding: const EdgeInsets.all(28),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Warning Luminous Icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: theme.darkTile.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFC5C5C).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFC5C5C).withValues(alpha: 0.15),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFFC5C5C),
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Ad Not Ready',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE5E2E1),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No ad is available right now. To keep you from getting stuck, we have granted you a free undo!',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFFC3C8C2),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            color: Color(0xFF131313),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
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
          scale: 0.95 + 0.05 * anim1.value,
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  // ── Redo ──

  void _redo() {
    if (appModel.gameController != null) {
      if (appModel.playingWithAI) {
        appModel.gameController!.redoTwoMoves();
      } else {
        appModel.gameController!.redoMove();
      }
    }
  }
}

// ── Undo Badge Widget ──

/// A small pill-shaped badge that displays the number of remaining undos.
/// Uses a warm amber colour when undos are available, switching to a grey
/// tone when the count hits zero to signal that an ad is required.
class _UndoBadge extends StatelessWidget {
  final int count;

  const _UndoBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final bool hasUndos = count > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: hasUndos
            ? const Color(0xFFFFB74D) // warm amber
            : const Color(0xFF78909C), // cool grey when empty
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color:
                (hasUndos ? const Color(0xFFFFB74D) : const Color(0xFF78909C))
                    .withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
