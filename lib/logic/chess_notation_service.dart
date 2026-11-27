import 'package:dartchess/dartchess.dart' as dc;

import 'move_calculation/move_classes/move_stack_object.dart';
import 'stockfish_service.dart';

/// Classification of FIDE draw outcomes.
enum FideDrawReason {
  stalemate,
  threefoldRepetition,
  fiftyMoveRule,
  insufficientMaterial;

  String get description {
    switch (this) {
      case FideDrawReason.stalemate:
        return 'Stalemate';
      case FideDrawReason.threefoldRepetition:
        return 'Threefold Repetition';
      case FideDrawReason.fiftyMoveRule:
        return '50-Move Rule';
      case FideDrawReason.insufficientMaterial:
        return 'Insufficient Material';
    }
  }
}

/// Structured outcome of a position evaluation.
class PositionOutcome {
  final bool isCheckmate;
  final FideDrawReason? drawReason;

  const PositionOutcome({this.isCheckmate = false, this.drawReason});

  bool get isStalemate => drawReason == FideDrawReason.stalemate;
  bool get isDraw => drawReason != null;
  bool get isGameOver => isCheckmate || isDraw;
}

/// Service that leverages dartchess for standard FEN generation,
/// PGN export with SAN formatting, and FIDE-compliant draw evaluation.
class ChessNotationService {
  ChessNotationService._();

  static final ChessNotationService instance = ChessNotationService._();

  /// Converts a UCI string to a legal [dc.Move] in the given [pos],
  /// supporting standard e1g1/e8g8 castling and normalized formats.
  dc.Move? parseUciMove(dc.Position pos, String uci) {
    try {
      final normal = dc.NormalMove.fromUci(uci);
      if (pos.isLegal(normal)) return normal;

      final normalized = pos.normalizeMove(normal);
      if (pos.isLegal(normalized)) return normalized;
    } catch (_) {}
    return null;
  }

  /// Replays a list of [MoveStackObject]s from the standard starting position
  /// and returns the resulting immutable [dc.Position].
  dc.Position replayMoves(List<MoveStackObject> moveStack) {
    dc.Position position = dc.Chess.initial;
    for (final mso in moveStack) {
      final uci = StockfishService.msoToUCI(mso);
      final move = parseUciMove(position, uci);
      if (move != null) {
        position = position.play(move);
      }
    }
    return position;
  }

  /// Evaluates checkmate and FIDE draw conditions across the entire move history.
  PositionOutcome evaluateOutcome(List<MoveStackObject> moveStack) {
    dc.Position position = dc.Chess.initial;
    final historyHashes = <int>[position.zobristHash()];

    for (final mso in moveStack) {
      final uci = StockfishService.msoToUCI(mso);
      final move = parseUciMove(position, uci);
      if (move != null) {
        position = position.play(move);
        historyHashes.add(position.zobristHash());
      }
    }

    if (position.isCheckmate) {
      return const PositionOutcome(isCheckmate: true);
    }

    if (position.isStalemate) {
      return const PositionOutcome(drawReason: FideDrawReason.stalemate);
    }

    if (position.isInsufficientMaterial) {
      return const PositionOutcome(
        drawReason: FideDrawReason.insufficientMaterial,
      );
    }

    // 50-move rule: 100 half-moves without a pawn move or capture
    if (position.halfmoves >= 100) {
      return const PositionOutcome(drawReason: FideDrawReason.fiftyMoveRule);
    }

    // Threefold repetition: exact same position occurs >= 3 times
    final currentHash = position.zobristHash();
    int occurrences = 0;
    for (final hash in historyHashes) {
      if (hash == currentHash) {
        occurrences++;
        if (occurrences >= 3) {
          return const PositionOutcome(
            drawReason: FideDrawReason.threefoldRepetition,
          );
        }
      }
    }

    return const PositionOutcome();
  }

  /// Evaluates FIDE draw conditions across the entire move history.
  ///
  /// Returns a [FideDrawReason] if a draw condition is reached, or null otherwise.
  FideDrawReason? checkDraw(List<MoveStackObject> moveStack) {
    return evaluateOutcome(moveStack).drawReason;
  }

  /// Checks if the current board state represents a checkmate.
  bool isCheckmate(List<MoveStackObject> moveStack) {
    return evaluateOutcome(moveStack).isCheckmate;
  }

  /// Checks if the current board state represents a stalemate.
  bool isStalemate(List<MoveStackObject> moveStack) {
    return evaluateOutcome(moveStack).isStalemate;
  }

  /// Exports the current board position as standard FEN notation.
  String exportFen(List<MoveStackObject> moveStack) {
    return replayMoves(moveStack).fen;
  }

  /// Generates a complete, standard PGN string from the game move history.
  String generatePgn({
    required List<MoveStackObject> moveStack,
    String whiteName = 'White',
    String blackName = 'Black',
    String? result, // "1-0", "0-1", "1/2-1/2", or "*"
    String? event = 'Casual Match',
    DateTime? date,
  }) {
    final matchDate = date ?? DateTime.now();
    final dateStr =
        '${matchDate.year}.${matchDate.month.toString().padLeft(2, '0')}.${matchDate.day.toString().padLeft(2, '0')}';
    final matchResult = result ?? '*';

    final buffer = StringBuffer();
    buffer.writeln('[Event "$event"]');
    buffer.writeln('[Site "Chess Offline"]');
    buffer.writeln('[Date "$dateStr"]');
    buffer.writeln('[Round "-"]');
    buffer.writeln('[White "$whiteName"]');
    buffer.writeln('[Black "$blackName"]');
    buffer.writeln('[Result "$matchResult"]');
    buffer.writeln();

    dc.Position position = dc.Chess.initial;
    int moveNumber = 1;

    for (int i = 0; i < moveStack.length; i++) {
      final mso = moveStack[i];
      final uci = StockfishService.msoToUCI(mso);
      final move = parseUciMove(position, uci);

      if (move != null) {
        final (newPos, san) = position.makeSan(move);
        position = newPos;

        if (i % 2 == 0) {
          buffer.write('$moveNumber. $san ');
        } else {
          buffer.write('$san ');
          moveNumber++;
        }
      } else {
        // Fallback if parsing fails
        if (i % 2 == 0) {
          buffer.write('$moveNumber. $uci ');
        } else {
          buffer.write('$uci ');
          moveNumber++;
        }
      }
    }

    if (matchResult != '*') {
      buffer.write(matchResult);
    }

    return buffer.toString().trim();
  }
}
