import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../logic/ad_service.dart';
import '../../../../../model/app_model.dart';
import '../../../shared/rounded_button.dart';
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
      barrierColor: Colors.black.withValues(alpha: 0.5),
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 340),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: appModel.theme.background,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Out of Undos',
                    style: TextStyle(
                      fontSize: 28,
                      fontFamily: 'Jura',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'You\'ve used all your free undos for this game. Watch a short ad to earn 1 extra undo.',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Jura',
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  RoundedButton(
                    'Watch Ad',
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _requestAdUndo(context);
                    },
                  ),
                  const SizedBox(height: 12),
                  RoundedButton(
                    'Cancel',
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
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

  /// Asks [AdService] to show a rewarded interstitial ad.
  /// On reward earned: grants an undo in the model, then immediately
  /// executes the undo so the experience feels seamless.
  void _requestAdUndo(BuildContext context) {
    AdService.instance.showRewardedUndoAd(
      onRewardEarned: () {
        // Grant the undo from the ad to the bank.
        appModel.grantUndoFromAd();
      },
      onAdNotAvailable: () {
        // Ad not ready yet — inform the player gracefully.
        _showAdNotReadyDialog(context);
      },
    );
  }

  void _showAdNotReadyDialog(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 340),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: appModel.theme.background,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFF78909C), // cool grey
                    size: 48,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Ad Not Ready',
                    style: TextStyle(
                      fontSize: 28,
                      fontFamily: 'Jura',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'No ad is available right now. Please try again in a moment.',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Jura',
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  RoundedButton(
                    'OK',
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
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
          fontFamily: 'Jura',
        ),
      ),
    );
  }
}
