# AI Coding Guidelines for AI Chess Flutter App

You are an AI coding assistant working on the "AI Chess" Flutter application.
Please adhere to the following guidelines:

## Technologies & Architecture

- **Framework**: Flutter (Dart >= 3.0.0)
- **State Management**: `provider` (App state in `lib/model/app_model.dart`)
- **Game Engine**: `flame` (used for 2D chess board rendering in `lib/logic/`)
- **UI Toolkit**: `Cupertino` widgets are primarily used (see `lib/main.dart` and `lib/views/`)
- **Data Persistence**: `shared_preferences` (settings, themes, undo/redo configs)
- **Audio & Effects**: `flame_audio` for game sounds and `confetti` for celebratory UI effects
- **Ads**: `google_mobile_ads` is wrapped by `lib/logic/ad_service.dart`
- **Typography**: The app uses the Inter font from `assets/font/`

## Directory Structure

- `lib/model/`: Contains `app_model.dart`, `app_themes.dart`, `player.dart`, `user_preferences.dart`. Modify these for state or theme changes.
- `lib/logic/`: Core game mechanics. Includes `chess_board.dart`, `chess_game.dart`, `game_controller.dart`, `chess_piece.dart`, `chess_constants.dart`, `shared_functions.dart`, `move_calculation/`, `timer_service.dart`, `audio_service.dart`, `haptic_service.dart`, `ad_service.dart`, `game_state_storage.dart`, `play_games_service.dart`, and Flame Sprite logic (`chess_piece_sprite.dart`).
- `lib/logic/move_calculation/`: Move validation, AI search, openings, move classes, piece-square tables, and transposition table support.
- `lib/views/`: UI screens (`main_menu_view.dart`, `chess_view.dart`, `settings_view.dart`) and components (`components/`).
- `lib/views/components/shared/`: Shared UI primitives such as `glass_panel.dart`, `rounded_button.dart`, and text/padding helpers.
- `assets/images/pieces/`: Piece theme image folders. The folder name must match `formatPieceTheme(theme)` from `lib/logic/shared_functions.dart`.

## Rules

1. **State Management**: Any global state changes must happen via `AppModel`. Do not use `setState` for global app state.
2. **Game Logic Updates**: Changes to standard chess rules or AI should be contained in `lib/logic/`. AI moves are handled by the native Stockfish engine wrapped inside `StockfishService`.
3. **App Themes**: Add board/app themes in `themeList` within `lib/model/app_themes.dart`. Theme names are sorted before display.
4. **Piece Themes & Preview**: When adding a new piece theme, register it in `PIECE_THEMES` in `lib/model/user_preferences.dart`, add assets under `assets/images/pieces/<formatted_theme_name>/`, and update `pubspec.yaml`. Note that `main.dart` preloads only the active and Classic fallback themes at startup while loading the rest asynchronously in the background in a sequential, throttled manner (one theme at a time with a 100ms pause, after a 3-second startup delay) to optimize startup performance. Settings screen piece previews must use the lightweight `PiecePreview` StatelessWidget to avoid Flame GameWidget initialization overhead.
5. **Settings UI**: Keep the app theme and piece theme pickers visually consistent. Selected picker rows use a subtle fill without an outline border. Both CupertinoPickers are cached outside reactive builder loops and debounced by 150ms to prevent intermediate frame jank during fast scrolling. The settings screen also contains: Board Rotation (2P), Show Hints, Show Notation, Allow Undo/Redo, Show Move History, Sound, Haptic Feedback toggles, and a tappable Achievements tile.
6. **Formatting & Analysis**: Run `dart format` on changed Dart files and `flutter analyze` before handing off.
7. **No Destructive Overrides**: Do not remove core AI features (Undo/Redo, Timers, Difficulty Levels) unless explicitly requested. Currently supports 5 difficulty levels mapped to Stockfish skill levels (0-20), search depths (3-16), and move thinking times in `StockfishService`.
8. **Performance & Rendering**: Use `RepaintBoundary` and isolate rebuilds via `Selector` for heavy drawing/custom paint components (like the chess board background `_ChessBackground`, main menu backgrounds, and settings page dot grids or radial blurs).
9. **Stockfish Engine Lifecycle**: Ensure the native Stockfish instance is initialized on demand, synchronized using the `readyok` response before sending commands, and disposed of correctly in the `AppModel`'s `dispose()` method to avoid process leaks and isolate crashes.
10. **State Saving & Debouncing**: Game state saving (`saveGameState`) is debounced (400ms) to limit disk writes. Use `saveGameStateImmediate` for critical lifecycle events (e.g. app pause or close) where writes must complete synchronously. Similarly, picker state updates are debounced (150ms) to prevent UI rebuild overhead during active user scrolls.
11. **Game Restart Reactive Handling**: When game controllers are swapped or restarted, `ChessView` automatically detects the controller change and recreates the rendering Flame layer to prevent canvas state desyncs.
12. **Ad Reward & Fallback Handling**: Rewarded ads (e.g., for granting undos) must degrade gracefully. If an ad fails to display (`onAdFailedToShowFullScreenContent`) or is unavailable/offline, the reward is granted anyway so the player is never blocked/stuck. Additionally, rewards like undos should be granted to the model allowing the player to manually execute them, rather than auto-executing. Each new game starts the player with 1 free undo (`_availableUndos = 1`); watching an ad grants 1 more via `grantUndoFromAd()`.
13. **Marketing Screenshot Customizations**: If layout changes, custom branding, or styling are requested for app store screenshots, use the Next.js app in `screenshots_editor/`. Maintain diverse slide layouts, keep device bezels thinned and concentric (without camera dots by default, but toggleable in global settings), and ensure changes auto-save back to `screenshots_editor/app-store-screenshots.json`. Support custom text and headline horizontal/vertical alignment parameters and stage snap-centering actions.
14. **Promotion Dialog & Easter Egg**: Inside games, the `PromotionDialog` is non-dismissible via back gestures/system buttons using `PopScope(canPop: false)`. A developer Easter egg is implemented in `PieceThemePicker` which displays the dialog when the piece preview is tapped 7 times. It shows an instantly-responsive, glassmorphic countdown toast using `FToast` starting from the 4th tap.
15. **Play Games Services (Achievements)**: `PlayGamesService` (singleton in `lib/logic/play_games_service.dart`) wraps Google Play Games Services (Android) and is disabled on iOS. Silent sign-in (`signInSilently`) is called once in `main()` after `runApp` (non-blocking) on Android to log in returning returning users silently. On-demand interactive sign-in and Native UI display is handled by tapping the Achievements setting tile (`showAchievements()`), which is hidden on iOS. Hook into the correct lifecycle call-sites: `onGameStarted` from `AppModel.newGame`, `onPlayerWon` from `AppModel.endGame`, `onPawnPromotion` from `GameController.promote` (human player only), and `onCheckDelivered` from `GameController._moveCompletion` (human player only). All calls are fire-and-forget — errors are swallowed silently so GPGS outages never block gameplay.
16. **Haptic Feedback**: All haptic output is routed through `HapticService` (`lib/logic/haptic_service.dart`), exposed on `AppModel` as `appModel.haptic`. Use `haptic.selection()` for piece selection, `haptic.light()` for normal moves and preference changes, `haptic.medium()` for captures and checks, `haptic.heavy()` for stalemates, and `haptic.vibrate()` for checkmates. The service honours the `hapticEnabled` preference and is a no-op when disabled. Never call `HapticFeedback.*` directly from views or game logic — always go through `HapticService`.
17. **Game Save & Resume**: `GameStateStorage` persists the full game state (player settings, move history, timer values, and undo bank) to SharedPreferences. `saveGameState()` (debounced 400ms) is called after each move; `saveGameStateImmediate()` is called on app lifecycle pause/inactive. `restoreGameState()` in `AppModel` replays the saved moves to reconstruct board state. The `ChessView` passes `isResuming: true` when navigating to a resumed game, which triggers `restoreGameState()` instead of `newGame()`.

