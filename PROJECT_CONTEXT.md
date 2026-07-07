# Chess App - Project Context

## Overview

This is a feature-rich chess application built with **Flutter** and **Flame**.
It offers both single-player (vs AI) and two-player offline modes. The AI utilizes the **Minimax algorithm with alpha-beta pruning** with varying difficulty levels (Depth 1 to 5).

## Key Components

### 1. App Entry & State

- **`lib/main.dart`**: Initializes settings (loading preferences first), preloads essential assets (the active piece theme, Classic theme, and the home screen logo) synchronously to speed up startup, launches remaining theme preloading and AdService initialization asynchronously, and wraps the `CupertinoApp` with a `ChangeNotifierProvider` for `AppModel`.
- **`lib/model/app_model.dart`**: The central brain for state management, notifying the UI of game state changes, theme changes, and settings.
- **`lib/model/user_preferences.dart`**: Handles saving and loading settings to local storage.
- **`lib/model/app_themes.dart`**: Specifies board and UI colors.
- **`lib/model/player.dart`**: Player enums and base logic.

### 2. UI & Views (`lib/views/`)

- **`main_menu_view.dart`**: The starting screen to configure the game (1P/2P, difficulty, time control, side selection).
- **`chess_view.dart`**: The primary game interface displaying the Flame-rendered board, move history, captured pieces, and timers. Reacts dynamically to `GameController` swaps (e.g., on game restart) to re-initialize the Flame layer.
- **`settings_view.dart`**: For customizing themes, sounds, and other UI preferences.
- **`components/`**: Directory containing view-specific subcomponents and shared widgets.

### 3. Game Logic & Flame Integration (`lib/logic/`)

- **`chess_game.dart` & `game_controller.dart`**: Controls the flow of the game, turn switching, and game loop.
- **`chess_board.dart`**: Handles the board representation and rendering logic via Flame engine components.
- **`move_calculation/`**: Contains the critical logic for move generation, validation (checks, stalemates), and the AI's Minimax algorithm with optimizations like Quiescence Search, Null Move Pruning, and Iterative Deepening.
- **`timer_service.dart` & `audio_service.dart`**: Independent services for game timers and sound effects.
- **`ad_service.dart`**: Integrates `google_mobile_ads` for rewarded ads (such as for granting undos), implementing fallback mechanisms that grant rewards even when offline or upon ad display failures.
- **`game_state_storage.dart`**: Logic for managing game history, states, undo and redo functionality.

### 4. Marketing & Screenshots (`screenshots_editor/`)

- **`screenshots_editor/`**: A Next.js-based local web tool for designing and exporting Google Play Store screenshots.
  - Automatically loads slide-specific game themes (Forest Mint, Midnight Slate, etc.).
  - Configured with custom thin bezel layouts, concentric rounded corners, and layouts (`two-devices`, `three-devices`).
  - Supports premium background overlays (adjustable film noise opacity) and camera notch bezel toggle settings.
  - Supports horizontal & vertical alignment (both custom text elements and slide headlines) and stage snap-centering actions.
  - Auto-saves layout configurations in real-time to `screenshots_editor/app-store-screenshots.json`.

## Assets

- Images are located in `assets/images` (with piece subdirectories).
- Audio effects are in `assets/audio`.
- Fonts (`Inter`) are in `assets/font`.

## Important Note to AI

This context provides a high-level map of the codebase to assist in making localized or architectural changes without breaking existing features. If you are modifying UI look in `views/` and `model/`. If modifying how pieces move or AI difficulty, look inside `logic/`.
If you need to make changes to the app store screenshot generator, modify the Next.js code under `screenshots_editor/` and run `bun dev` to test it.
