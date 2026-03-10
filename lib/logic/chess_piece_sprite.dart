import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';

import '../model/app_model.dart';
import '../model/player.dart';
import 'chess_piece.dart';
import 'shared_functions.dart';

class ChessPieceSprite {
  ChessPieceType? type;
  String? pieceTheme;
  int? tile;
  Sprite? sprite;
  double? spriteX;
  double? spriteY;

  ChessPieceSprite(ChessPiece piece, String pieceTheme) {
    this.tile = piece.tile;
    this.type = piece.type;
    this.pieceTheme = pieceTheme;
    initSprite(piece);
  }

  /// Smooth interpolation factor per frame (0 = no movement, 1 = snap)
  static const double _lerpSpeed = 12.0;

  void update(double tileSize, AppModel appModel, ChessPiece piece, double dt) {
    if (piece.type != this.type || appModel.pieceTheme != this.pieceTheme) {
      this.type = piece.type;
      this.pieceTheme = appModel.pieceTheme;
      initSprite(piece);
    }
    if (piece.tile != this.tile) {
      this.tile = piece.tile;
    }
    var destX = getXFromTile(tile ?? 0, tileSize);
    var destY = getYFromTile(tile ?? 0, tileSize);
    // Smooth interpolation using frame-rate independent exponential decay
    double t = 1.0 - math.exp(-_lerpSpeed * dt);
    if (t > 1.0) t = 1.0;
    if ((destX - (spriteX ?? 0)).abs() <= 0.5) {
      spriteX = destX;
    } else if (spriteX != null) {
      spriteX = spriteX! + (destX - spriteX!) * t;
    }
    if ((destY - (spriteY ?? 0)).abs() <= 0.5) {
      spriteY = destY;
    } else if (spriteY != null) {
      spriteY = spriteY! + (destY - spriteY!) * t;
    }
  }


  void initSprite(ChessPiece piece) async {
    String color = piece.player == Player.player1 ? 'white' : 'black';
    String pieceName = pieceTypeToString(piece.type);
    if (piece.type == ChessPieceType.promotion) {
      pieceName = 'pawn';
    }
    sprite = Sprite(await Flame.images.load(
        'pieces/${formatPieceTheme(pieceTheme ?? "")}/${pieceName}_$color.png'));
  }

  void initSpritePosition(double tileSize, AppModel appModel) {
    spriteX = getXFromTile(tile ?? 0, tileSize);
    spriteY = getYFromTile(tile ?? 0, tileSize);
  }

  void snapToPiece(ChessPiece piece, double tileSize, AppModel appModel) {
    type = piece.type;
    tile = piece.tile;
    spriteX = getXFromTile(tile ?? 0, tileSize);
    spriteY = getYFromTile(tile ?? 0, tileSize);
  }
}
