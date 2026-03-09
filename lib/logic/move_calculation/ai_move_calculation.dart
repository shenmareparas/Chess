import 'dart:math';

import 'package:en_passant/logic/move_calculation/move_classes/move_and_value.dart';
import 'package:en_passant/logic/move_calculation/transposition_table.dart';
import 'package:en_passant/model/player.dart';

import '../chess_board.dart';
import '../shared_functions.dart';
import 'move_classes/move.dart';

const INITIAL_ALPHA = -40000;
const STALEMATE_ALPHA = -20000;
const INITIAL_BETA = 40000;
const STALEMATE_BETA = 20000;

// Null move pruning reduction
const NULL_MOVE_REDUCTION = 2;

// Late move reduction threshold (search first N moves at full depth)
const LMR_FULL_DEPTH_MOVES = 4;
const LMR_DEPTH_THRESHOLD = 3;

// Quiescence search depth limit to prevent explosion
const MAX_QUIESCENCE_DEPTH = 8;

Move calculateAIMove(Map args) {
  ChessBoard board = args['board'];
  if (board.possibleOpenings.isNotEmpty) {
    return _openingMove(board, args['aiPlayer']);
  } else {
    int maxDepth = args['aiDifficulty'];
    Player aiPlayer = args['aiPlayer'];
    var tt = TranspositionTable();

    // Iterative deepening: search depth 1, 2, ..., maxDepth
    // Each iteration informs move ordering for the next
    Move? bestMove;
    for (int depth = 1; depth <= maxDepth; depth++) {
      var result = _alphaBeta(board, aiPlayer, Move(0, 0), 0, depth,
          INITIAL_ALPHA, INITIAL_BETA, tt, true);
      if (result.move.from != 0 || result.move.to != 0) {
        bestMove = result.move;
      }
    }

    return bestMove ?? Move(0, 0);
  }
}

MoveAndValue _alphaBeta(ChessBoard board, Player player, Move move, int depth,
    int maxDepth, int alpha, int beta, TranspositionTable tt, bool allowNull) {
  int origAlpha = alpha;

  // Transposition table lookup
  var ttEntry = tt.probe(board.zobristHash);
  if (ttEntry != null && ttEntry.depth >= (maxDepth - depth)) {
    if (ttEntry.flag == TT_EXACT) {
      return MoveAndValue(ttEntry.bestMove ?? move, ttEntry.value);
    } else if (ttEntry.flag == TT_BETA) {
      alpha = max(alpha, ttEntry.value);
    } else if (ttEntry.flag == TT_ALPHA) {
      beta = min(beta, ttEntry.value);
    }
    if (alpha >= beta) {
      return MoveAndValue(ttEntry.bestMove ?? move, ttEntry.value);
    }
  }

  // Leaf node: run quiescence search instead of static eval
  if (depth == maxDepth) {
    return MoveAndValue(move, _quiescence(board, player, alpha, beta, 0));
  }

  // Null Move Pruning: if not in check and depth is sufficient,
  // try passing the turn to see if we can still cause a cutoff
  if (allowNull &&
      depth + NULL_MOVE_REDUCTION + 1 < maxDepth &&
      !board.kingInCheck(player)) {
    // "Pass" the turn by searching from the opponent's perspective
    // without making a move, at reduced depth
    board.zobristHash ^= ChessBoard.zobristSideToMoveValue;
    var nullResult = _alphaBeta(board, oppositePlayer(player), move,
        depth + 1 + NULL_MOVE_REDUCTION, maxDepth, alpha, beta, tt, false);
    board.zobristHash ^= ChessBoard.zobristSideToMoveValue;
    if (player == Player.player1) {
      if (nullResult.value >= beta) {
        return MoveAndValue(move, beta);
      }
    } else {
      if (nullResult.value <= alpha) {
        return MoveAndValue(move, alpha);
      }
    }
  }

  var moves = board.allMoves(player, maxDepth);

  // Order the TT best move first if available
  if (ttEntry != null && ttEntry.bestMove != null) {
    var ttMove = ttEntry.bestMove!;
    var idx =
        moves.indexWhere((m) => m.from == ttMove.from && m.to == ttMove.to);
    if (idx > 0) {
      moves.removeAt(idx);
      moves.insert(0, ttMove);
    }
  }

  var bestMove = MoveAndValue(
      Move(0, 0), player == Player.player1 ? INITIAL_ALPHA : INITIAL_BETA);

  for (int i = 0; i < moves.length; i++) {
    var currentMove = moves[i];
    board.push(currentMove, promotionType: currentMove.promotionType);

    MoveAndValue result;
    int remaining = maxDepth - depth - 1;

    // Late Move Reductions: search later quiet moves at reduced depth
    bool isCapture = board.moveStack.last.takenPiece != null;
    bool isPromotion = board.moveStack.last.promotion;
    if (i >= LMR_FULL_DEPTH_MOVES &&
        remaining >= LMR_DEPTH_THRESHOLD &&
        !isCapture &&
        !isPromotion &&
        !board.kingInCheck(oppositePlayer(player))) {
      // Search at reduced depth first
      result = _alphaBeta(board, oppositePlayer(player), currentMove, depth + 2,
          maxDepth, alpha, beta, tt, true);
      result.move = currentMove;

      // If the reduced search looks interesting, re-search at full depth
      bool needsFullSearch;
      if (player == Player.player1) {
        needsFullSearch = result.value > alpha;
      } else {
        needsFullSearch = result.value < beta;
      }
      if (needsFullSearch) {
        result = _alphaBeta(board, oppositePlayer(player), currentMove,
            depth + 1, maxDepth, alpha, beta, tt, true);
        result.move = currentMove;
      }
    } else {
      // Full depth search
      result = _alphaBeta(board, oppositePlayer(player), currentMove, depth + 1,
          maxDepth, alpha, beta, tt, true);
      result.move = currentMove;
    }

    board.pop();

    if (player == Player.player1) {
      if (result.value > bestMove.value) {
        bestMove = result;
      }
      alpha = max(alpha, bestMove.value);
      if (alpha >= beta) {
        break;
      }
    } else {
      if (result.value < bestMove.value) {
        bestMove = result;
      }
      beta = min(beta, bestMove.value);
      if (beta <= alpha) {
        break;
      }
    }
  }

  // Stalemate / no-moves detection
  if (bestMove.value.abs() == INITIAL_BETA && !board.kingInCheck(player)) {
    if (board.piecesForPlayer(player).length == 1) {
      bestMove.value =
          player == Player.player1 ? STALEMATE_BETA : STALEMATE_ALPHA;
    } else {
      bestMove.value =
          player == Player.player1 ? STALEMATE_ALPHA : STALEMATE_BETA;
    }
  }

  // Store in transposition table
  int ttFlag;
  if (bestMove.value <= origAlpha) {
    ttFlag = TT_ALPHA;
  } else if (bestMove.value >= beta) {
    ttFlag = TT_BETA;
  } else {
    ttFlag = TT_EXACT;
  }
  tt.store(board.zobristHash, maxDepth - depth, bestMove.value, ttFlag,
      bestMove.move);

  return bestMove;
}

/// Quiescence search: continue searching captures at leaf nodes
/// to avoid the horizon effect
int _quiescence(
    ChessBoard board, Player player, int alpha, int beta, int qDepth) {
  int standPat = board.boardValue;

  if (qDepth >= MAX_QUIESCENCE_DEPTH) {
    return standPat;
  }

  if (player == Player.player1) {
    if (standPat >= beta) return beta;
    if (standPat > alpha) alpha = standPat;

    var captures = board.allMoves(player, 0, capturesOnly: true);
    for (var move in captures) {
      board.push(move, promotionType: move.promotionType);
      int value =
          _quiescence(board, oppositePlayer(player), alpha, beta, qDepth + 1);
      board.pop();

      if (value >= beta) return beta;
      if (value > alpha) alpha = value;
    }
    return alpha;
  } else {
    if (standPat <= alpha) return alpha;
    if (standPat < beta) beta = standPat;

    var captures = board.allMoves(player, 0, capturesOnly: true);
    for (var move in captures) {
      board.push(move, promotionType: move.promotionType);
      int value =
          _quiescence(board, oppositePlayer(player), alpha, beta, qDepth + 1);
      board.pop();

      if (value <= alpha) return alpha;
      if (value < beta) beta = value;
    }
    return beta;
  }
}

Move _openingMove(ChessBoard board, Player aiPlayer) {
  List<Move> possibleMoves = board.possibleOpenings
      .map((opening) => opening[board.moveCount])
      .toList();
  return possibleMoves[Random.secure().nextInt(possibleMoves.length)];
}
