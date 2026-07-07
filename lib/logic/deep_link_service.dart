import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/cupertino.dart';

import '../logic/game_state_storage.dart';
import '../model/app_model.dart';
import '../views/chess_view.dart';

/// Listens for incoming deep links (both cold-start and warm-start) and
/// navigates to the appropriate screen.
///
/// Registered deep links:
///   chess://start  – start a fresh 1P vs AI game
///   chess://resume – resume the saved game (falls back to new game if none)
class DeepLinkService {
  final AppModel appModel;
  final GlobalKey<NavigatorState> navigatorKey;

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  DeepLinkService({
    required this.appModel,
    required this.navigatorKey,
  });

  /// Call once after [runApp] to start listening.
  Future<void> initialize() async {
    // Handle cold-start deep link (app was not running)
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      // Delay slightly to ensure the navigator is ready after first frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleUri(initialUri);
      });
    }

    // Handle warm-start deep links (app already running in background)
    _sub = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (_) {/* ignore link errors */},
    );
  }

  void _handleUri(Uri uri) {
    if (uri.scheme != 'chess') return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    switch (uri.host) {
      case 'start':
        _startNewGame(navigator);
        break;
      case 'resume':
        _resumeGame(navigator);
        break;
    }
  }

  void _startNewGame(NavigatorState navigator) {
    // Configure for 1P vs AI (keeps existing difficulty/side preferences)
    appModel.setPlayerCount(1);
    appModel.newGame();

    // Pop any existing routes back to root, then push ChessView
    navigator.popUntil((route) => route.isFirst);
    navigator.push(
      CupertinoPageRoute(
        builder: (_) => ChessView(appModel),
      ),
    );
  }

  Future<void> _resumeGame(NavigatorState navigator) async {
    final hasSaved = await GameStateStorage.hasSavedGame();

    navigator.popUntil((route) => route.isFirst);

    if (hasSaved) {
      navigator.push(
        CupertinoPageRoute(
          builder: (_) => ChessView(appModel, isResuming: true),
        ),
      );
    } else {
      // Graceful fallback: no saved game, start a fresh one instead
      _startNewGame(navigator);
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}
