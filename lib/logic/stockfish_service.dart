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

  Completer<void>? _readyCompleter;

  void init() {
    if (_engine != null) return;
    _engine = Stockfish();
    _stdoutSubscription = _engine!.stdout.listen((line) {
      debugPrint("[Stockfish stdout] $line");
      if (line == 'readyok') {
        if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
          _readyCompleter!.complete();
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

  Future<void> _waitUntilReady() async {
    init();
    if (_engine!.state.value == StockfishState.ready) return;

    final completer = Completer<void>();
    void listener() {
      if (_engine!.state.value == StockfishState.ready) {
        _engine!.state.removeListener(listener);
        completer.complete();
      } else if (_engine!.state.value == StockfishState.error) {
        _engine!.state.removeListener(listener);
        completer.completeError(StateError('Stockfish engine error'));
      }
    }

    _engine!.state.addListener(listener);

    if (_engine!.state.value == StockfishState.ready) {
      _engine!.state.removeListener(listener);
      return;
    }

    return completer.future.timeout(const Duration(seconds: 5));
  }

  Future<Move> getBestMove(String movesString, int difficulty) async {
    try {
      await _waitUntilReady();
    } catch (_) {
      return Move(0, 0);
    }

    _readyCompleter = Completer<void>();
    debugPrint("[Stockfish stdin] uci");
    _engine!.stdin = 'uci';
    debugPrint("[Stockfish stdin] isready");
    _engine!.stdin = 'isready';

    try {
      await _readyCompleter!.future.timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint("[Stockfish] isready timeout or error: $e");
    }

    _moveCompleter = Completer<String>();

    int skillLevel = 0;
    int depth = 5;
    int moveTime = 300;
    switch (difficulty) {
      case 1:
        skillLevel = 3;
        depth = 3;
        moveTime = 150;
        break;
      case 2:
        skillLevel = 7;
        depth = 5;
        moveTime = 300;
        break;
      case 3:
        skillLevel = 12;
        depth = 8;
        moveTime = 600;
        break;
      case 4:
        skillLevel = 16;
        depth = 12;
        moveTime = 1200;
        break;
      case 5:
        skillLevel = 20;
        depth = 16;
        moveTime = 2000;
        break;
    }

    debugPrint(
        "[Stockfish stdin] setoption name Skill Level value $skillLevel");
    _engine!.stdin = 'setoption name Skill Level value $skillLevel';

    if (movesString.trim().isEmpty) {
      debugPrint("[Stockfish stdin] position startpos");
      _engine!.stdin = 'position startpos';
    } else {
      debugPrint("[Stockfish stdin] position startpos moves $movesString");
      _engine!.stdin = 'position startpos moves $movesString';
    }

    debugPrint("[Stockfish stdin] go depth $depth movetime $moveTime");
    _engine!.stdin = 'go depth $depth movetime $moveTime';

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
  }
}
