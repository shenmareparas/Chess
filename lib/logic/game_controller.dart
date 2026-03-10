import 'package:async/async.dart';
import 'package:flutter/foundation.dart';

import '../model/app_model.dart';

import 'chess_board.dart';
import 'chess_piece.dart';
import 'move_calculation/ai_move_calculation.dart';
import 'move_calculation/move_classes/move.dart';
import 'move_calculation/move_classes/move_meta.dart';
import 'shared_functions.dart';



/// Handles game logic orchestration: move execution, AI, undo/redo, promotion.
/// Separated from ChessGame (the view/rendering layer) for clean MVVM.
class GameController {
  final AppModel appModel;
  final ChessBoard board = ChessBoard();

  CancelableOperation? aiOperation;
  List<int> validMoves = [];
  ChessPiece? selectedPiece;
  int? checkHintTile;
  Move? latestMove;

  /// Called when the view needs to refresh sprites (e.g. after game restore).
  VoidCallback? onSnapSprites;

  GameController(this.appModel) {}

  // ── Piece Selection ──

  void selectPiece(ChessPiece? piece) {
    if (piece != null) {
      if (piece.player == appModel.turn) {
        selectedPiece = piece;
        if (selectedPiece != null) {
          validMoves = board.movesForPiece(piece);
        }
        if (validMoves.isEmpty) {
          selectedPiece = null;
        }
      }
    }
  }

  void movePiece(int tile) {
    if (validMoves.contains(tile)) {
      validMoves = [];
      var meta =
          board.push(Move(selectedPiece?.tile ?? 0, tile), getMeta: true);
      appModel.audio.playMovedSound();
      if (meta.promotion) {
        appModel.requestPromotion();
      }
      _moveCompletion(meta, changeTurn: !meta.promotion);
    }
  }

  // ── AI ──

  void _aiMove() async {
    if (appModel.gameOver) return;
    await Future.delayed(Duration(milliseconds: 500));
    if (appModel.gameOver) return;
    var args = Map();
    args['aiPlayer'] = appModel.aiTurn;
    args['aiDifficulty'] = appModel.aiDifficulty;
    args['board'] = board;
    aiOperation = CancelableOperation.fromFuture(
      compute(calculateAIMove, args),
    );
    aiOperation?.value.then((move) {
      if (move == null || appModel.gameOver) {
        appModel.endGame();
      } else {
        validMoves = [];
        var meta = board.push(move, getMeta: true);
        appModel.audio.playMovedSound();
        _moveCompletion(meta, changeTurn: !meta.promotion);
        if (meta.promotion) {
          promote(move.promotionType);
        }
      }
    });
  }

  void cancelAIMove() {
    aiOperation?.cancel();
  }

  void triggerAIMove() {
    _aiMove();
  }

  // ── Undo / Redo ──

  void undoMove() {
    board.redoStack.add(board.pop());
    if (appModel.moveMetaList.length > 1) {
      var meta = appModel.moveMetaList[appModel.moveMetaList.length - 2];
      _moveCompletion(meta, clearRedo: false, undoing: true);
    } else {
      _undoOpeningMove();
      appModel.changeTurn();
    }
  }

  void undoTwoMoves() {
    board.redoStack.add(board.pop());
    board.redoStack.add(board.pop());
    appModel.popMoveMeta();
    if (appModel.moveMetaList.length > 1) {
      _moveCompletion(appModel.moveMetaList[appModel.moveMetaList.length - 2],
          clearRedo: false, undoing: true, changeTurn: false);
    } else {
      _undoOpeningMove();
    }
  }

  void _undoOpeningMove() {
    selectedPiece = null;
    validMoves = [];
    latestMove = null;
    checkHintTile = null;
    appModel.popMoveMeta();
  }

  void redoMove() {
    _moveCompletion(board.pushMSO(board.redoStack.removeLast()),
        clearRedo: false);
  }

  void redoTwoMoves() {
    _moveCompletion(board.pushMSO(board.redoStack.removeLast()),
        clearRedo: false, updateMetaList: true);
    _moveCompletion(board.pushMSO(board.redoStack.removeLast()),
        clearRedo: false, updateMetaList: true);
  }

  // ── Promotion ──

  void promote(ChessPieceType type) {
    board.moveStack.last.movedPiece?.type = type;
    board.moveStack.last.promotionType = type;
    board.addPromotedPiece(board.moveStack.last);
    appModel.moveMetaList.last.promotionType = type;
    _moveCompletion(appModel.moveMetaList.last, updateMetaList: false);
  }

  // ── Move Completion ──

  void _moveCompletion(
    MoveMeta meta, {
    bool clearRedo = true,
    bool undoing = false,
    bool changeTurn = true,
    bool updateMetaList = true,
  }) async {
    if (clearRedo) {
      board.redoStack = [];
    }
    validMoves = [];
    latestMove = meta.move;
    checkHintTile = null;
    var oppositeTurn = oppositePlayer(appModel.turn);

    // kingInCheck is lightweight (no push/pop), keep synchronous
    if (board.kingInCheck(oppositeTurn)) {
      meta.isCheck = true;
      checkHintTile = board.kingForPlayer(oppositeTurn)?.tile;
    }

    // Run synchronously to avoid expensive object graph serialization in Isolates
    bool isCheckmate = board.kingInCheckmate(oppositeTurn);
    if (isCheckmate) {
      if (!meta.isCheck) {
        appModel.stalemate = true;
        meta.isStalemate = true;
      }
      meta.isCheck = false;
      meta.isCheckmate = true;
      appModel.endGame(silent: true);
    }
    if (undoing) {
      appModel.popMoveMeta(silent: true);
      appModel.undoEndGame(silent: true);
    } else if (updateMetaList) {
      appModel.pushMoveMeta(meta, silent: true);
    }
    if (changeTurn) {
      appModel.changeTurn(silent: true);
    }
    selectedPiece = null;
    // Single rebuild for all the state changes above
    appModel.update();
    if (appModel.isAIsTurn && clearRedo && changeTurn) {
      _aiMove();
    }
  }

  void snapSprites() {
    onSnapSprites?.call();
  }
}
