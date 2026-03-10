import 'dart:math' as math;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';

import '../model/app_model.dart';
import 'chess_board.dart';
import 'chess_piece.dart';
import 'chess_piece_sprite.dart';
import 'game_controller.dart';
import 'move_calculation/move_classes/move.dart';
import 'shared_functions.dart';

/// Rendering layer for the chess game. Delegates all game logic to
/// [GameController], keeping this class focused on display and input routing.
class ChessGame extends FlameGame with TapCallbacks {
  double? width;
  double? tileSize;
  AppModel appModel;

  late final GameController controller;
  Map<ChessPiece, ChessPieceSprite> spriteMap = Map();

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

  ChessGame(this.controller, this.appModel) {
    controller.onSnapSprites = () => snapSprites();
    // width and tileSize are calculated in onGameResize
    for (var piece
        in controller.board.player1Pieces + controller.board.player2Pieces) {
      spriteMap[piece] = ChessPieceSprite(piece, appModel.pieceTheme);
    }
    _updatePaints();
    forceSnapRotation();
  }

  void forceSnapRotation() {
    if (appModel.isBoardInverted) {
      currentRotation = math.pi;
      targetRotation = math.pi;
      startRotation = math.pi;
    } else {
      currentRotation = 0;
      targetRotation = 0;
      startRotation = 0;
    }
    animationProgress = 1.0;
  }

  // ── Delegated Accessors (backward compatibility for views) ──

  ChessBoard get board => controller.board;
  List<int> get validMoves => controller.validMoves;
  set validMoves(List<int> v) => controller.validMoves = v;
  ChessPiece? get selectedPiece => controller.selectedPiece;
  set selectedPiece(ChessPiece? v) => controller.selectedPiece = v;
  int? get checkHintTile => controller.checkHintTile;
  set checkHintTile(int? v) => controller.checkHintTile = v;
  Move? get latestMove => controller.latestMove;
  set latestMove(Move? v) => controller.latestMove = v;

  void cancelAIMove() => controller.cancelAIMove();
  void triggerAIMove() => controller.triggerAIMove();
  void undoMove() => controller.undoMove();
  void undoTwoMoves() => controller.undoTwoMoves();
  void redoMove() => controller.redoMove();
  void redoTwoMoves() => controller.redoTwoMoves();
  void promote(ChessPieceType type) => controller.promote(type);

  // ── Input Handling ──

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
            controller.movePiece(tile);
          } else {
            validMoves = [];
            controller.selectPiece(touchedPiece);
          }
        } else if (selectedPiece == null) {
          controller.selectPiece(touchedPiece);
        } else {
          controller.movePiece(tile);
        }
      }
    }
  }

  // ── Rendering ──

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    width = size.x;
    tileSize = width! / 8;
    _initSpritePositions();
    snapSprites();
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
    if (appModel.isBoardInverted) {
      newTargetRotation = math.pi;
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

      double curviness = animationProgress < 0.5
          ? 4 * animationProgress * animationProgress * animationProgress
          : 1 - math.pow(-2 * animationProgress + 2, 3) / 2;

      currentRotation =
          startRotation + (targetRotation - startRotation) * curviness;
    } else {
      currentRotation = targetRotation;
    }

    for (var piece
        in board.player1Pieces.followedBy(board.player2Pieces)) {
      spriteMap[piece]?.update(tileSize ?? 0, appModel, piece, t);
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
          getXFromTile(tile, (tileSize ?? 0)) + ((tileSize ?? 0) / 2),
          getYFromTile(tile, (tileSize ?? 0)) + ((tileSize ?? 0) / 2),
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
          getXFromTile(latestMove!.from, tileSize ?? 0),
          getYFromTile(latestMove!.from, tileSize ?? 0),
          tileSize ?? 0,
          tileSize ?? 0,
        ),
        _latestMovePaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          getXFromTile(latestMove!.to, tileSize ?? 0),
          getYFromTile(latestMove!.to, tileSize ?? 0),
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
          getXFromTile(checkHintTile!, tileSize ?? 0),
          getYFromTile(checkHintTile!, tileSize ?? 0),
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
          getXFromTile(selectedPiece!.tile, tileSize ?? 0),
          getYFromTile(selectedPiece!.tile, tileSize ?? 0),
          tileSize ?? 0,
          tileSize ?? 0,
        ),
        _selectedPiecePaint,
      );
    }
  }
}
