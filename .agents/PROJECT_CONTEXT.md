# AI Chess App - Project Context

## Overview

A feature-rich chess application built with **Flutter** and **Flame**. Offers single-player (vs Stockfish AI) and two-player offline modes, with timed games, move history review, undo/redo, customizable boards and piece themes, sound, haptic feedback, and full game-save/resume support.

**Architecture**: MVVM via `provider`. `AppModel` (ChangeNotifier) is the ViewModel; `ChessBoard`, services, and data classes are the Model; `lib/views/` + `ChessGame` (Flame) are the View.

---

## Key Components

### 1. App Entry & State (`lib/model/`, `lib/main.dart`)

- **`lib/main.dart`**: Initializes preferences, preloads the active piece theme and Classic fallback synchronously, then loads remaining themes asynchronously (sequentially throttled: one at a time, 100ms gap, after a 3-second startup delay). Initializes AdMob in the background. Calls `PlayGamesService.instance.signInSilently()` and `InAppUpdateService.instance.checkForUpdate()` post-`runApp` on Android (non-blocking). Wraps `CupertinoApp` in a `ChangeNotifierProvider<AppModel>`.
- **`lib/model/app_model.dart`**: The central brain for state management, serving as the ViewModel. Manages settings, preloading flags, undo bank updates, and delegates timers, audio, and haptics. Communicates changes to the View and persists state using `GameStateStorage`. Exposes fields of `GameState` via proxy getters/setters. Exposes ELO mapping helper for difficulty levels.
- **`lib/model/game_state.dart`**: Pure domain Model layer holding game state parameters (`gameOver`, `stalemate`, `userWon`, `turn`, `moveMetaList`). Fully decoupled from UI logic.
- **`lib/model/user_preferences.dart`**: Handles saving and loading settings to local storage. Defines `PIECE_THEMES` constant, `hapticEnabled` preference, `enablePieceRotation` (auto-rotating pieces for Player 2 offline), and `timerMode` ('increment' or 'delay').
- **`lib/model/app_themes.dart`**: 8 board/UI themes (sorted alphabetically). Add new themes here in `themeList`.
- **`lib/model/player.dart`**: `Player` enum (`player1`, `player2`, `random`).

### 2. UI & Views (`lib/views/`)

- **`main_menu_view.dart`**: Game configuration (1P/2P, difficulty, time control, side selection). In 2P mode Player 1 can set their starting side (`selectedSideP1`). Shows "Resume" button if `GameStateStorage.hasSavedGame()` is true.
- **`chess_view.dart`**: Primary game screen. Hosts Flame board, move history panel, timers, and game controls. Reacts to `GameController` swaps (game restart) by re-initializing the Flame layer. Implements `WidgetsBindingObserver` for timer pause/resume on lifecycle changes. Triggers confetti on human win. Back button shows a **Leave Game dialog** (Save & Exit / Exit Without Saving / Cancel). Checks `promotionRequested` flag on each rebuild and shows `PromotionDialog` via `addPostFrameCallback`.
- **`settings_view.dart`**: Theme/piece pickers, toggles (Auto-Rotate Board, Auto-Rotate Pieces, Move Hints & Highlights, Notation, Undo/Redo, Move History, Sound, Haptic), and Achievements tile. Pickers are debounced 150ms. Has a `RepaintBoundary`-isolated dot grid + glow background. Reset button shows a confirmation dialog before calling `resetSettingsToDefaults()`.
- **`components/`**: Feature-scoped component subdirectories:
  - `chess_view/`: `PromotionDialog` (non-dismissible, `PopScope(canPop: false)`), `PromotionOption`, `ChessBoardWidget` (Flame↔Flutter bridge).
  - `chess_view/game_info_and_controls/`: `GameStatus` (replaces status text with a RESUME button when reviewing history), `TimerWidget`, `Timers`, `MoveList` (clickable history with 2-second press-to-copy using FToast), `UndoRedoButtons`, `RestartExitButtons`, `RoundedAlertButton`.
  - `main_menu_view/`: `GameOptions`, `MainMenuButtons`, and `game_options/` pickers (mode, difficulty, time limit, increment, timer mode, side).
  - `settings_view/`: `AppThemePicker`, `PieceThemePicker` (with 7-tap Easter egg + `FToast` countdown), `PiecePreview` (lightweight StatelessWidget), `Toggle`, `Toggles`.
  - `shared/`: `GlassPanel`, `RoundedButton`, `TextVariable`, `BottomPadding`.

### 3. Game Logic & Flame (`lib/logic/`)

- **`chess_game.dart`**: Flame `FlameGame` subclass — the rendering View layer. Handles board drawing (pre-built tile Rects, cached Paint objects), piece sprite animation, board/piece rotation animation (supporting both board rotation and piece rotation in offline 2P mode), and tap input routing. Delegates ALL game logic to `GameController` via thin proxy methods. Reads `AppModel` directly for rendering state (theme, hints, board inversion). Zero widget imports.
- **`game_controller.dart`**: The logic ViewModel. Orchestrates move execution, AI triggering (`_aiMove` via Stockfish or randomized blunders), undo/redo (`undoMove`, `undoTwoMoves`, `redoMove`, `redoTwoMoves`), and pawn promotion. For human promotion: calls `requestPromotion()` on `AppModel`, holds the turn (`changeTurn: false`), waits for user dialog choice, then calls `promote(type)`. For AI promotion: `board.push()` already embeds the type and calls `addPromotedPiece()`; the controller syncs meta and finalizes the turn without re-calling `addPromotedPiece()`. Intercepts moves at Levels 1 & 2 with a randomized blunder pass (60% and 25% random legal moves respectively) after a safety-checked thinking delay. Dispatches haptic feedback based on move outcome. Applies Fischer increment on turn end.
- **`chess_board.dart`**: Pure Model — the chess rules engine. Board state (`tiles[64]`, `player1Pieces`, etc.), `push`/`pop` for make/unmake moves (with incremental eval restore and Zobrist hash tracking), `movesForPiece`, `kingInCheck`, `kingInCheckmate`. No Flutter imports.
- **`chess_piece.dart`** & **`chess_constants.dart`**: `ChessPieceType` enum, `ChessPiece` model (with signed `value` and unsigned `materialValue`), and `PROMOTIONS` list.
- **`shared_functions.dart`**: Utility helpers — tile/coordinate conversions, `oppositePlayer`, `formatPieceTheme`, `pieceTypeToString`.
- **`move_calculation/`**: Move generation and validation support:
  - `move_classes/`: `Move`, `MoveMeta`, `MoveStackObject`, `MoveAndValue`, `Direction`.
  - `piece_square_tables.dart`: `squareValue()` for incremental board evaluation (used for undo/pop correctness in `ChessBoard`).
  - ~~`openings.dart`~~ — deleted (vestigial, had no effect on Stockfish play).
  - ~~`transposition_table.dart`~~ — deleted (unused after Stockfish replaced homebrew AI).
- **`stockfish_service.dart`**: Singleton wrapping the native Stockfish binary via UCI protocol. Performs the UCI handshake (`uci` + `isready` -> `readyok`) exactly once per engine instance using a shared `_uciReadyCompleter`. Maps difficulty 1–5 to strength limiting options (`UCI_LimitStrength` and `UCI_Elo` for levels 3–5 targeting 1200, 1600, 2000 ELO respectively) and Skill Level 0 for levels 1–2 (400 and 800 ELO). Translates castling between internal king-captures-rook representation and standard UCI notation (`e1g1`, `e1c1`, `e8g8`, `e8c8`).
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
