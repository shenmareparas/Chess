

import 'package:shared_preferences/shared_preferences.dart';

import '../model/app_model.dart';

import 'chess_piece.dart';
import 'move_calculation/move_classes/move.dart';

// Constants for SharedPreferences keys
const String _playerCountKey = 'playerCount';
const String _aiDifficultyKey = 'aiDifficulty';
const String _playerSideKey = 'playerSide';
const String _selectedSideKey = 'selectedSide';
const String _timeLimitKey = 'timeLimit';
const String _player1TimeLeftMsKey = 'player1TimeLeftMs';
const String _player2TimeLeftMsKey = 'player2TimeLeftMs';
const String _gameOverKey = 'gameOver';
const String _stalemateKey = 'stalemate';
const String _movesKey = 'moves';
const String _gameStateKey = 'chess_game_state';

class GameStateStorage {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<void> saveGameState(AppModel appModel) async {
    if (appModel.gameController == null) return;
    var gameController = appModel.gameController;
    if (gameController == null) return;

    final prefs = await _getPrefs();
    await prefs.setBool(_gameStateKey, true);

    // Save game metadata
    await prefs.setInt(_playerCountKey, appModel.playerCount);
    await prefs.setInt(_aiDifficultyKey, appModel.aiDifficulty);
    await prefs.setInt(_playerSideKey, appModel.playerSide.index);
    await prefs.setInt(_selectedSideKey, appModel.selectedSide.index);
    await prefs.setInt(_timeLimitKey, appModel.timeLimit);
    await prefs.setInt(_player1TimeLeftMsKey, appModel.player1TimeLeft.value.inMilliseconds);
    await prefs.setInt(_player2TimeLeftMsKey, appModel.player2TimeLeft.value.inMilliseconds);
    await prefs.setBool(_gameOverKey, appModel.gameOver);
    await prefs.setBool(_stalemateKey, appModel.stalemate);

    // Save move history
    var moveList = gameController.board.moveStack.map((mso) {
      if (mso.promotion) {
        return '${mso.move.from}-${mso.move.to}-${_promotionChar(mso.promotionType!)}';
      }
      return '${mso.move.from}-${mso.move.to}';
    }).toList();
    await prefs.setStringList(_movesKey, moveList);
  }

  static Future<Map<String, dynamic>?> loadGameState() async {
    final prefs = await _getPrefs();

    // Check if any game state exists
    if (!prefs.containsKey(_gameStateKey)) {
      return null;
    }

    try {
      final Map<String, dynamic> state = {
        'playerCount': prefs.getInt(_playerCountKey),
        'aiDifficulty': prefs.getInt(_aiDifficultyKey),
        'playerSide': prefs.getInt(_playerSideKey),
        'selectedSide': prefs.getInt(_selectedSideKey),
        'timeLimit': prefs.getInt(_timeLimitKey),
        'player1TimeLeftMs': prefs.getInt(_player1TimeLeftMsKey),
        'player2TimeLeftMs': prefs.getInt(_player2TimeLeftMsKey),
        'gameOver': prefs.getBool(_gameOverKey),
        'stalemate': prefs.getBool(_stalemateKey),
        'moves': prefs.getStringList(_movesKey),
      };
      return state;
    } catch (_) {
      await clearGameState();
      return null;
    }
  }

  static Future<void> clearGameState() async {
    final prefs = await _getPrefs();
    await prefs.remove(_gameStateKey);
    await prefs.remove(_playerCountKey);
    await prefs.remove(_aiDifficultyKey);
    await prefs.remove(_playerSideKey);
    await prefs.remove(_selectedSideKey);
    await prefs.remove(_timeLimitKey);
    await prefs.remove(_player1TimeLeftMsKey);
    await prefs.remove(_player2TimeLeftMsKey);
    await prefs.remove(_gameOverKey);
    await prefs.remove(_stalemateKey);
    await prefs.remove(_movesKey);
  }

  static Future<bool> hasSavedGame() async {
    final prefs = await _getPrefs();
    return prefs.containsKey(_gameStateKey);
  }

  /// Parses the saved moves list from the state map.
  static List<Move> parseMoves(Map<String, dynamic> state) {
    final movesJson = state['moves'] as List<dynamic>;
    return movesJson.map((m) {
      final parts = (m as String).split('-');
      final from = int.parse(parts[0]);
      final to = int.parse(parts[1]);
      ChessPieceType? promotionType;
      if (parts.length == 3) {
        promotionType = _parsePromotionChar(parts[2]);
      }
      return Move(from, to, promotionType: promotionType ?? ChessPieceType.promotion);
    }).toList();
  }

  static String _promotionChar(ChessPieceType type) {
    switch (type) {
      case ChessPieceType.queen:
        return 'q';
      case ChessPieceType.rook:
        return 'r';
      case ChessPieceType.knight:
        return 'n';
      case ChessPieceType.bishop:
        return 'b';
      case ChessPieceType.pawn:
        return 'p';
      case ChessPieceType.king:
        return 'k';
      case ChessPieceType.promotion:
        return '';
    }
  }

  static ChessPieceType? _parsePromotionChar(String char) {
    switch (char) {
      case 'q':
        return ChessPieceType.queen;
      case 'r':
        return ChessPieceType.rook;
      case 'n':
        return ChessPieceType.knight;
      case 'b':
        return ChessPieceType.bishop;
      default:
        return null; // Or throw an error if unexpected
    }
  }
}
