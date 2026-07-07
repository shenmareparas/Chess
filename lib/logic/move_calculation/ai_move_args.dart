import '../../model/player.dart';
import '../chess_board.dart';

/// Typed argument container passed to [calculateAIMove] via [compute].
/// Replaces the previous untyped [Map] to avoid boxing overhead.
class AIMoveArgs {
  final ChessBoard board;
  final Player aiPlayer;
  final int aiDifficulty;

  const AIMoveArgs({
    required this.board,
    required this.aiPlayer,
    required this.aiDifficulty,
  });
}
