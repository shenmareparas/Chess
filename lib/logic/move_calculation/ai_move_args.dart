import '../../model/player.dart';
import '../chess_board.dart';
import 'transposition_table.dart';

/// Typed argument container passed to [calculateAIMove] via [compute].
/// Replaces the previous untyped [Map] to avoid boxing overhead.
class AIMoveArgs {
  final ChessBoard board;
  final Player aiPlayer;
  final int aiDifficulty;
  final TranspositionTable tt;

  const AIMoveArgs({
    required this.board,
    required this.aiPlayer,
    required this.aiDifficulty,
    required this.tt,
  });
}
