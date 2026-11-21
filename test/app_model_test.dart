import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../lib/logic/ad_service.dart';
import '../lib/logic/chess_piece.dart';
import '../lib/logic/game_controller.dart';
import '../lib/logic/game_state_storage.dart';
import '../lib/logic/move_calculation/move_classes/move.dart';
import '../lib/logic/move_calculation/move_classes/move_meta.dart';
import '../lib/model/app_model.dart';
import '../lib/model/player.dart';
import '../lib/model/user_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AdService.instance.setAdFree(true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('org.lichess/sound_effect'),
      (MethodCall methodCall) async => null,
    );
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

    test(
        'history navigation updates checkHintTile accurately and clears stale check highlights',
        () async {
      final prefs = UserPreferences();
      await prefs.load();
      final appModel = AppModel(prefs: prefs);
      final controller = GameController(appModel);
      appModel.gameController = controller;

      // Simulate live game has checkHintTile active (e.g. from a recent check)
      controller.checkHintTile = 36;

      // Create two moves: 1. e4 (52->36), 1... e5 (12->28)
      final meta1 = MoveMeta(Move(52, 36), Player.player1, ChessPieceType.pawn);
      final meta2 = MoveMeta(Move(12, 28), Player.player2, ChessPieceType.pawn);
      controller.board.push(meta1.move!);
      controller.board.push(meta2.move!);
      appModel.moveMetaList.addAll([meta1, meta2]);

      // Navigate to move 0 (e4) where neither king is in check
      appModel.setHistoryViewIndex(0);

      // The stale checkHintTile MUST be cleared
      expect(controller.checkHintTile, isNull);

      // Return to live state where neither king is in check
      appModel.setHistoryViewIndex(null);
      expect(controller.checkHintTile, isNull);
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

    test('exitChessView clears saved game and prevents subsequent saves',
        () async {
      final prefs = UserPreferences();
      await prefs.load();
      final appModel = AppModel(prefs: prefs);
      appModel.newGame();

      // Save game state
      appModel.saveGameStateImmediate();
      expect(await GameStateStorage.hasSavedGame(), isTrue);

      // Exit without saving
      await appModel.exitChessView();
      expect(appModel.isExiting, isTrue);
      expect(await GameStateStorage.hasSavedGame(), isFalse);
      expect(appModel.hasSavedGame, isFalse);

      // Attempting to save after exit should be blocked
      appModel.saveGameStateImmediate();
      expect(await GameStateStorage.hasSavedGame(), isFalse);
    });

    test('saveAndExitChessView saves game state and marks isExiting', () async {
      final prefs = UserPreferences();
      await prefs.load();
      final appModel = AppModel(prefs: prefs);
      appModel.newGame();

      await appModel.saveAndExitChessView();
      expect(appModel.isExiting, isTrue);
      expect(await GameStateStorage.hasSavedGame(), isTrue);
      expect(appModel.hasSavedGame, isTrue);
    });

    test('showCapturedPieces defaults to true and persists changes', () async {
      final prefs = UserPreferences();
      await prefs.load();
      expect(prefs.showCapturedPieces, isTrue);

      final appModel = AppModel(prefs: prefs);
      expect(appModel.showCapturedPieces, isTrue);

      appModel.setShowCapturedPieces(false);
      expect(appModel.showCapturedPieces, isFalse);
      expect(prefs.showCapturedPieces, isFalse);

      final reloadedPrefs = UserPreferences();
      await reloadedPrefs.load();
      expect(reloadedPrefs.showCapturedPieces, isFalse);

      await appModel.resetSettingsToDefaults();
      expect(appModel.showCapturedPieces, isTrue);
      expect(prefs.showCapturedPieces, isTrue);
    });

    test('captured pieces update dynamically during history navigation',
        () async {
      final prefs = UserPreferences();
      await prefs.load();
      final appModel = AppModel(prefs: prefs);
      final controller = GameController(appModel);
      appModel.gameController = controller;

      // Play e2e4 (48 -> 32)
      final meta1 = controller.board.push(Move(48, 32));
      appModel.pushMoveMeta(meta1);

      // Play d7d5 (11 -> 27)
      final meta2 = controller.board.push(Move(11, 27));
      appModel.pushMoveMeta(meta2);

      // White captures Black's pawn: e4xd5 (32 -> 27)
      final meta3 = controller.board.push(Move(32, 27));
      appModel.pushMoveMeta(meta3);

      // Verify captured pieces at live state: Player 2 lost 1 pawn
      expect(appModel.capturedPiecesFor(Player.player2), [ChessPieceType.pawn]);
      expect(appModel.capturedPiecesFor(Player.player1), isEmpty);

      // Rewind history to move index 1 (before the capture on move 2)
      appModel.setHistoryViewIndex(1);

      // Before the capture, Player 2 had NO captured pieces
      expect(appModel.capturedPiecesFor(Player.player2), isEmpty);
      expect(appModel.capturedPiecesFor(Player.player1), isEmpty);

      // Return to live game
      appModel.setHistoryViewIndex(null);

      // Capture is restored
      expect(appModel.capturedPiecesFor(Player.player2), [ChessPieceType.pawn]);
      expect(appModel.capturedPiecesFor(Player.player1), isEmpty);
    });

    test(
        'board and piece rotation in 2P mode behave like single player when viewing history',
        () async {
      final prefs = UserPreferences();
      await prefs.load();
      final appModel = AppModel(prefs: prefs);
      final controller = GameController(appModel);
      appModel.gameController = controller;

      // Configure 2P mode with auto board rotation
      appModel.setPlayerCount(2);
      appModel.setEnableRotation(true);
      appModel.setEnablePieceRotation(false);

      // Play e2e4 (Player 1 move)
      final meta1 = controller.board.push(Move(48, 32));
      appModel.pushMoveMeta(meta1);
      appModel.changeTurn();

      // Play e7e5 (Player 2 move)
      final meta2 = controller.board.push(Move(12, 28));
      appModel.pushMoveMeta(meta2);
      appModel.changeTurn();

      // Turn is Player 1 at live state. Now play another move to make it Player 2's turn again.
      final meta3 = controller.board.push(Move(32, 24)); // dummy e4-e5/etc
      appModel.pushMoveMeta(meta3);
      appModel.changeTurn();

      // Turn is now Player 2
      expect(appModel.turn, Player.player2);
      expect(appModel.isBoardInverted, isTrue);

      // Rewind into history viewing state at move index 0 (out of 3 moves)
      appModel.setHistoryViewIndex(0);
      expect(appModel.historyViewIndex, 0);
      // During history view, board rotation behaves like single player (no flip on turn)
      expect(appModel.isBoardInverted, isFalse);

      // Configure 2P mode with auto piece rotation
      appModel.setEnableRotation(false);
      appModel.setEnablePieceRotation(true);

      // Exit history view back to live game on Player 2's turn
      appModel.setHistoryViewIndex(null);
      expect(appModel.turn, Player.player2);
      expect(appModel.isPieceRotated, isTrue);

      // Enter history view again
      appModel.setHistoryViewIndex(0);
      // During history view, pieces must NOT rotate
      expect(appModel.isPieceRotated, isFalse);
    });

    test(
        'Undo after stalemate in AI mode restores human turn and clears game over',
        () async {
      final prefs = UserPreferences();
      await prefs.load();
      final appModel = AppModel(prefs: prefs);
      final controller = GameController(appModel);
      appModel.gameController = controller;
      appModel.playerCount = 1;
      appModel.playerSide = Player.player1;

      // Play e2e4 (White / Human)
      final meta = controller.board.push(Move(52, 36));
      appModel.pushMoveMeta(meta);
      appModel.changeTurn();

      // Simulate stalemate delivered by human
      appModel.endGame(stalemate: true);
      expect(appModel.gameOver, isTrue);
      expect(appModel.stalemate, isTrue);
      expect(appModel.userWon, isFalse);

      // Verify last move was by the user
      final lastMovePlayer = controller.board.moveStack.last.movedPiece?.player;
      expect(lastMovePlayer, appModel.playerSide);

      // Undo the human's stalemate move
      controller.undoMove();

      // Verify game over and stalemate are cleared, and turn is restored to Human
      expect(appModel.gameOver, isFalse);
      expect(appModel.stalemate, isFalse);
      expect(appModel.turn, Player.player1);
      expect(appModel.isAIsTurn, isFalse);
      expect(controller.board.moveStack, isEmpty);
    });

    test('ViewModel undo and redo properties reflect board state', () async {
      final prefs = UserPreferences();
      await prefs.load();
      final appModel = AppModel(prefs: prefs);
      final controller = GameController(appModel);
      appModel.gameController = controller;
      appModel.playerCount = 2;

      // Initially cannot undo or redo
      expect(appModel.canUndo, isFalse);
      expect(appModel.canRedo, isFalse);

      // Play e2e4 (White, Player 1)
      final meta = controller.board.push(Move(52, 36));
      appModel.pushMoveMeta(meta);

      // Should be able to undo
      expect(appModel.canUndo, isTrue);
      expect(appModel.canRedo, isFalse);

      // Call appModel.undo()
      appModel.undo();
      expect(appModel.canUndo, isFalse);
      expect(appModel.canRedo, isTrue);
      expect(controller.board.moveStack, isEmpty);
      expect(controller.board.redoStack.length, 1);
    });

    test('stepHistoryBackward and stepHistoryForward step through moves',
        () async {
      final prefs = UserPreferences();
      await prefs.load();
      final appModel = AppModel(prefs: prefs);
      final controller = GameController(appModel);
      appModel.gameController = controller;
      appModel.playerCount = 2;

      // Create two moves: 1. e4 (52->36), 1... e5 (12->28)
      final meta1 = MoveMeta(Move(52, 36), Player.player1, ChessPieceType.pawn);
      final meta2 = MoveMeta(Move(12, 28), Player.player2, ChessPieceType.pawn);
      controller.board.push(meta1.move!);
      controller.board.push(meta2.move!);
      appModel.moveMetaList.addAll([meta1, meta2]);

      // Enter history at move 0
      appModel.setHistoryViewIndex(0);
      expect(appModel.historyViewIndex, 0);

      // Stepping forward at the end of history returns to live state (null)
      appModel.stepHistoryForward();
      expect(appModel.historyViewIndex, isNull);
    });

    test(
        'king check highlight (checkHintTile) is restored after undoing move in 2-player mode',
        () async {
      final prefs = UserPreferences();
      await prefs.load();
      final appModel = AppModel(prefs: prefs);
      final controller = GameController(appModel);
      appModel.gameController = controller;
      appModel.playerCount = 2;

      // 1. e4 (52->36)
      controller.handleTap(52);
      controller.handleTap(36);
      // 1... f6 (13->21)
      controller.handleTap(13);
      controller.handleTap(21);
      // 2. Qh5+ (59->31) placing Black King (tile 4) in check
      controller.handleTap(59);
      controller.handleTap(31);

      // Verify Black King is in check and highlighted
      expect(controller.checkHintTile, 4);
      expect(appModel.turn, Player.player2);

      // Black plays 2... g6 (14->22) escaping check
      controller.handleTap(14);
      controller.handleTap(22);

      // Verify check highlight is cleared
      expect(controller.checkHintTile, isNull);
      expect(appModel.turn, Player.player1);

      // Black undos the move
      appModel.undo();

      // Verify check highlight is restored to Black King (tile 4)
      expect(controller.checkHintTile, 4);
      expect(appModel.turn, Player.player2);
    });

    test(
        'king check highlight (checkHintTile) is restored after undoing moves in AI mode',
        () async {
      final prefs = UserPreferences();
      await prefs.load();
      final appModel = AppModel(prefs: prefs);
      final controller = GameController(appModel);
      appModel.gameController = controller;
      appModel.playerCount = 2;

      // 1. e4 (52->36)
      controller.handleTap(52);
      controller.handleTap(36);
      // 1... f6 (13->21)
      controller.handleTap(13);
      controller.handleTap(21);
      // 2. Qh5+ (59->31) placing Black King (tile 4) in check
      controller.handleTap(59);
      controller.handleTap(31);

      // Verify Black King is in check and highlighted
      expect(controller.checkHintTile, 4);

      // Black (Human) plays 2... g6 (14->22) escaping check
      controller.handleTap(14);
      controller.handleTap(22);
      expect(controller.checkHintTile, isNull);

      // Opponent moves Queen 31 -> 39 (Qh4)
      controller.handleTap(31);
      controller.handleTap(39);
      expect(controller.checkHintTile, isNull);

      // Set to AI mode with Human as Black so appModel.undo() triggers undoTwoMoves
      appModel.playerCount = 1;
      appModel.playerSide = Player.player2;

      // Human undos in AI mode (undoes 2 moves: AI's move and Human's move)
      appModel.undo();

      // Verify check highlight is restored to Black King (tile 4)
      expect(controller.checkHintTile, 4);
      expect(appModel.turn, Player.player2);
    });
  });
}
