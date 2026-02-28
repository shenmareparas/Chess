import 'dart:convert';

import 'package:en_passant/logic/chess_piece.dart';
import 'package:en_passant/model/app_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'move_calculation/move_classes/move.dart';

const _gameStateKey = 'saved_game_state';

class GameStateStorage {
  static Future<void> saveGameState(AppModel appModel) async {
    if (appModel.game == null) return;

    final board = appModel.game!.board;
    final moves = board.moveStack.map((mso) {
      return {
        'from': mso.move.from,
        'to': mso.move.to,
        'promotionType': mso.promotionType?.index,
      };
    }).toList();

    final state = {
      'playerCount': appModel.playerCount,
      'aiDifficulty': appModel.aiDifficulty,
      'playerSide': appModel.playerSide.index,
      'selectedSide': appModel.selectedSide.index,
      'timeLimit': appModel.timeLimit,
      'turn': appModel.turn.index,
      'gameOver': appModel.gameOver,
      'stalemate': appModel.stalemate,
      'player1TimeLeftMs': appModel.player1TimeLeft.inMilliseconds,
      'player2TimeLeftMs': appModel.player2TimeLeft.inMilliseconds,
      'pieceTheme': appModel.pieceTheme,
      'moves': moves,
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gameStateKey, jsonEncode(state));
  }

  static Future<Map<String, dynamic>?> loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_gameStateKey);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      await clearGameState();
      return null;
    }
  }

  static Future<void> clearGameState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_gameStateKey);
  }

  static Future<bool> hasSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_gameStateKey);
  }

  /// Parses the saved moves list from the state map.
  static List<Move> parseMoves(Map<String, dynamic> state) {
    final movesJson = state['moves'] as List<dynamic>;
    return movesJson.map((m) {
      final promotionIndex = m['promotionType'] as int?;
      final promotionType = promotionIndex != null
          ? ChessPieceType.values[promotionIndex]
          : ChessPieceType.promotion;
      return Move(m['from'] as int, m['to'] as int,
          promotionType: promotionType);
    }).toList();
  }
}
