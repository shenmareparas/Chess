import 'dart:ui' as ui;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../model/app_model.dart';
import '../model/app_themes.dart';
import '../model/player.dart';
import 'chess_board.dart';
import 'chess_notation_service.dart';
import 'chess_piece.dart';
import 'move_calculation/move_classes/move.dart';
import 'shared_functions.dart';

/// Stateless bridge between the internal [ChessBoard] / [AppModel] state
/// and `chessground`'s [GameData] / [ChessboardSettings] API.
class ChessgroundAdapter {
  ChessgroundAdapter._();

  static final Map<String, PieceAssets> _pieceAssetsCache = {};
  static final Set<String> _paddedThemesLoaded = {};

  /// Preloads all 12 piece images for [pieceThemeName] into [ChessgroundImages]
  /// with a 10% transparent margin on each side to match the app's piece sizing.
  static Future<void> preloadPieceTheme(String pieceThemeName) async {
    final formatted = formatPieceTheme(pieceThemeName);
    if (_paddedThemesLoaded.contains(formatted)) return;
    _paddedThemesLoaded.add(formatted);

    final assets = buildPieceAssets(pieceThemeName);
    await Future.wait(assets.values.map(_loadPaddedAsset));
  }

  static Future<void> _loadPaddedAsset(AssetImage asset) async {
    try {
      final byteData = await rootBundle.load(asset.assetName);
      final codec = await ui.instantiateImageCodec(
        byteData.buffer.asUint8List(),
      );
      final frame = await codec.getNextFrame();
      final src = frame.image;

      final int w = src.width;
      final int h = src.height;
      const double inset = 0.10;
      final double padX = w * inset;
      final double padY = h * inset;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawImageRect(
        src,
        ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
        ui.Rect.fromLTWH(padX, padY, w - padX * 2, h - padY * 2),
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );
      final picture = recorder.endRecording();
      final padded = await picture.toImage(w, h);
      src.dispose();
      picture.dispose();

      ChessgroundImages.instance.add(asset, padded);
    } catch (_) {}
  }

  /// Converts an internal 0..63 board tile index (a8=0 .. h1=63)
  /// to a `dartchess` [dc.Square] (a1=0 .. h8=63).
  static dc.Square tileToSquare(int tile) {
    final file = tile % 8;
    final rank = 7 - (tile ~/ 8);
    return dc.Square.fromCoords(dc.File(file), dc.Rank(rank));
  }

  /// Converts a `dartchess` [dc.Square] (a1=0 .. h8=63)
  /// to an internal 0..63 board tile index (a8=0 .. h1=63).
  static int squareToTile(dc.Square square) {
    final rank = 7 - square.rank;
    return rank * 8 + square.file;
  }

  /// Converts a `dartchess` [dc.Role] to an internal [ChessPieceType].
  static ChessPieceType? roleToPieceType(dc.Role? role) {
    switch (role) {
      case dc.Role.queen:
        return ChessPieceType.queen;
      case dc.Role.rook:
        return ChessPieceType.rook;
      case dc.Role.bishop:
        return ChessPieceType.bishop;
      case dc.Role.knight:
        return ChessPieceType.knight;
      case dc.Role.king:
        return ChessPieceType.king;
      case dc.Role.pawn:
        return ChessPieceType.pawn;
      case null:
        return null;
    }
  }

  /// Builds the [GameData] snapshot consumed by [ChessboardController].
  static GameData buildGameData(AppModel appModel) {
    final controller = appModel.gameController;
    final board = controller?.board;
    if (controller == null || board == null) {
      return const GameData(
        fen: dc.kInitialFEN,
        playerSide: PlayerSide.none,
        sideToMove: dc.Side.white,
        validMoves: {},
      );
    }

    final position = ChessNotationService.instance.replayMoves(board.moveStack);
    final sideToMove =
        appModel.turn == Player.player1 ? dc.Side.white : dc.Side.black;

    final bool isInteractive = !appModel.gameOver &&
        !appModel.isAIsTurn &&
        appModel.historyViewIndex == null &&
        !appModel.promotionRequested;

    final PlayerSide playerSide;
    if (!isInteractive) {
      playerSide = PlayerSide.none;
    } else if (appModel.playingWithAI) {
      playerSide = appModel.playerSide == Player.player1
          ? PlayerSide.white
          : PlayerSide.black;
    } else {
      playerSide =
          sideToMove == dc.Side.white ? PlayerSide.white : PlayerSide.black;
    }

    final ValidMoves validMoves =
        isInteractive ? dc.makeLegalMoves(position) : const {};

    final Move? latest = controller.latestMove;
    final dc.Move? lastMove = (latest != null && appModel.showHints)
        ? dc.NormalMove(
            from: tileToSquare(latest.from),
            to: tileToSquare(latest.to),
          )
        : null;

    return GameData(
      fen: position.fen,
      playerSide: playerSide,
      sideToMove: sideToMove,
      validMoves: validMoves,
      lastMove: lastMove,
      // Check highlight is rendered as a crisp flat square in ChessBoardWidget
      // using theme.checkHint instead of chessground's blurred radial glow.
      kingSquareInCheck: null,
    );
  }

  /// Translates a `chessground` [dc.NormalMove] into internal `(fromTile, toTile)`
  /// coordinates, converting standard UCI castling (`e1g1` -> king-captures-rook `60 -> 63`)
  /// so [ChessBoard.push] recognizes it.
  static (int, int) chessgroundMoveToInternalTiles(
    dc.NormalMove move,
    ChessBoard board,
  ) {
    final int fromTile = squareToTile(move.from);
    int toTile = squareToTile(move.to);

    final movingPiece = board.tiles[fromTile];
    if (movingPiece != null && movingPiece.type == ChessPieceType.king) {
      if (fromTile == 60) {
        if (toTile == 62) toTile = 63; // White O-O
        if (toTile == 58) toTile = 56; // White O-O-O
      } else if (fromTile == 4) {
        if (toTile == 6) toTile = 7; // Black O-O
        if (toTile == 2) toTile = 0; // Black O-O-O
      }
    }

    return (fromTile, toTile);
  }

  /// Maps [AppModel.isBoardInverted] to `chessground` board [dc.Side] orientation.
  static dc.Side buildOrientation(bool isBoardInverted) {
    return isBoardInverted ? dc.Side.black : dc.Side.white;
  }

  /// Maps 2P piece-rotation preferences to [PieceOrientationBehavior].
  static PieceOrientationBehavior buildPieceOrientation(AppModel appModel) {
    if (appModel.enablePieceRotation &&
        !appModel.enableRotation &&
        !appModel.playingWithAI &&
        appModel.historyViewIndex == null &&
        appModel.playerCount == 2) {
      return appModel.flipOpponentPieces
          ? PieceOrientationBehavior.opponentUpsideDown
          : PieceOrientationBehavior.sideToPlay;
    }
    return PieceOrientationBehavior.facingUser;
  }

  /// Builds and caches a [PieceAssets] map from the app's existing PNG piece themes.
  static PieceAssets buildPieceAssets(String pieceThemeName) {
    final formatted = formatPieceTheme(pieceThemeName);
    return _pieceAssetsCache.putIfAbsent(formatted, () {
      AssetImage img(String piece, String color) =>
          AssetImage('assets/images/pieces/$formatted/${piece}_$color.png');

      return {
        dc.PieceKind.whiteKing: img('king', 'white'),
        dc.PieceKind.whiteQueen: img('queen', 'white'),
        dc.PieceKind.whiteRook: img('rook', 'white'),
        dc.PieceKind.whiteBishop: img('bishop', 'white'),
        dc.PieceKind.whiteKnight: img('knight', 'white'),
        dc.PieceKind.whitePawn: img('pawn', 'white'),
        dc.PieceKind.blackKing: img('king', 'black'),
        dc.PieceKind.blackQueen: img('queen', 'black'),
        dc.PieceKind.blackRook: img('rook', 'black'),
        dc.PieceKind.blackBishop: img('bishop', 'black'),
        dc.PieceKind.blackKnight: img('knight', 'black'),
        dc.PieceKind.blackPawn: img('pawn', 'black'),
      };
    });
  }

  /// Converts an [AppTheme] into a [ChessboardColorScheme].
  static ChessboardColorScheme buildColorScheme(AppTheme theme) {
    final bg = SolidColorChessboardBackground(
      lightSquare: theme.lightTile,
      darkSquare: theme.darkTile,
    );
    return ChessboardColorScheme(
      lightSquare: theme.lightTile,
      darkSquare: theme.darkTile,
      background: bg,
      whiteCoordBackground: bg,
      blackCoordBackground: bg,
      lastMove: HighlightDetails(solidColor: theme.latestMove),
      selected: HighlightDetails(solidColor: theme.moveHint),
      validMoves: theme.moveHint,
      validPremoves: theme.moveHint.withValues(alpha: 0.4),
    );
  }
}
