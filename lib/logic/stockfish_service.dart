import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:multistockfish/multistockfish.dart';
import 'chess_piece.dart';
import 'move_calculation/move_classes/move.dart';

class StockfishService {
  static final StockfishService instance = StockfishService._();
  StockfishService._();

  Stockfish? _engine;
  Completer<String>? _moveCompleter;
  Completer<void>? _readyOkCompleter;
  Future<Stockfish>? _engineInitFuture;
  bool _isDisposed = false;

  void _handleStdoutLine(String line) {
    if (kDebugMode) {
      if (line == 'readyok' || line.startsWith('bestmove')) {
        debugPrint("[Stockfish stdout] $line");
      }
    }
    if (line == 'readyok') {
      if (_readyOkCompleter != null && !_readyOkCompleter!.isCompleted) {
        _readyOkCompleter!.complete();
      }
    }
    if (line.startsWith('bestmove')) {
      final parts = line.split(' ');
      if (parts.length >= 2) {
        final bestMove = parts[1];
        if (_moveCompleter != null && !_moveCompleter!.isCompleted) {
          _moveCompleter!.complete(bestMove);
        }
      }
    }
  }

  /// Ensures an active [Stockfish] engine instance of flavor [StockfishFlavor.light].
  /// Guards against concurrent initialization calls to prevent flavor slot conflicts.
  Future<Stockfish> _ensureEngine() async {
    _isDisposed = false;
    if (_engine != null && _engine!.state.value == StockfishState.ready) {
      return _engine!;
    }
    if (_engineInitFuture != null) {
      return _engineInitFuture!;
    }

    _engineInitFuture = _createEngine();
    try {
      final engine = await _engineInitFuture!;
      if (_isDisposed) {
        await engine.dispose();
        throw StateError('StockfishService was disposed during initialization');
      }
      _engine = engine;
      return engine;
    } finally {
      _engineInitFuture = null;
    }
  }

  Future<Stockfish> _createEngine() async {
    if (_engine != null) {
      try {
        await _engine!.dispose();
      } catch (_) {}
      _engine = null;
    }

    _readyOkCompleter = Completer<void>();

    final engine = await Stockfish.create(
      flavor: StockfishFlavor.light,
      onStdout: _handleStdoutLine,
    );

    if (kDebugMode) {
      debugPrint('[Stockfish stdin] setoption name Hash value 16');
      debugPrint('[Stockfish stdin] setoption name Threads value 1');
    }
    engine.stdin = 'setoption name Hash value 16';
    engine.stdin = 'setoption name Threads value 1';

    if (kDebugMode) {
      debugPrint('[Stockfish stdin] isready');
    }
    engine.stdin = 'isready';
    await _readyOkCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint(
            '[Stockfish] WARNING: readyok never received — proceeding anyway');
      },
    );

    return engine;
  }

  /// Initiates engine startup in the background if not already started.
  void init() {
    _ensureEngine();
  }

  /// Synchronizes with the Stockfish engine via `isready` → `readyok`.
  Future<void> _waitUntilReady() async {
    final engine = await _ensureEngine();
    _readyOkCompleter = Completer<void>();
    if (kDebugMode) {
      debugPrint('[Stockfish stdin] isready');
    }
    engine.stdin = 'isready';
    await _readyOkCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint(
            '[Stockfish] WARNING: readyok never received — proceeding anyway');
      },
    );
  }

  Future<Move> getBestMove(String movesString, int difficulty) async {
    Stockfish engine;
    try {
      engine = await _ensureEngine();
      await _waitUntilReady();
    } catch (e) {
      debugPrint('[Stockfish] Engine not ready: $e');
      return Move(0, 0);
    }

    _moveCompleter = Completer<String>();

    int moveTime = 300;
    int depth = 5;
    if (difficulty == 1) {
      moveTime = 100;
      depth = 1;
      if (kDebugMode) {
        debugPrint(
            "[Stockfish stdin] setoption name UCI_LimitStrength value false");
      }
      engine.stdin = 'setoption name UCI_LimitStrength value false';
      if (kDebugMode) {
        debugPrint("[Stockfish stdin] setoption name Skill Level value 0");
      }
      engine.stdin = 'setoption name Skill Level value 0';
    } else if (difficulty == 2) {
      moveTime = 200;
      depth = 3;
      if (kDebugMode) {
        debugPrint(
            "[Stockfish stdin] setoption name UCI_LimitStrength value false");
      }
      engine.stdin = 'setoption name UCI_LimitStrength value false';
      if (kDebugMode) {
        debugPrint("[Stockfish stdin] setoption name Skill Level value 0");
      }
      engine.stdin = 'setoption name Skill Level value 0';
    } else {
      int elo = 1200;
      if (difficulty == 3) {
        elo = 1200;
        moveTime = 400;
      } else if (difficulty == 4) {
        elo = 1600;
        moveTime = 800;
      } else if (difficulty == 5) {
        elo = 2000;
        moveTime = 1500;
      }
      if (kDebugMode) {
        debugPrint(
            "[Stockfish stdin] setoption name UCI_LimitStrength value true");
      }
      engine.stdin = 'setoption name UCI_LimitStrength value true';
      if (kDebugMode) {
        debugPrint("[Stockfish stdin] setoption name UCI_Elo value $elo");
      }
      engine.stdin = 'setoption name UCI_Elo value $elo';
    }

    if (movesString.trim().isEmpty) {
      if (kDebugMode) debugPrint("[Stockfish stdin] position startpos");
      engine.stdin = 'position startpos';
    } else {
      if (kDebugMode) {
        debugPrint("[Stockfish stdin] position startpos moves $movesString");
      }
      engine.stdin = 'position startpos moves $movesString';
    }

    if (difficulty <= 2) {
      if (kDebugMode) {
        debugPrint("[Stockfish stdin] go depth $depth movetime $moveTime");
      }
      engine.stdin = 'go depth $depth movetime $moveTime';
    } else {
      if (kDebugMode) debugPrint("[Stockfish stdin] go movetime $moveTime");
      engine.stdin = 'go movetime $moveTime';
    }

    try {
      final uciMove = await _moveCompleter!.future.timeout(
        Duration(milliseconds: moveTime + 1500),
        onTimeout: () => 'none',
      );
      if (kDebugMode) debugPrint("[Stockfish] computed best move: $uciMove");
      if (uciMove == 'none' || uciMove.length < 4) {
        return Move(0, 0);
      }
      return _uciToMove(uciMove);
    } catch (_) {
      return Move(0, 0);
    }
  }

  Move _uciToMove(String uci) {
    // Map standard UCI castling moves to the custom board's king-on-rook castling representation
    if (uci == 'e1g1') {
      return Move(60, 63);
    } else if (uci == 'e1c1') {
      return Move(60, 56);
    } else if (uci == 'e8g8') {
      return Move(4, 7);
    } else if (uci == 'e8c8') {
      return Move(4, 0);
    }

    int fromFile = uci.codeUnitAt(0) - 97;
    int fromRank = 8 - int.parse(uci[1]);
    int toFile = uci.codeUnitAt(2) - 97;
    int toRank = 8 - int.parse(uci[3]);

    int from = fromRank * 8 + fromFile;
    int to = toRank * 8 + toFile;

    var promo = ChessPieceType.promotion;
    if (uci.length > 4) {
      switch (uci[4]) {
        case 'q':
          promo = ChessPieceType.queen;
          break;
        case 'r':
          promo = ChessPieceType.rook;
          break;
        case 'b':
          promo = ChessPieceType.bishop;
          break;
        case 'n':
          promo = ChessPieceType.knight;
          break;
      }
    }

    return Move(from, to, promotionType: promo);
  }

  static String msoToUCI(dynamic mso) {
    if (mso.castled == true) {
      int kingTile = mso.move.from;
      int otherTile = mso.move.to;
      if (mso.movedPiece?.type == ChessPieceType.rook) {
        kingTile = mso.move.to;
        otherTile = mso.move.from;
      }
      if (kingTile == 60) {
        if (otherTile == 63) return 'e1g1';
        if (otherTile == 56) return 'e1c1';
      } else if (kingTile == 4) {
        if (otherTile == 7) return 'e8g8';
        if (otherTile == 0) return 'e8c8';
      }
    }

    Move move = mso.move;
    int from = move.from;
    int to = move.to;

    int fromFile = from % 8;
    int fromRank = 8 - (from ~/ 8);
    int toFile = to % 8;
    int toRank = 8 - (to ~/ 8);

    String fromStr = '${String.fromCharCode(97 + fromFile)}$fromRank';
    String toStr = '${String.fromCharCode(97 + toFile)}$toRank';

    String promo = '';
    if (mso.promotion && mso.promotionType != null) {
      switch (mso.promotionType) {
        case ChessPieceType.queen:
          promo = 'q';
          break;
        case ChessPieceType.rook:
          promo = 'r';
          break;
        case ChessPieceType.bishop:
          promo = 'b';
          break;
        case ChessPieceType.knight:
          promo = 'n';
          break;
        default:
          break;
      }
    }
    return '$fromStr$toStr$promo';
  }

  Future<void> dispose() async {
    _isDisposed = true;
    final engine = _engine;
    _engine = null;
    _engineInitFuture = null;
    if (engine != null) {
      try {
        await engine.dispose();
      } catch (e) {
        if (kDebugMode) debugPrint('[Stockfish] Error during dispose: $e');
      }
    }
    if (_moveCompleter != null && !_moveCompleter!.isCompleted) {
      _moveCompleter!.completeError(StateError('Stockfish service disposed'));
    }
    _moveCompleter = null;
    _readyOkCompleter = null;
  }
}
