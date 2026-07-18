import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:stockfish/stockfish.dart';
import 'chess_piece.dart';
import 'move_calculation/move_classes/move.dart';

class StockfishService {
  static final StockfishService instance = StockfishService._();
  StockfishService._();

  Stockfish? _engine;
  StreamSubscription? _stdoutSubscription;
  Completer<String>? _moveCompleter;

  /// Completer that resolves once the UCI handshake (`uci` → `readyok`) has
  /// completed for this engine instance. Null means the handshake hasn't
  /// started yet; completed means the engine is ready to accept commands.
  Completer<void>? _uciReadyCompleter;
  bool _configured = false;

  void init() {
    if (_engine != null) return;
    _engine = Stockfish();
    _uciReadyCompleter = Completer<void>();
    _stdoutSubscription = _engine!.stdout.listen((line) {
      if (kDebugMode) {
        if (line == 'readyok' || line.startsWith('bestmove')) {
          debugPrint("[Stockfish stdout] $line");
        }
      }
      if (line == 'readyok') {
        if (_uciReadyCompleter != null && !_uciReadyCompleter!.isCompleted) {
          _uciReadyCompleter!.complete();
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
    });
  }

  /// Waits for the Stockfish process to reach [StockfishState.ready] and then
  /// performs the one-time UCI handshake (`uci` + `isready` → `readyok`).
  /// Subsequent calls return immediately once the completer is resolved.
  Future<void> _waitUntilReady() async {
    init();

    // Wait for the native process to start.
    if (_engine!.state.value != StockfishState.ready) {
      final engineReady = Completer<void>();
      void listener() {
        if (_engine!.state.value == StockfishState.ready) {
          _engine!.state.removeListener(listener);
          if (!engineReady.isCompleted) engineReady.complete();
        } else if (_engine!.state.value == StockfishState.error) {
          _engine!.state.removeListener(listener);
          if (!engineReady.isCompleted) {
            engineReady.completeError(StateError('Stockfish engine error'));
          }
        }
      }

      _engine!.state.addListener(listener);
      // Re-check in case state changed between the first check and addListener.
      if (_engine!.state.value == StockfishState.ready) {
        _engine!.state.removeListener(listener);
      } else {
        await engineReady.future.timeout(const Duration(seconds: 10));
      }
    }

    // Perform the UCI handshake exactly once per engine instance.
    if (!_uciReadyCompleter!.isCompleted) {
      if (kDebugMode) {
        debugPrint('[Stockfish stdin] uci');
      }
      _engine!.stdin = 'uci';
      if (kDebugMode) {
        debugPrint('[Stockfish stdin] isready');
      }
      _engine!.stdin = 'isready';
    }

    // Await the single shared completer — all callers that arrive before
    // `readyok` will suspend here and wake up together.
    await _uciReadyCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint(
            '[Stockfish] WARNING: readyok never received — proceeding anyway');
      },
    );

    // Apply native configurations only once after the initial handshake finishes.
    if (!_configured) {
      _configured = true;
      _engine!.stdin = 'setoption name Use NNUE value false';
      _engine!.stdin = 'setoption name Hash value 16';
      _engine!.stdin = 'setoption name Threads value 1';
    }
  }

  Future<Move> getBestMove(String movesString, int difficulty) async {
    try {
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
      debugPrint(
          "[Stockfish stdin] setoption name UCI_LimitStrength value false");
      _engine!.stdin = 'setoption name UCI_LimitStrength value false';
      debugPrint("[Stockfish stdin] setoption name Skill Level value 0");
      _engine!.stdin = 'setoption name Skill Level value 0';
    } else if (difficulty == 2) {
      moveTime = 200;
      depth = 3;
      debugPrint(
          "[Stockfish stdin] setoption name UCI_LimitStrength value false");
      _engine!.stdin = 'setoption name UCI_LimitStrength value false';
      debugPrint("[Stockfish stdin] setoption name Skill Level value 0");
      _engine!.stdin = 'setoption name Skill Level value 0';
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
      debugPrint(
          "[Stockfish stdin] setoption name UCI_LimitStrength value true");
      _engine!.stdin = 'setoption name UCI_LimitStrength value true';
      debugPrint("[Stockfish stdin] setoption name UCI_Elo value $elo");
      _engine!.stdin = 'setoption name UCI_Elo value $elo';
    }

    if (movesString.trim().isEmpty) {
      debugPrint("[Stockfish stdin] position startpos");
      _engine!.stdin = 'position startpos';
    } else {
      debugPrint("[Stockfish stdin] position startpos moves $movesString");
      _engine!.stdin = 'position startpos moves $movesString';
    }

    if (difficulty <= 2) {
      debugPrint("[Stockfish stdin] go depth $depth movetime $moveTime");
      _engine!.stdin = 'go depth $depth movetime $moveTime';
    } else {
      debugPrint("[Stockfish stdin] go movetime $moveTime");
      _engine!.stdin = 'go movetime $moveTime';
    }

    try {
      final uciMove = await _moveCompleter!.future.timeout(
        Duration(milliseconds: moveTime + 1500),
        onTimeout: () => 'none',
      );
      debugPrint("[Stockfish] computed best move: $uciMove");
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

  void dispose() {
    _stdoutSubscription?.cancel();
    _stdoutSubscription = null;
    _engine?.dispose();
    _engine = null;
    if (_moveCompleter != null && !_moveCompleter!.isCompleted) {
      _moveCompleter!.completeError(StateError('Disposed'));
    }
    _moveCompleter = null;
    _uciReadyCompleter = null;
    _configured = false;
  }
}
