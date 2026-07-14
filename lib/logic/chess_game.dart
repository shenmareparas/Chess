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
  Paint _warningHintPaint = Paint();
  String? _cachedThemeName;

  // 64 pre-built Rects for the chess board tiles (rebuilt in onGameResize).
  // Eliminates 64 float multiplications + 64 Rect allocations per frame.
  final List<Rect> _lightTileRects = [];
  final List<Rect> _darkTileRects = [];

  // Flattened piece list rebuilt only when pieces are captured/added.
  // Avoids creating a new FollowedByIterable on every update/render tick.
  List<ChessPiece> _allPieces = [];

  ChessGame(this.controller, this.appModel) {
    controller.onSnapSprites = ({bool snap = true}) => snapSprites(snap: snap);
    // Gather all pieces that exist in the active lists as well as captured pieces in move stacks.
    // This ensures that when review mode restores captured pieces, they have initialized sprites.
    final Set<ChessPiece> allUniquePieces = {};
    allUniquePieces.addAll(controller.board.player1Pieces);
    allUniquePieces.addAll(controller.board.player2Pieces);
    for (var mso in controller.board.moveStack) {
      if (mso.takenPiece != null) {
        allUniquePieces.add(mso.takenPiece!);
      }
      if (mso.enPassantPiece != null) {
        allUniquePieces.add(mso.enPassantPiece!);
      }
    }
    for (var mso in controller.board.redoStack) {
      if (mso.takenPiece != null) {
        allUniquePieces.add(mso.takenPiece!);
      }
      if (mso.enPassantPiece != null) {
        allUniquePieces.add(mso.enPassantPiece!);
      }
    }
    for (var mso in appModel.historyRedoStack) {
      if (mso.takenPiece != null) {
        allUniquePieces.add(mso.takenPiece!);
      }
      if (mso.enPassantPiece != null) {
        allUniquePieces.add(mso.enPassantPiece!);
      }
    }

    for (var piece in allUniquePieces) {
      spriteMap[piece] = ChessPieceSprite(piece, appModel.pieceTheme);
    }
    _rebuildPieceCache();
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
  int? get warningTile => controller.warningTile;
  set warningTile(int? v) => controller.warningTile = v;
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

  /// Converts the tap position to a board tile and delegates to the controller.
  /// The Flame layer has zero routing logic — it is a pure renderer + input forwarder.
  void onTapDown(TapDownEvent event) {
    if (appModel.historyViewIndex != null) return;
    controller.handleTap(_vector2ToTile(event.localPosition));
  }

  // ── Rendering ──

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    width = size.x;
    tileSize = width! / 8;
    _buildBoardRects();
    _initSpritePositions();
    snapSprites();
  }

  /// Pre-builds all 64 tile [Rect] objects so [_drawBoard] can just iterate
  /// the cached lists rather than computing coordinates every frame.
  void _buildBoardRects() {
    _lightTileRects.clear();
    _darkTileRects.clear();
    final ts = tileSize ?? 0;
    for (int tileNo = 0; tileNo < 64; tileNo++) {
      final rect = Rect.fromLTWH(
        (tileNo % 8) * ts,
        (tileNo ~/ 8) * ts,
        ts,
        ts,
      );
      if ((tileNo + tileNo ~/ 8) % 2 == 0) {
        _lightTileRects.add(rect);
      } else {
        _darkTileRects.add(rect);
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
    _drawWarningHint(canvas);
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

    // Rebuild the piece list if the count changed (capture / promotion).
    // This is cheaper than creating a FollowedByIterable every tick.
    final currentCount =
        board.player1Pieces.length + board.player2Pieces.length;
    if (currentCount != _allPieces.length) {
      _rebuildPieceCache();
    }

    for (var piece in _allPieces) {
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
    _warningHintPaint = Paint()..color = const Color(0xAAFF3B30);
    _cachedThemeName = theme.name;
  }

  /// Rebuilds the flat piece list from both players' current piece lists.
  /// Called on construction and whenever a capture or promotion occurs.
  void _rebuildPieceCache() {
    _allPieces = [
      ...board.player1Pieces,
      ...board.player2Pieces,
    ];
  }

  void _initSpritePositions() {
    for (var piece in _allPieces) {
      spriteMap[piece]?.initSpritePosition(tileSize ?? 0, appModel);
    }
  }

  void snapSprites({bool snap = true}) {
    _rebuildPieceCache();
    if (snap) {
      for (var piece in _allPieces) {
        spriteMap[piece]?.snapToPiece(piece, tileSize ?? 0, appModel);
      }
    }
  }

  int _vector2ToTile(Vector2 vector2) {
    return (vector2.y / (tileSize ?? 0)).floor() * 8 +
        (vector2.x / (tileSize ?? 0)).floor();
  }

  void _drawBoard(Canvas canvas) {
    // Draw from pre-built Rect lists — avoids 64 float mults + Rect allocs per frame.
    for (final rect in _lightTileRects) {
      canvas.drawRect(rect, _lightTilePaint);
    }
    for (final rect in _darkTileRects) {
      canvas.drawRect(rect, _darkTilePaint);
    }
  }

  void _drawPieces(Canvas canvas) {
    for (var piece in _allPieces) {
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

  void _drawWarningHint(Canvas canvas) {
    if (warningTile != null) {
      canvas.drawRect(
        Rect.fromLTWH(
          getXFromTile(warningTile!, tileSize ?? 0),
          getYFromTile(warningTile!, tileSize ?? 0),
          tileSize ?? 0,
          tileSize ?? 0,
        ),
        _warningHintPaint,
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
