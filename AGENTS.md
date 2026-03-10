# AI Coding Guidelines for Chess Flutter App

You are an AI coding assistant working on the "Chess" Flutter application.
Please adhere to the following guidelines:

## Technologies & Architecture
- **Framework**: Flutter (Dart >= 3.0.0)
- **State Management**: `provider` (App state in `lib/model/app_model.dart`)
- **Game Engine**: `flame` (used for 2D chess board rendering in `lib/logic/`)
- **UI Toolkit**: `Cupertino` widgets are primarily used (see `lib/main.dart` and `lib/views/`)
- **Data Persistence**: `shared_preferences` (settings, themes, undo/redo configs)

## Directory Structure
- `lib/model/`: Contains `app_model.dart`, `app_themes.dart`, `user_preferences.dart`. Modify these for state or theme changes.
- `lib/logic/`: Core game mechanics. Includes `chess_board.dart`, `chess_game.dart`, `game_controller.dart`, `move_calculation/`, and Flame Sprite logic (`chess_piece_sprite.dart`). Check Minimax and Alpha-Beta logic in `move_calculation/`.
- `lib/views/`: UI Screens (`main_menu_view.dart`, `chess_view.dart`, `settings_view.dart`).

## Rules
1. **State Management**: Any global state changes must happen via `AppModel`. Do not use `setState` for global app state.
2. **Game Logic Updates**: Changes to standard chess rules or AI should be contained in `lib/logic/`. Ensure Minimax depth evaluation and alpha-beta pruning is not broken when modifying `move_calculation/`.
3. **Themes**: When adding a new piece theme, register it in `PIECE_THEMES` and follow existing folder structures (`assets/images/pieces/<theme_name>/`). Load it via Flame's asset loader in `main.dart`.
4. **Formatting**: Ensure Dart files are properly formatted. Follow the naming conventions used in the project.
5. **No Destructive Overrides**: Do not remove core AI features (Undo/Redo, Timers, Difficulty Levels) unless explicitly requested.
