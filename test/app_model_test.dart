import 'package:en_passant/logic/game_controller.dart';
import 'package:en_passant/model/app_model.dart';
import 'package:en_passant/model/player.dart';
import 'package:en_passant/model/user_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppModel ELO and History Tests', () {
    test('getDifficultyElo maps correctly', () {
      expect(AppModel.getDifficultyElo(1), 400);
      expect(AppModel.getDifficultyElo(2), 800);
      expect(AppModel.getDifficultyElo(3), 1200);
      expect(AppModel.getDifficultyElo(4), 1600);
      expect(AppModel.getDifficultyElo(5), 2000);
    });

    test('history navigation clears active game selections', () async {
      final prefs = UserPreferences();
      await prefs.load();
      final appModel = AppModel(prefs: prefs);
      final controller = GameController(appModel);
      appModel.gameController = controller;

      // Simulate a selected piece and valid moves
      controller.selectedPiece = controller.board.player1Pieces.first;
      controller.validMoves = [16, 24];
      controller.warningTile = 12;

      // Navigate history
      appModel.setHistoryViewIndex(0);

      // Verify that active selections and hints are cleared
      expect(controller.selectedPiece, isNull);
      expect(controller.validMoves, isEmpty);
      expect(controller.warningTile, isNull);
    });

    test('king check highlight restored on game resume', () async {
      final prefs = UserPreferences();
      await prefs.load();

      // Set up mocked shared preferences containing a game state in check
      SharedPreferences.setMockInitialValues({
        'chess_game_state': true,
        'playerCount': 1,
        'aiDifficulty': 3,
        'playerSide': Player.player1.index,
        'selectedSide': Player.player1.index,
        'selectedSideP1': Player.player1.index,
        'timeLimit': 600,
        'gameOver': false,
        'stalemate': false,
        'timerIncrement': 0,
        'timerMode': 'increment',
        'availableUndos': 1,
        'player1TimeLeftMs': 600000,
        'player2TimeLeftMs': 600000,
        'moves': [
          '53-45',
          '12-28',
          '54-38',
          '3-39'
        ], // Fool's Mate sequence placing White (Player.player1) in check
      });

      final appModel = AppModel(prefs: prefs);
      await appModel.restoreGameState();

      // Verify that the game restored successfully and player1 (White) is in check
      expect(appModel.turn, Player.player1);
      expect(
          appModel.gameController!.board.kingInCheck(Player.player1), isTrue);

      // Check if the checkHintTile is correctly highlighted at the White king's tile (e1 = tile 60)
      final whiteKingTile =
          appModel.gameController!.board.kingForPlayer(Player.player1)?.tile;
      expect(appModel.gameController!.checkHintTile, whiteKingTile);
    });

    test('winner is correctly determined as the active player on checkmate',
        () async {
      final prefs = UserPreferences();
      await prefs.load();
      final appModel = AppModel(prefs: prefs);

      // Simulate human as White, playing with AI, and White delivers checkmate (turn = player1)
      appModel.playerSide = Player.player1;
      appModel.setPlayerCount(1); // Set playing with AI (playerCount = 1)
      appModel.turn = Player.player1;

      // When game ends with time remaining on both sides
      final userWon = appModel.audio.didUserWin(
        playingWithAI: appModel.playingWithAI,
        playerSide: appModel.playerSide,
        turn: appModel.turn,
        player1TimeLeft: const Duration(minutes: 5),
        player2TimeLeft: const Duration(minutes: 5),
      );

      // User (White) delivered checkmate on their turn, so they should win
      expect(userWon, isTrue);
    });

    test(
        'winner is correctly determined as the active player on checkmate in untimed games',
        () async {
      final prefs = UserPreferences();
      await prefs.load();
      final appModel = AppModel(prefs: prefs);

      // Simulate human as White, playing with AI, and White delivers checkmate (turn = player1)
      appModel.playerSide = Player.player1;
      appModel.setPlayerCount(1);
      appModel.turn = Player.player1;

      // In an untimed game, both time left values are Duration.zero
      final userWon = appModel.audio.didUserWin(
        playingWithAI: appModel.playingWithAI,
        playerSide: appModel.playerSide,
        turn: appModel.turn,
        player1TimeLeft: Duration.zero,
        player2TimeLeft: Duration.zero,
      );

      // User (White) delivered checkmate, so they should win
      expect(userWon, isTrue);
    });
  });
}
