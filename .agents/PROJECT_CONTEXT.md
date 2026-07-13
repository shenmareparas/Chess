# AI Chess App - Project Context

## Overview

This is a feature-rich chess application built with **Flutter** and **Flame**.
It offers both single-player (vs AI) and two-player offline modes. The AI utilizes the world-class **Stockfish Chess Engine** (integrated via FFI) with 5 difficulty levels mapped to engine Skill Levels (3-20), search depths (3-16), and response time limits (150ms-2s). A custom Minimax algorithm serves as the fallback engine option.

## Key Components

### 1. App Entry & State

- **`lib/main.dart`**: Initializes settings (loading preferences first), preloads essential assets (the active piece theme, Classic theme, and the home screen logo) synchronously to speed up startup, launches remaining theme preloading asynchronously (sequentially throttled with a 100ms delay between themes, starting 3 seconds after boot) to protect main-thread frame metrics, initializes AdMob SDK in the background without blocking startup, and wraps the `CupertinoApp` with a `ChangeNotifierProvider` for `AppModel`. Also calls `PlayGamesService.instance.signInSilently()` and checks for Google Play Store updates on Android via `InAppUpdateService.instance.checkForUpdate()` post-`runApp` (non-blocking).
- **`lib/model/app_model.dart`**: The central brain for state management, notifying the UI of game state changes, theme changes, and settings. Manages the **undo bank** (`_availableUndos`, starts at 1 per game, earnable via ad), delegates timer control to `TimerService` (configuring time limit, increment, and `timerMode`), delegates audio to `AudioService`, and delegates haptics to `HapticService`. Also handles game save/restore lifecycle (`saveGameState` / `saveGameStateImmediate` / `restoreGameState` including `timerMode` / `timerIncrement` restoration) and two-player `selectedSideP1` configuration.
- **`lib/model/user_preferences.dart`**: Handles saving and loading settings to local storage. Defines `PIECE_THEMES` constant, `hapticEnabled` preference, and `timerMode` ('increment' or 'delay').
- **`lib/model/app_themes.dart`**: Specifies board and UI colors for all 8 themes (sorted alphabetically by name).
- **`lib/model/player.dart`**: Player enum (`player1`, `player2`, `random`) and base logic.

### 2. UI & Views (`lib/views/`)

- **`main_menu_view.dart`**: The starting screen to configure the game (1P/2P, difficulty, time control, side selection). In 2P mode, Player 1 can separately set their preferred starting side (`selectedSideP1`). The main menu also exposes a "Resume" button when a saved game exists (`GameStateStorage.hasSavedGame()`).
- **`chess_view.dart`**: The primary game interface displaying the Flame-rendered board, move history, captured pieces, and timers. Reacts dynamically to `GameController` swaps (e.g., on game restart) to re-initialize the Flame layer. Implements `WidgetsBindingObserver` to pause the timer on app background/inactive and resume it when foregrounded. Shows confetti on a human win. The back-button/swipe triggers a **Leave Game dialog** with three actions: "Save & Exit" (`saveAndExitChessView()`), "Exit Without Saving" (`exitChessView()`), and "Cancel" (resumes the timer).
- **`settings_view.dart`**: For customizing themes, sounds, and other UI preferences. Contains a `DotGridPainter` background and glowing blur blobs, both wrapped in `RepaintBoundary`. App bar includes a reset button that shows a glassmorphic confirmation dialog before calling `resetSettingsToDefaults()`. Integrates: `AppThemePicker`, `PieceThemePicker`, and `Toggles` (Board Rotation, Show Hints, Show Notation, Allow Undo/Redo, Show Move History, Sound, Haptic Feedback toggles) + an Achievements tappable tile.
- **`components/`**: Directory containing view-specific subcomponents and shared widgets, including:
  - `game_options/`: Mode selection, AI picker, time limit, time increment picker, and `timer_mode_picker.dart` (lets users choose between 'increment' / Fischer or 'delay' / Simple Delay when a time increment is active).
  - `chess_view/`: A glassmorphic `PromotionDialog` (wrapped in `PopScope(canPop: false)` to prevent accidental dismissals during games), and `timer_widget.dart` (which dynamically shows remaining delay on the active turn if `timerMode` is set to USCF delay).
  - `shared/`: `GlassPanel` shared UI containers. The piece preview uses a lightweight standard `PiecePreview` StatelessWidget with standard image caching rather than heavy Flame loops. `PieceThemePicker` contains a developer Easter egg that opens the `PromotionDialog` when the preview is tapped 7 times, showing `FToast` countdown toasts from the 4th tap.

### 3. Game Logic & Flame Integration (`lib/logic/`)

- **`chess_game.dart` & `game_controller.dart`**: Controls the flow of the game, turn switching, and game loop. `GameController` is responsible for move orchestration, AI triggering, undo/redo (including `undoTwoMoves` for AI games), pawn promotion, and dispatching haptic feedback via `AppModel.haptic` based on move outcome. Applies time increments on turn end if the timer mode is `increment`.
- **`chess_board.dart`**: Handles the board representation and rendering logic via Flame engine components.
- **`chess_piece.dart`** & **`chess_constants.dart`**: Define the piece type enum, piece model, and shared constants (e.g. the `PROMOTIONS` list used by both board logic and the promotion dialog).
- **`shared_functions.dart`**: Utility helpers shared across logic and views — tile-to-coordinate conversions, `oppositePlayer`, `formatPieceTheme`, and `pieceTypeToString`.
- **`move_calculation/`**: Contains the critical logic for move generation, validation (checks, stalemates), and the fallback Minimax algorithm with alpha-beta pruning, quiescence search, and iterative deepening.
- **`stockfish_service.dart`**: A singleton service wrapping the native Stockfish binary. Communicates using the UCI protocol via standard input/output channels and synchronizes ready states. Mapped to the selected game difficulty. Handles castling move translations between the custom chess board representation (where castling is modeled as a king capturing its own rook) and the standard UCI format expected by Stockfish (e.g. `e1g1`, `e1c1`).
- **`timer_service.dart`** & **`audio_service.dart`**: Independent services for game timers (with `pause()`/`resume()` support) and pooled sound effects (`AudioPool` for move sounds, `FlameAudio.play` for game-end sounds). `TimerService` supports both `increment` (Fischer) and `delay` (USCF Simple Delay) modes, managing player clocks and delay countdowns.
- **`in_app_update_service.dart`**: Service utilizing `in_app_update` for Google Play Store updates on Android. Checks for flexible or immediate updates. Safe JVM compilation (version 17) is enforced across project builds.
- **`haptic_service.dart`**: Centralized haptic feedback service. Wraps Flutter's `HapticFeedback` APIs and honours the user's `hapticEnabled` setting. Methods: `selection()`, `light()`, `medium()`, `heavy()`, `vibrate()`. Exposed on `AppModel` as `appModel.haptic`. Never call `HapticFeedback.*` directly — always use this service.
- **`ad_service.dart`**: Integrates `google_mobile_ads` for rewarded interstitial ads ("1 Ad = 1 Undo"). Implements fallback mechanisms that grant the undo reward even when offline or upon ad display failures (`onAdFailedToShowFullScreenContent`). Each new game gives 1 free undo; `grantUndoFromAd()` on `AppModel` adds 1 more.
- **`game_state_storage.dart`**: Logic for managing full game state persistence via SharedPreferences. Saves and restores player settings, move history, timer durations, game-over/stalemate flags, `timerIncrement`, `timerMode`, and the available undo count. `hasSavedGame()` is used by the main menu to show/hide the Resume button.
- **`play_games_service.dart`**: Wraps `games_services` to integrate Google Play Games Services (Android) achievements (completely disabled on iOS and web). Handles startup silent sign-in and on-demand interactive achievements UI launcher. Hooked into `AppModel.newGame` (`onGameStarted`), `AppModel.endGame` (`onPlayerWon`), and `GameController.promote`/`_moveCompletion` (`onPawnPromotion`, `onCheckDelivered`). Tracks incremental "Play 10 / Play 50 Games" achievements via `GamesServices.increment`. All calls are fire-and-forget and degrade silently when the service is unavailable.

### 4. Marketing & Screenshots (`screenshots_editor/`)

- **`screenshots_editor/`**: A Next.js-based local web tool for designing and exporting App Store (iOS) and Google Play Store (Android) screenshots.
  - Automatically loads slide-specific game themes (Forest Mint, Midnight Slate, etc.).
  - Configured with custom thin bezel layouts, concentric rounded corners, and layouts (`two-devices`, `three-devices`).
  - Supports premium background overlays (adjustable film noise opacity) and camera notch bezel toggle settings.
  - Supports horizontal & vertical alignment (both custom text elements and slide headlines) and stage snap-centering actions.
  - Auto-saves layout configurations in real-time to `screenshots_editor/app-store-screenshots.json`.

## Assets

- Images are located in `assets/images` (with piece subdirectories per theme).
- Audio effects are in `assets/audio` (`piece_moved.mp3`, `win.wav`, `lose.wav`, `tie.wav`).
- Fonts (`Inter`) are in `assets/font`.
- App launcher icons are in `assets/icons`.

## Important Note to AI

This context provides a high-level map of the codebase to assist in making localized or architectural changes without breaking existing features. If you are modifying UI look in `views/` and `model/`. If modifying how pieces move or AI difficulty, look inside `logic/`. If modifying haptic feedback patterns, use `HapticService` — never `HapticFeedback.*` directly. If modifying game persistence, change `game_state_storage.dart` and update `AppModel.restoreGameState`.
If you need to make changes to the app store screenshot generator, modify the Next.js code under `screenshots_editor/` and run `bun dev` to test it.
