# Chess

Chess is a chess app written in Flutter using Flame engine.

## Features

- 1 or 2 player gameplay (2 player is offline)
- Six AI difficulty levels
- Customizable app theme
- Customizable piece theme

## AI Description

The chess AI we developed for this app uses the minimax algorithm with alpha-beta pruning to calculate which moves to make. There are six difficulty levels in the app, each level corresponding to the depth of the search used in the minimax algorithm. The highest difficulty is 6, which corresponds to 3 full chess moves. To learn more about how this algorithm works, use the following link: https://en.wikipedia.org/wiki/Alpha–beta_pruning.