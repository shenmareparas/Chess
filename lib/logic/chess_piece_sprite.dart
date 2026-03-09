import 'package:en_passant/model/app_model.dart';
import 'package:en_passant/model/player.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';

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
    var destX = getXFromTile(tile ?? 0, tileSize, appModel);
    var destY = getYFromTile(tile ?? 0, tileSize, appModel);
    // Smooth interpolation using frame-rate independent lerp
    double t = 1.0 - _pow(1.0 - _lerpSpeed * dt, 1);
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

  static double _pow(double base, int exp) {
    if (base <= 0) return 0;
    return base;
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
    spriteX = getXFromTile(tile ?? 0, tileSize, appModel);
    spriteY = getYFromTile(tile ?? 0, tileSize, appModel);
  }

  void snapToPiece(ChessPiece piece, double tileSize, AppModel appModel) {
    type = piece.type;
    tile = piece.tile;
    spriteX = getXFromTile(tile ?? 0, tileSize, appModel);
    spriteY = getYFromTile(tile ?? 0, tileSize, appModel);
  }
}
