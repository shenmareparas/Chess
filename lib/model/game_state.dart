import '../logic/move_calculation/move_classes/move_meta.dart';
import 'player.dart';

/// Pure Model class holding the mutable outcome state of a single chess game.
///
/// This is deliberately a plain Dart class (no [ChangeNotifier]) — it carries
/// no UI awareness.  [AppModel] owns an instance of this and notifies its own
/// listeners whenever it mutates fields here.
///
/// Fields included here are those that describe **what happened in the game**
/// (who won, whose turn it is, what moves were played) rather than app-level
/// settings, UI flags, or service references — those stay in [AppModel].
class GameState {
  /// Whether the game has ended (checkmate, stalemate, or time-out).
  bool gameOver = false;

  /// Whether the game ended in stalemate rather than checkmate.
  bool stalemate = false;

  /// Whether the human player won (used for confetti + audio selection).
  bool userWon = false;

  /// Whose turn it currently is.
  Player turn = Player.player1;

  /// Ordered list of move metadata; one entry per half-move (ply).
  List<MoveMeta> moveMetaList = [];

  /// Resets all fields to their initial values for a fresh game.
  void reset() {
    gameOver = false;
    stalemate = false;
    userWon = false;
    turn = Player.player1;
    moveMetaList = [];
  }
}
