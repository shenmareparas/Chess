import 'package:async/async.dart';
import 'dart:math';
import 'package:en_passant/logic/chess_piece_sprite.dart';
import 'package:en_passant/logic/move_calculation/ai_move_calculation.dart';
import 'package:en_passant/logic/move_calculation/move_calculation.dart';
import 'package:en_passant/logic/move_calculation/move_classes/move_meta.dart';
import 'package:en_passant/logic/shared_functions.dart';
import 'package:en_passant/model/app_model.dart';
import 'package:en_passant/model/player.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'chess_board.dart';
import 'chess_piece.dart';
import 'move_calculation/move_classes/move.dart';

/// Top-level function for compute() — runs kingInCheckmate in a real isolate.
/// compute() requires a top-level or static function, not a closure.
bool _computeCheckmate(Map args) {
  Player player = args['player'];
  ChessBoard board = args['board'];
  return kingInCheckmate(player, board);
}

class ChessGame extends FlameGame with TapCallbacks {
  double? width;
  double? tileSize;
  AppModel appModel;
  BuildContext context;
  ChessBoard board = ChessBoard();
  Map<ChessPiece, ChessPieceSprite> spriteMap = Map();

  CancelableOperation? aiOperation;
  List<int> validMoves = [];
  ChessPiece? selectedPiece;
  int? checkHintTile;
  Move? latestMove;
  double currentRotation = 0;
  double targetRotation = 0;
  double startRotation = 0;
  double animationProgress = 1.0;
  final double animationDuration = 0.6;

  // Cached Paint objects to avoid per-frame allocations
  Paint _lightTilePaint = Paint();
  Paint _darkTilePaint = Paint();
  Paint _moveHintPaint = Paint();
  Paint _checkHintPaint = Paint();
  Paint _latestMovePaint = Paint();
  Paint _selectedPiecePaint = Paint();
  String? _cachedThemeName;

  ChessGame(this.appModel, this.context) {
    width = MediaQuery.of(context).size.width - 68;
    tileSize = (width ?? 0) / 8;
    for (var piece in board.player1Pieces + board.player2Pieces) {
      spriteMap[piece] = ChessPieceSprite(piece, appModel.pieceTheme);
    }
    _initSpritePositions();
    _updatePaints();
    if (appModel.isAIsTurn) {
      _aiMove();
    }
  }

  void _updatePaints() {
    var theme = appModel.theme;
    _lightTilePaint = Paint()..color = theme.lightTile;
    _darkTilePaint = Paint()..color = theme.darkTile;
    _moveHintPaint = Paint()..color = theme.moveHint;
    _checkHintPaint = Paint()..color = theme.checkHint;
    _latestMovePaint = Paint()..color = theme.latestMove;
    _selectedPiecePaint = Paint()..color = theme.moveHint;
    _cachedThemeName = theme.name;
  }

  void onTapDown(TapDownEvent event) {
    if (appModel.gameOver || !(appModel.isAIsTurn)) {
      var tile = _vector2ToTile(event.localPosition);
      var touchedPiece = board.tiles[tile];
      if (touchedPiece == selectedPiece) {
        validMoves = [];
        selectedPiece = null;
      } else {
        if (selectedPiece != null &&
            touchedPiece != null &&
            touchedPiece.player == selectedPiece?.player) {
          if (validMoves.contains(tile)) {
            _movePiece(tile);
          } else {
            validMoves = [];
            _selectPiece(touchedPiece);
          }
        } else if (selectedPiece == null) {
          _selectPiece(touchedPiece);
        } else {
          _movePiece(tile);
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    _drawBoard(canvas);
    if (appModel.showHints) {
      _drawCheckHint(canvas);
      _drawLatestMove(canvas);
    }
    _drawSelectedPieceHint(canvas);
    _drawPieces(canvas);
    if (appModel.showHints) {
      _drawMoveHints(canvas);
    }
  }

  @override
  void update(double t) {
    super.update(t);

    // Update cached paints if theme changed
    if (_cachedThemeName != appModel.theme.name) {
      _updatePaints();
    }

    double newTargetRotation = 0;
    if (appModel.enableRotation &&
        ((appModel.playingWithAI && appModel.playerSide == Player.player2) ||
            (!appModel.playingWithAI && appModel.turn == Player.player2))) {
      newTargetRotation = pi;
    } else {
      newTargetRotation = 0;
    }

    if (newTargetRotation != targetRotation) {
      targetRotation = newTargetRotation;
      startRotation = currentRotation;
      animationProgress = 0;
    }

    if (animationProgress < 1.0) {
      animationProgress += t / animationDuration;
      if (animationProgress > 1.0) animationProgress = 1.0;

      // Parametric easeInOutCubic equivalent to match Curves.easeInOut roughly
      // t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
      double curviness = animationProgress < 0.5
          ? 4 * animationProgress * animationProgress * animationProgress
          : 1 - pow(-2 * animationProgress + 2, 3) / 2;

      currentRotation =
          startRotation + (targetRotation - startRotation) * curviness;
    } else {
      currentRotation = targetRotation;
    }

    for (var piece in board.player1Pieces.followedBy(board.player2Pieces)) {
      spriteMap[piece]?.update(tileSize ?? 0, appModel, piece, t);
    }
  }

  void _initSpritePositions() {
    for (var piece in board.player1Pieces.followedBy(board.player2Pieces)) {
      spriteMap[piece]?.initSpritePosition(tileSize ?? 0, appModel);
    }
  }

  void snapSprites() {
    for (var piece in board.player1Pieces.followedBy(board.player2Pieces)) {
      spriteMap[piece]?.snapToPiece(piece, tileSize ?? 0, appModel);
    }
  }

  void _selectPiece(ChessPiece? piece) {
    if (piece != null) {
      if (piece.player == appModel.turn) {
        selectedPiece = piece;
        if (selectedPiece != null) {
          validMoves = movesForPiece(piece, board);
        }
        if (validMoves.isEmpty) {
          selectedPiece = null;
        }
      }
    }
  }

  void _movePiece(int tile) {
    if (validMoves.contains(tile)) {
      validMoves = [];
      var meta =
          push(Move(selectedPiece?.tile ?? 0, tile), board, getMeta: true);
      if (appModel.soundEnabled) {
        FlameAudio.play('piece_moved.mp3');
      }
      if (meta.promotion) {
        appModel.requestPromotion();
      }
      _moveCompletion(meta, changeTurn: !meta.promotion);
    }
  }

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
        var meta = push(move, board, getMeta: true);
        if (appModel.soundEnabled) {
          FlameAudio.play('piece_moved.mp3');
        }
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

  void undoMove() {
    board.redoStack.add(pop(board));
    if (appModel.moveMetaList.length > 1) {
      var meta = appModel.moveMetaList[appModel.moveMetaList.length - 2];
      _moveCompletion(meta, clearRedo: false, undoing: true);
    } else {
      _undoOpeningMove();
      appModel.changeTurn();
    }
  }

  void undoTwoMoves() {
    board.redoStack.add(pop(board));
    board.redoStack.add(pop(board));
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
    _moveCompletion(pushMSO(board.redoStack.removeLast(), board),
        clearRedo: false);
  }

  void redoTwoMoves() {
    _moveCompletion(pushMSO(board.redoStack.removeLast(), board),
        clearRedo: false, updateMetaList: true);
    _moveCompletion(pushMSO(board.redoStack.removeLast(), board),
        clearRedo: false, updateMetaList: true);
  }

  void promote(ChessPieceType type) {
    board.moveStack.last.movedPiece?.type = type;
    board.moveStack.last.promotionType = type;
    addPromotedPiece(board, board.moveStack.last);
    appModel.moveMetaList.last.promotionType = type;
    _moveCompletion(appModel.moveMetaList.last, updateMetaList: false);
  }

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
    if (kingInCheck(oppositeTurn, board)) {
      meta.isCheck = true;
      checkHintTile = kingForPlayer(oppositeTurn, board)?.tile;
    }

    // kingInCheckmate is expensive (O(pieces × moves²) with push/pop).
    // Run it in a real isolate to avoid blocking the UI thread.
    bool isCheckmate = await compute(_computeCheckmate, {
      'player': oppositeTurn,
      'board': board,
    });
    if (isCheckmate) {
      if (!meta.isCheck) {
        appModel.stalemate = true;
        meta.isStalemate = true;
      }
      meta.isCheck = false;
      meta.isCheckmate = true;
      appModel.endGame();
    }
    if (undoing) {
      appModel.popMoveMeta();
      appModel.undoEndGame();
    } else if (updateMetaList) {
      appModel.pushMoveMeta(meta);
    }
    if (changeTurn) {
      appModel.changeTurn();
    }
    selectedPiece = null;
    if (appModel.isAIsTurn && clearRedo && changeTurn) {
      _aiMove();
    }
  }

  int _vector2ToTile(Vector2 vector2) {
    return (vector2.y / (tileSize ?? 0)).floor() * 8 +
        (vector2.x / (tileSize ?? 0)).floor();
  }

  void _drawBoard(Canvas canvas) {
    for (int tileNo = 0; tileNo < 64; tileNo++) {
      canvas.drawRect(
        Rect.fromLTWH(
          (tileNo % 8) * (tileSize ?? 0),
          (tileNo / 8).floor() * (tileSize ?? 0),
          (tileSize ?? 0),
          (tileSize ?? 0),
        ),
        (tileNo + (tileNo / 8).floor()) % 2 == 0
            ? _lightTilePaint
            : _darkTilePaint,
      );
    }
  }

  void _drawPieces(Canvas canvas) {
    for (var piece in board.player1Pieces.followedBy(board.player2Pieces)) {
      double x = (spriteMap[piece]?.spriteX ?? 0) + 5;
      double y = (spriteMap[piece]?.spriteY ?? 0) + 5;
      double size = (tileSize ?? 0) - 10;

      canvas.save();
      // Rotate piece around its center
      canvas.translate(x + size / 2, y + size / 2);
      canvas.rotate(-currentRotation);
      canvas.translate(-(x + size / 2), -(y + size / 2));

      spriteMap[piece]?.sprite?.render(
            canvas,
            size: Vector2(size, size),
            position: Vector2(x, y),
          );
      canvas.restore();
    }
  }

  void _drawMoveHints(Canvas canvas) {
    for (var tile in validMoves) {
      canvas.drawCircle(
        Offset(
          getXFromTile(tile, (tileSize ?? 0), appModel) + ((tileSize ?? 0) / 2),
          getYFromTile(tile, (tileSize ?? 0), appModel) + ((tileSize ?? 0) / 2),
        ),
        (tileSize ?? 0) / 5,
        _moveHintPaint,
      );
    }
  }

  void _drawLatestMove(Canvas canvas) {
    if (latestMove != null) {
      canvas.drawRect(
        Rect.fromLTWH(
          getXFromTile(latestMove!.from, tileSize ?? 0, appModel),
          getYFromTile(latestMove!.from, tileSize ?? 0, appModel),
          tileSize ?? 0,
          tileSize ?? 0,
        ),
        _latestMovePaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          getXFromTile(latestMove!.to, tileSize ?? 0, appModel),
          getYFromTile(latestMove!.to, tileSize ?? 0, appModel),
          tileSize ?? 0,
          tileSize ?? 0,
        ),
        _latestMovePaint,
      );
    }
  }

  void _drawCheckHint(Canvas canvas) {
    if (checkHintTile != null) {
      canvas.drawRect(
        Rect.fromLTWH(
          getXFromTile(checkHintTile!, tileSize ?? 0, appModel),
          getYFromTile(checkHintTile!, tileSize ?? 0, appModel),
          tileSize ?? 0,
          tileSize ?? 0,
        ),
        _checkHintPaint,
      );
    }
  }

  void _drawSelectedPieceHint(Canvas canvas) {
    if (selectedPiece != null) {
      canvas.drawRect(
        Rect.fromLTWH(
          getXFromTile(selectedPiece!.tile, tileSize ?? 0, appModel),
          getYFromTile(selectedPiece!.tile, tileSize ?? 0, appModel),
          tileSize ?? 0,
          tileSize ?? 0,
        ),
        _selectedPiecePaint,
      );
    }
  }
}
