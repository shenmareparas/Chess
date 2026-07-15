import 'dart:math' as math;
import 'package:async/async.dart';

import '../model/app_model.dart';
import '../model/player.dart';

import 'chess_board.dart';
import 'chess_piece.dart';
import 'move_calculation/move_classes/move.dart';
import 'move_calculation/move_classes/move_meta.dart';
import 'play_games_service.dart';
import 'shared_functions.dart';
import 'stockfish_service.dart';

/// Handles game logic orchestration: move execution, AI, undo/redo, promotion.
/// Separated from ChessGame (the view/rendering layer) for clean MVVM.
class GameController {
  final AppModel appModel;
  final ChessBoard board = ChessBoard();

  CancelableOperation? aiOperation;
  List<int> validMoves = [];
  ChessPiece? selectedPiece;
  int? checkHintTile;
  int? warningTile;
  Move? latestMove;

  /// Called when the view needs to refresh sprites (e.g. after game restore).
  void Function({bool snap})? onSnapSprites;

  GameController(this.appModel) {}

  // ── Piece Selection ──

  /// Routing logic for a board tap at [tile].
  ///
  /// Called by the Flame view after it converts a touch position to a tile
  /// index. Contains all tap-routing decisions so the view stays logic-free.
  ///
  /// Guards:
  /// - No input while it's the AI's turn (unless the game is already over).
  /// - Deselect: tapping the already-selected piece clears selection.
  /// - Re-select: tapping a friendly piece swaps selection (or moves if valid).
  /// - Move: tapping any other tile forwards to [movePiece].
  void handleTap(int tile) {
    if (!appModel.gameOver && appModel.isAIsTurn) return;
    final touchedPiece = board.tiles[tile];
    if (touchedPiece == selectedPiece) {
      // Deselect: tap the already-selected piece again.
      validMoves = [];
      selectedPiece = null;
      appModel.haptic.selection();
    } else if (selectedPiece != null &&
        touchedPiece != null &&
        touchedPiece.player == selectedPiece?.player) {
      // Tap a friendly piece while another is selected.
      if (validMoves.contains(tile)) {
        movePiece(tile);
      } else {
        validMoves = [];
        selectPiece(touchedPiece);
      }
    } else if (selectedPiece == null) {
      // No piece selected — try to select this one.
      selectPiece(touchedPiece);
    } else {
      // A piece is selected — try to move to this tile.
      movePiece(tile);
    }
  }

  void selectPiece(ChessPiece? piece) {
    if (piece != null) {
      if (piece.player == appModel.turn) {
        selectedPiece = piece;
        if (selectedPiece != null) {
          validMoves = board.movesForPiece(piece);
        }
        if (validMoves.isEmpty) {
          selectedPiece = null;
          warningTile = piece.tile;
          appModel.haptic.warning();
          appModel.update();
          Future.delayed(const Duration(milliseconds: 500), () {
            if (warningTile == piece.tile) {
              warningTile = null;
              appModel.update();
            }
          });
        } else {
          appModel.haptic.selection();
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
    } else if (selectedPiece != null) {
      appModel.haptic.warning();
    }
  }

  // ── AI ──

  void _aiMove() async {
    if (appModel.gameOver) return;
    await Future.delayed(const Duration(milliseconds: 500));
    if (appModel.gameOver) return;

    final int difficulty = appModel.aiDifficulty;
    bool playRandomMove = false;
    if (difficulty == 1) {
      playRandomMove = math.Random().nextDouble() < 0.60;
    } else if (difficulty == 2) {
      playRandomMove = math.Random().nextDouble() < 0.25;
    }

    if (playRandomMove) {
      final List<Move> allLegalMoves = [];
      final activePieces = appModel.turn == Player.player1
          ? board.player1Pieces
          : board.player2Pieces;
      for (var piece in activePieces) {
        final destinations = board.movesForPiece(piece);
        for (var dest in destinations) {
          allLegalMoves.add(Move(piece.tile, dest));
        }
      }

      if (allLegalMoves.isNotEmpty) {
        final randomMove =
            allLegalMoves[math.Random().nextInt(allLegalMoves.length)];
        final movingPiece = board.tiles[randomMove.from];
        if (movingPiece != null && movingPiece.type == ChessPieceType.pawn) {
          if ((movingPiece.player == Player.player1 &&
                  randomMove.to ~/ 8 == 7) ||
              (movingPiece.player == Player.player2 &&
                  randomMove.to ~/ 8 == 0)) {
            randomMove.promotionType = ChessPieceType.queen;
          }
        }

        final int moveTime = difficulty == 1 ? 100 : 200;
        await Future.delayed(Duration(milliseconds: moveTime));
        if (appModel.gameOver ||
            !appModel.isAIsTurn ||
            appModel.historyViewIndex != null) return;

        validMoves = [];
        var meta = board.push(randomMove, getMeta: true);
        appModel.audio.playMovedSound();
        _moveCompletion(meta, changeTurn: !meta.promotion);
        if (meta.promotion) {
          appModel.moveMetaList.last.promotionType = randomMove.promotionType;
          _moveCompletion(appModel.moveMetaList.last, updateMetaList: false);
        }
        return;
      }
    }

    final movesStr =
        board.moveStack.map((mso) => StockfishService.msoToUCI(mso)).join(' ');
    aiOperation = CancelableOperation.fromFuture(
      StockfishService.instance.getBestMove(movesStr, difficulty),
    );
    aiOperation?.value.then((move) {
      if (move == null ||
          (move.from == 0 && move.to == 0) ||
          appModel.gameOver) {
        appModel.endGame();
      } else {
        validMoves = [];
        var meta = board.push(move, getMeta: true);
        appModel.audio.playMovedSound();
        _moveCompletion(meta, changeTurn: !meta.promotion);
        if (meta.promotion) {
          appModel.moveMetaList.last.promotionType = move.promotionType;
          _moveCompletion(appModel.moveMetaList.last, updateMetaList: false);
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
    appModel.haptic.light();
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
    appModel.haptic.light();
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
    warningTile = null;
    appModel.popMoveMeta();
  }

  void redoMove() {
    appModel.haptic.light();
    _moveCompletion(board.pushMSO(board.redoStack.removeLast()),
        clearRedo: false);
  }

  void redoTwoMoves() {
    appModel.haptic.light();
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
    // Play Games: pawn promotion achievement (human player only)
    if (!appModel.isAIsTurn) {
      PlayGamesService.instance.onPawnPromotion();
    }
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
    warningTile = null;
    var oppositeTurn = oppositePlayer(appModel.turn);

    // kingInCheck is lightweight (no push/pop), keep synchronous
    if (board.kingInCheck(oppositeTurn)) {
      meta.isCheck = true;
      checkHintTile = board.kingForPlayer(oppositeTurn)?.tile;
      // Play Games: put opponent in check (human player's move only)
      if (!appModel.isAIsTurn) {
        PlayGamesService.instance.onCheckDelivered();
      }
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
      if (!undoing && appModel.timerMode == 'increment') {
        appModel.timerService
            .addIncrement(appModel.turn, appModel.timerIncrement);
      }
      appModel.changeTurn(silent: true);
    }
    selectedPiece = null;
    // Single rebuild for all the state changes above
    appModel.update();

    // Trigger haptic feedback based on move outcome
    final isOpponentMove =
        appModel.playingWithAI && (meta.player != appModel.playerSide);

    if (meta.isCheckmate) {
      appModel.haptic.vibrate();
    } else if (meta.isStalemate) {
      appModel.haptic.heavy();
    } else if (isOpponentMove) {
      if (meta.isCheck) {
        appModel.haptic.medium();
      } else {
        appModel.haptic.light();
      }
    } else {
      // Human move
      if (meta.isCheck) {
        appModel.haptic.heavy();
      } else if (meta.took) {
        appModel.haptic.medium();
      } else if (meta.kingCastle || meta.queenCastle) {
        appModel.haptic.doubleLight();
      } else {
        appModel.haptic.light();
      }
    }

    if (appModel.isAIsTurn && clearRedo && changeTurn) {
      _aiMove();
    }
  }

  void snapSprites({bool snap = true}) {
    onSnapSprites?.call(snap: snap);
  }
}
