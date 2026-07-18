# Chess App - Project Context

## Overview

A feature-rich chess application built with **Flutter** and **Flame**. Offers single-player (vs Stockfish AI) and two-player offline modes, with timed games, move history review, undo/redo, customizable boards and piece themes, sound, haptic feedback, and full game-save/resume support.

**Architecture**: MVVM via `provider`. `AppModel` (ChangeNotifier) is the ViewModel; `ChessBoard`, services, and data classes are the Model; `lib/views/` + `ChessGame` (Flame) are the View.

---

## Key Components

### 1. App Entry & State (`lib/model/`, `lib/main.dart`)

- **`lib/main.dart`**: Initializes preferences, then calls `runApp()` immediately to show the splash logo on the first frame. Decodes essential piece images and audio asynchronously after `runApp()`, signaling `appModel.imagesReady` when complete. Remaining themes preload in the background sequentially (one image at a time, yielding to the event loop, 100ms gap, after a 3s delay). Initializes AdMob in the background. Calls `PlayGamesService.instance.signInSilently()` and `InAppUpdateService.instance.checkForUpdate()` (non-blocking).
- **`lib/model/app_model.dart`**: The central brain for state management, serving as the ViewModel. Manages settings, preloading flags (`imagesReady`), undo bank updates, and delegates timers, audio, and haptics. Persists state using `GameStateStorage`. `endGame()` accepts an optional `winner` to compute correct win/loss audio even when evaluated asynchronously after a turn change.
- **`lib/model/game_state.dart`**: Pure domain Model layer holding game state parameters (`gameOver`, `stalemate`, `userWon`, `turn`, `moveMetaList`). Fully decoupled from UI logic.
- **`lib/model/user_preferences.dart`**: Handles saving and loading settings to local storage. Defines `PIECE_THEMES` constant, `hapticEnabled` preference, `enablePieceRotation` (auto-rotating pieces for Player 2 offline), and `timerMode` ('increment' or 'delay').
- **`lib/model/app_themes.dart`**: 8 board/UI themes (sorted alphabetically). Add new themes here in `themeList`.
- **`lib/model/player.dart`**: `Player` enum (`player1`, `player2`, `random`).

### 2. UI & Views (`lib/views/`)

- **`main_menu_view.dart`**: Game configuration (1P/2P, difficulty, time control, side selection). In 2P mode Player 1 can set their starting side (`selectedSideP1`). Shows "Resume" button if `GameStateStorage.hasSavedGame()` is true.
- **`chess_view.dart`**: Primary game screen. Hosts Flame board, move history panel, timers, and game controls. Reacts to `GameController` swaps (game restart) by re-initializing the Flame layer. Implements `WidgetsBindingObserver` for timer pause/resume on lifecycle changes. Triggers confetti on human win (guarded by `_hasPlayedConfetti` state variable to prevent repeating on history review/rebuilds). Back button shows a **Leave Game dialog** (Save & Exit / Exit Without Saving / Cancel). Checks `promotionRequested` flag on each rebuild and shows `PromotionDialog` via `addPostFrameCallback`.
- **`settings_view.dart`**: Theme/piece pickers, toggles (Auto-Rotate Board, Auto-Rotate Pieces, Move Hints & Highlights, Notation, Undo/Redo, Move History, Sound, Haptic), and Achievements tile. Pickers are debounced 150ms. Has a `RepaintBoundary`-isolated dot grid + glow background. Reset button shows a confirmation dialog before calling `resetSettingsToDefaults()`.
- **`components/`**: Feature-scoped component subdirectories:
  - `chess_view/`: `PromotionDialog` (non-dismissible, `PopScope(canPop: false)`), `PromotionOption`, `ChessBoardWidget` (Flame↔Flutter bridge).
  - `chess_view/game_info_and_controls/`: `GameStatus` (replaces status text with a RESUME button when reviewing history), `TimerWidget`, `Timers`, `MovesUndoRedoRow` (main row layout), `RestartExitButtons`, `RoundedAlertButton`.
  - `chess_view/game_info_and_controls/moves_undo_redo_row/`: `MoveList` (clickable history with 2-second press-to-copy using FToast, auto-scrolling to center using dynamic item width measurements), `UndoRedoButtons`, `RoundedIconButton`.
  - `main_menu_view/`: `GameOptions`, `MainMenuButtons` (Start/Resume buttons show a progress spinner if `!imagesReady`), and `game_options/` pickers (mode, difficulty, time limit, increment, timer mode, side).
  - `settings_view/`: `AppThemePicker`, `PieceThemePicker` (with 7-tap Easter egg + `FToast` countdown), `PiecePreview` (lightweight StatelessWidget), `Toggle` (individual settings row), `Toggles` (collection of all settings toggles).
  - `shared/`: `GlassPanel`, `RoundedButton`, `TextVariable`, `BottomPadding`.

### 3. Game Logic & Flame (`lib/logic/`)

- **`chess_game.dart`**: Flame `FlameGame` subclass — the rendering View layer. Handles board drawing, piece sprite animation, rotation animation, and tap input routing. Delegates all game logic to `GameController`.
- **`game_controller.dart`**: The logic ViewModel. Orchestrates move execution, AI triggering, undo/redo, and pawn promotion. Applies a randomized blunder pass for difficulty levels 1 & 2 (with 60% and 25% chance of random legal moves respectively). Offloads CPU-heavy checkmate verification (`kingInCheckmate()`) to `CheckmateWorker` in a background isolate to keep UI frame times smooth. Gates AI moves with `!undoing` to resume play when undoing back onto the AI's turn. Reconstructs a clean controller on new/restored games, calling `dispose()` to tear down the background worker.
- **`checkmate_worker.dart`**: Hosts a warm background isolate spawned once in `GameController`'s constructor. Runs `checkmateIsolateEntry()` on a minimal serialized snapshot of the board without Isolate spawn overhead.
- **`checkmate_isolate.dart`**: Houses serialization models and logic to build a bare `ChessBoard.blank()` and compute checkmates inside the isolate worker.
- **`chess_board.dart`**: Pure Model — the chess rules engine. Board state, push/pop moves (with incremental eval restore and Zobrist hash tracking), `movesForPiece`, `kingInCheck`, `kingInCheckmate`. Has a `ChessBoard.blank()` constructor. `_kingInCheckAtTile()` uses `_pieceAttacksTile()` for zero allocations.
- **`chess_piece.dart`** & **`chess_constants.dart`**: `ChessPieceType` enum, `ChessPiece` model, and `PROMOTIONS` list.
- **`shared_functions.dart`**: Utility helpers — tile/coordinate conversions, `oppositePlayer`, `formatPieceTheme`, `pieceTypeToString`.
- **`move_calculation/`**: Move generation and validation support:
  - `move_classes/`: `Move`, `MoveMeta`, `MoveStackObject`, `MoveAndValue`, `Direction`.
  - `piece_square_tables.dart`: `squareValue()` for incremental board evaluation (used for undo/pop correctness in `ChessBoard`).
  - ~~`openings.dart`~~ — deleted (vestigial, had no effect on Stockfish play).
  - ~~`transposition_table.dart`~~ — deleted (unused after Stockfish replaced homebrew AI).
- **`stockfish_service.dart`**: Singleton wrapping the native Stockfish binary via UCI protocol. Performs the UCI handshake (`uci` + `isready` -> `readyok`) exactly once per engine instance using a shared `_uciReadyCompleter`. Once the engine is ready, it applies stability configurations: disables NNUE evaluation (`Use NNUE` = false) to prevent `SIGSEGV` errors in native memory, limits transposition table size (`Hash` = 16) to avoid OutOfMemory errors, and limits engine threads to 1 (`Threads` = 1) to avoid lock contention and ANRs. Standard output streams are filtered in release mode, logging only crucial lifecycle events under `kDebugMode` to protect platform channel bandwidth. Maps difficulty 1–2 to Skill Level 0 (depth 1, 100ms and depth 3, 200ms respectively), and difficulty 3–5 to strength-limiting options (`UCI_LimitStrength` = true and target `UCI_Elo` values of 1200, 1600, 2000 with 400ms, 800ms, and 1500ms search times). Translates castling between internal king-captures-rook representation and standard UCI notation (`e1g1`, `e1c1`, `e8g8`, `e8c8`).
- **`timer_service.dart`**: Per-player countdown timers with `pause()`/`resume()`. Supports `increment` (Fischer, added after turn) and `delay` (USCF Simple Delay, clock held for delay duration before decrementing). Fires `onExpired` callback when a player's clock hits zero.
- **`audio_service.dart`**: Pooled `AudioPool` for rapid move sounds; `FlameAudio.play` for game-end sounds. Respects `soundEnabled` preference.
- **`haptic_service.dart`**: Centralized haptic output. Methods: `selection()`, `light()`, `medium()`, `heavy()`, `vibrate()`, `warning()` (double-light), `doubleLight()`. Exposed on `AppModel` as `appModel.haptic`. **Never call `HapticFeedback.*` directly.**
- **`ad_service.dart`**: `google_mobile_ads` rewarded interstitial ("1 Ad = 1 Undo"). Gracefully grants the undo reward even on ad failure or offline. `grantUndoFromAd()` on AppModel adds 1 to the bank.
- **`game_state_storage.dart`**: Full game state persistence via SharedPreferences. Saves/restores player settings, move history, timer values, `timerMode`, `timerIncrement`, game-over flags, and undo bank. `hasSavedGame()` used by the main menu.
- **`play_games_service.dart`**: Google Play Games Services (Android only, disabled on iOS). Silent sign-in on startup. Hook points: `onGameStarted` → `AppModel.newGame`; `onPlayerWon` → `AppModel.endGame`; `onPawnPromotion` → `GameController.promote` (human only); `onCheckDelivered` → `GameController._moveCompletion` (human only). All calls are fire-and-forget.
- **`in_app_update_service.dart`**: Checks for Google Play Store flexible/immediate updates at startup. Errors caught silently.

### 4. Marketing & Screenshots (`screenshots_editor/`)

A local Next.js web tool for designing and exporting App Store (iOS) and Google Play (Android) screenshots. Supports custom slide layouts (`two-devices`, `three-devices`), thin concentric bezels (notch toggleable), film noise overlay, per-element horizontal/vertical alignment, stage snap-centering, and real-time auto-save to `screenshots_editor/app-store-screenshots.json`. Run with `bun dev` (or `npm run dev`) from within `screenshots_editor/`.

---

## Assets

- `assets/images/pieces/<theme>/` — Piece theme images. Folder name must match `formatPieceTheme(theme)` from `shared_functions.dart`. Currently: `classic`, `angular`, `8-bit`, `letters`, `oldschool`, `fairytale`.
- `assets/images/logo.png` — Home screen logo.
- `assets/audio/` — `piece_moved.mp3`, `win.wav`, `lose.wav`, `tie.wav`.
- `assets/font/` — `Inter-VariableFont_slnt,wght.ttf`.
- `assets/icons/` — App launcher icons.

---

## Navigation for AI Agents

| Task | Where to look |
|---|---|
| Global state / game lifecycle | `lib/model/app_model.dart` |
| Move execution / AI / undo | `lib/logic/game_controller.dart` |
| Chess rules / board state | `lib/logic/chess_board.dart` |
| Rendering / input | `lib/logic/chess_game.dart` |
| UI screens | `lib/views/` |
| Haptic feedback | `lib/logic/haptic_service.dart` (never `HapticFeedback.*` directly) |
| Game persistence | `lib/logic/game_state_storage.dart` + `AppModel.restoreGameState` |
| Themes | `lib/model/app_themes.dart` (board themes), `lib/model/user_preferences.dart` (piece themes) |
| Screenshot editor | `screenshots_editor/` — run `bun dev` to test |
