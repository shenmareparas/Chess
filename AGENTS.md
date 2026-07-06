# AI Coding Guidelines for Chess Flutter App

You are an AI coding assistant working on the "Chess" Flutter application.
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
- `lib/logic/`: Core game mechanics. Includes `chess_board.dart`, `chess_game.dart`, `game_controller.dart`, `move_calculation/`, `timer_service.dart`, `audio_service.dart`, `ad_service.dart`, `game_state_storage.dart`, and Flame Sprite logic (`chess_piece_sprite.dart`).
- `lib/logic/move_calculation/`: Move validation, AI search, openings, move classes, piece-square tables, and transposition table support.
- `lib/views/`: UI screens (`main_menu_view.dart`, `chess_view.dart`, `settings_view.dart`) and components (`components/`).
- `lib/views/components/shared/`: Shared UI primitives such as `glass_panel.dart`, `rounded_button.dart`, and text/padding helpers.
- `assets/images/pieces/`: Piece theme image folders. The folder name must match `formatPieceTheme(theme)` from `lib/logic/shared_functions.dart`.

## Rules

1. **State Management**: Any global state changes must happen via `AppModel`. Do not use `setState` for global app state.
2. **Game Logic Updates**: Changes to standard chess rules or AI should be contained in `lib/logic/`. Ensure Minimax depth evaluation and alpha-beta pruning is not broken when modifying `move_calculation/`.
3. **App Themes**: Add board/app themes in `themeList` within `lib/model/app_themes.dart`. Theme names are sorted before display.
4. **Piece Themes**: When adding a new piece theme, register it in `PIECE_THEMES` in `lib/model/user_preferences.dart`, add assets under `assets/images/pieces/<formatted_theme_name>/`, update `pubspec.yaml`, and ensure `main.dart` preloads the images through Flame. Ensure new custom assets are trimmed of transparent padding and padded to perfect squares to prevent layout scaling and stretching issues.
5. **Settings UI**: Keep the app theme and piece theme pickers visually consistent. Selected picker rows use a subtle fill without an outline border.
6. **Formatting & Analysis**: Run `dart format` on changed Dart files and `flutter analyze` before handing off.
7. **No Destructive Overrides**: Do not remove core AI features (Undo/Redo, Timers, Difficulty Levels) unless explicitly requested. Currently supports 5 difficulty levels.
8. **Performance & Rendering**: Use `RepaintBoundary` and isolate rebuilds via `Selector` for heavy drawing/custom paint components (like the chess board background `_ChessBackground`).
9. **AI Search & GC Pressure**: Re-use Transposition Table structures during Minimax evaluations rather than re-allocating them on every search. Use `softClear()` to invalidate stale entries without releasing/reallocating the backing lists.
10. **State Saving & Debouncing**: Game state saving (`saveGameState`) is debounced (400ms) to limit disk writes. Use `saveGameStateImmediate` for critical lifecycle events (e.g. app pause or close) where writes must complete synchronously.
11. **Game Restart Reactive Handling**: When game controllers are swapped or restarted, `ChessView` automatically detects the controller change and recreates the rendering Flame layer to prevent canvas state desyncs.

