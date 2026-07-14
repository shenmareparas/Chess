# AI Coding Guidelines for AI Chess Flutter App

You are an AI coding assistant working on the "AI Chess" Flutter application.
Please adhere to the following guidelines:

## Technologies & Architecture

- **Framework**: Flutter (Dart >= 3.0.0)
- **Architecture**: MVVM via `provider`. `AppModel` (ChangeNotifier) is the ViewModel; `ChessBoard` and services are the Model; `lib/views/` + `ChessGame` (Flame) are the View.
- **State Management**: `provider` — all global state lives in `lib/model/app_model.dart`
- **Game Engine**: `flame` — 2D board rendering in `lib/logic/chess_game.dart`
- **AI Engine**: Native Stockfish binary via `stockfish` Dart FFI package, wrapped by `lib/logic/stockfish_service.dart`
- **UI Toolkit**: Cupertino widgets primarily (see `lib/main.dart` and `lib/views/`)
- **Data Persistence**: `shared_preferences` via `UserPreferences` and `GameStateStorage`
- **Audio & Effects**: `flame_audio` for game sounds; `confetti` for win celebration
- **Ads**: `google_mobile_ads` wrapped by `lib/logic/ad_service.dart`
- **In-App Updates**: `in_app_update` wrapped by `lib/logic/in_app_update_service.dart`
- **Typography**: Inter font from `assets/font/`

## Directory Structure

- `lib/model/`: `app_model.dart` (ViewModel/ChangeNotifier), `game_state.dart` (pure game data Model), `app_themes.dart`, `player.dart`, `user_preferences.dart`.
- `lib/logic/`: `chess_board.dart` (Model — pure rules engine), `chess_game.dart` (View — Flame rendering), `game_controller.dart` (logic ViewModel), `chess_piece.dart`, `chess_constants.dart`, `shared_functions.dart`, `stockfish_service.dart`, `timer_service.dart`, `audio_service.dart`, `haptic_service.dart`, `ad_service.dart`, `in_app_update_service.dart`, `game_state_storage.dart`, `play_games_service.dart`, `chess_piece_sprite.dart`.
- `lib/logic/move_calculation/`: Move generation/validation support. Contains `move_classes/` (Move, MoveMeta, MoveStackObject, MoveAndValue, Direction) and `piece_square_tables.dart` (incremental eval for undo correctness). **No openings.dart or transposition_table.dart — those were deleted.**
- `lib/views/`: UI screens (`main_menu_view.dart`, `chess_view.dart`, `settings_view.dart`) and `components/`.
- `lib/views/components/shared/`: `GlassPanel`, `RoundedButton`, `TextVariable`, `BottomPadding`.
- `assets/images/pieces/<theme>/`: Piece theme folders. Name must match `formatPieceTheme(theme)` in `shared_functions.dart`.

## Rules

1. **State Management**: All global state changes go through `AppModel`. Do not use `setState` for global app state. Do not access `GameController` fields from views — read from `AppModel`.
2. **Game Logic**: Changes to chess rules or move generation stay in `lib/logic/chess_board.dart`. AI move handling stays in `StockfishService` and `GameController._aiMove`. Do not add a new homebrew AI — use Stockfish.
3. **App Themes**: Add board/UI themes in `themeList` in `lib/model/app_themes.dart`. Theme names are sorted before display.
4. **Piece Themes & Preview**: Register new themes in `PIECE_THEMES` in `lib/model/user_preferences.dart`, add assets under `assets/images/pieces/<formatted_name>/`, and update `pubspec.yaml`. `main.dart` preloads only the active and Classic themes synchronously; the rest load asynchronously (one at a time, 100ms gap, 3s startup delay). Settings screen previews **must** use the lightweight `PiecePreview` StatelessWidget — never a Flame `GameWidget`.
5. **Settings UI**: App and piece theme pickers are cached outside reactive builder loops and debounced 150ms. Selected rows use subtle fill, no outline border. Settings toggles: Board Rotation (2P), Show Hints, Show Notation, Allow Undo/Redo, Show Move History, Sound, Haptic Feedback, and an Achievements tile.
6. **Formatting & Analysis**: Run `dart format` on changed Dart files and `flutter analyze` before handing off. Both must be clean (0 issues).
7. **No Destructive Overrides**: Do not remove core features (Undo/Redo, Timers, Difficulty, game save/resume) unless explicitly requested. Supports 5 difficulty levels mapped to Stockfish skill (3–20), search depth (3–16), and move time (150ms–2s).
8. **Performance & Rendering**: Use `RepaintBoundary` to isolate expensive painters (`_ChessBackground`, dot grids, glow blobs). Use `Selector<AppModel, T>` (not `Consumer`) for widgets that only depend on a narrow slice of state.
9. **Stockfish Lifecycle**: Initialize on demand, synchronize with `readyok`, dispose in `AppModel.dispose()`. Use `CancelableOperation` to cancel in-flight AI requests on game reset.
10. **State Saving & Debouncing**: `saveGameState` is debounced 400ms. Use `saveGameStateImmediate` for lifecycle events (app pause/close). Picker scroll updates are debounced 150ms.
11. **Game Restart Reactive Handling**: `ChessView` detects `GameController` swaps and re-initializes the Flame layer. Do not try to reuse a stale `ChessGame` instance.
12. **Ad Reward & Fallback**: Rewarded ads (1 Ad = 1 Undo) must degrade gracefully. Grant the undo even on ad failure or offline. `grantUndoFromAd()` adds to the undo bank; do not auto-execute the undo. Each new game starts with 1 free undo.
13. **Marketing Screenshots**: Modify the Next.js app in `screenshots_editor/`. Run `bun dev` (or `npm run dev`) to test. Auto-saves to `screenshots_editor/app-store-screenshots.json`. Supports `two-devices` / `three-devices` layouts, thin concentric bezels, notch toggle, per-element alignment, and stage snap-centering.
14. **Promotion Dialog & Easter Egg**: `PromotionDialog` is non-dismissible (`PopScope(canPop: false)`). The developer Easter egg in `PieceThemePicker` shows it after 7 taps on the piece preview, with `FToast` countdown toasts from tap 4.
15. **Pawn Promotion — Critical Flow**:
    - **Human**: `movePiece()` calls `board.push()` with the placeholder `ChessPieceType.promotion` → `requestPromotion()` flags UI → turn NOT changed yet → dialog shown → user picks type → `GameController.promote(type)` mutates MSO, calls `addPromotedPiece()`, changes turn.
    - **AI (Stockfish)**: Move arrives with `promotionType` already set (e.g. `queen`) → `board.push(move)` already calls `_promote()` + `addPromotedPiece()` → `_moveCompletion(changeTurn: false)` → **only sync meta + call `_moveCompletion` to change turn**. Do NOT call `GameController.promote()` for AI promotions — it would double-add the piece to `queensForPlayer`/`rooksForPlayer`.
16. **Play Games Services**: `PlayGamesService` is Android-only (disabled on iOS). Hook points: `onGameStarted` from `AppModel.newGame`, `onPlayerWon` from `AppModel.endGame`, `onPawnPromotion` from `GameController.promote` (human only), `onCheckDelivered` from `GameController._moveCompletion` (human only). All fire-and-forget, errors swallowed silently.
17. **Haptic Feedback**: Route all haptic output through `HapticService` (exposed as `appModel.haptic`). `selection()` for piece selection, `light()` for normal moves/preference changes, `medium()` for captures and checks (opponent), `heavy()` for stalemates and check (human), `vibrate()` for checkmates, `warning()` for no-valid-moves, `doubleLight()` for castles. **Never call `HapticFeedback.*` directly.**
18. **Game Save & Resume**: `GameStateStorage` saves full state to SharedPreferences. `restoreGameState()` in `AppModel` replays moves to reconstruct board. `ChessView` passes `isResuming: true` to trigger restore instead of `newGame()`.
19. **Time Controls**: `increment` = Fischer (added after turn ends). `delay` = USCF Simple Delay (clock held for delay duration before decrementing). `TimerService` handles both. Active delay is displayed visually on the active player's `TimerWidget`.
20. **In-App Update Lifecycle**: `InAppUpdateService.checkForUpdate()` called async in `main()` after `runApp`. Errors caught silently. Safe on sideloaded/debug builds.
21. **JVM Target & Kotlin Compatibility**: JVM target version `17` must be aligned across the main app and all subproject Kotlin/Java compilation tasks in `android/build.gradle`.
22. **R8 Minification & Native Library Compression**: Release builds use `minifyEnabled`, `shrinkResources`, `proguard-rules.pro` (`-dontwarn com.google.android.play.core.**`, `-keep class **.*stockfish*.** { *; }`). Native `.so` libs use `useLegacyPackaging = true`.
23. **Stockfish Castling Translation**: Internal board models castling as king capturing its own rook (`Move(60, 63)`). Translate to/from standard UCI notation (`e1g1`, `e1c1`, `e8g8`, `e8c8`) in `StockfishService.msoToUCI` and `_uciToMove`.
24. **Board Layout & Notation**: Flat, edge-to-edge board — no rounded corners or shadows. `_NotationOverlay` uses alternating tile colors (light tile color text on dark tiles, dark tile color text on light tiles) for contrast.
25. **Interactive Move History**: `MoveList` moves are tappable. Sets `historyViewIndex` on `AppModel`, rewinds board, pauses AI (timers keep running), disables board input. Navigation row: left/right chevrons + centered 56px glass play button, all in `ExcludeSemantics`. Active tile auto-scrolls to center. 2-second press-and-hold copies all moves to clipboard + shows 4-second toast.
