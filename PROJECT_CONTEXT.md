# Chess App - Project Context

## Overview
This is a feature-rich chess application built with **Flutter** and **Flame**. 
It offers both single-player (vs AI) and two-player offline modes. The AI utilizes the **Minimax algorithm with alpha-beta pruning** with varying difficulty levels (Depth 1 to 6).

## Key Components
### 1. App Entry & State
- **`lib/main.dart`**: Initializes settings, loads Flame assets (audio & images), and wraps the `CupertinoApp` with a `ChangeNotifierProvider` for `AppModel`.
- **`lib/model/app_model.dart`**: The central brain for state management, notifying the UI of game state changes, theme changes, and settings.
- **`lib/model/user_preferences.dart`**: Handles saving and loading settings to local storage.
- **`lib/model/app_themes.dart`**: Specifies board and UI colors.

### 2. UI & Views (`lib/views/`)
- **`main_menu_view.dart`**: The starting screen to configure the game (1P/2P, difficulty, time control, side selection).
- **`chess_view.dart`**: The primary game interface displaying the Flame-rendered board, move history, captured pieces, and timers.
- **`settings_view.dart`**: For customizing themes, sounds, and other UI preferences.

### 3. Game Logic & Flame Integration (`lib/logic/`)
- **`chess_game.dart` & `game_controller.dart`**: Controls the flow of the game, turn switching, and game loop.
- **`chess_board.dart`**: Handles the board representation and rendering logic via Flame engine components.
- **`move_calculation/`**: Contains the critical logic for move generation, validation (checks, stalemates), and the AI's Minimax algorithm.
- **`timer_service.dart` & `audio_service.dart`**: Independent services for game timers and sound effects.
- **`game_state_storage.dart`**: Logic for managing game history, states, undo and redo functionality.

## Assets
- Images are located in `assets/images` (with piece subdirectories).
- Audio effects are in `assets/audio`.
- Fonts (`Jura`) are in `assets/font`.

## Important Note to AI
This context provides a high-level map of the codebase to assist in making localized or architectural changes without breaking existing features. If you are modifying UI look in `views/` and `model/`. If modifying how pieces move or AI difficulty, look inside `logic/`.
