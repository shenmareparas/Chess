import 'package:chessground/chessground.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:dartchess/dartchess.dart' as dc;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../lib/logic/ad_service.dart';
import '../lib/logic/chess_piece.dart';
import '../lib/logic/move_calculation/move_classes/move.dart';
import '../lib/logic/move_calculation/move_classes/move_meta.dart';
import '../lib/model/app_model.dart';
import '../lib/model/player.dart';
import '../lib/model/user_preferences.dart';
import '../lib/views/chess_view.dart';
import '../lib/views/components/chess_view/captured_pieces_row.dart';
import '../lib/views/components/chess_view/promotion_dialog.dart';
import '../lib/views/components/settings_view/toggle.dart';
import '../lib/views/components/settings_view/toggles.dart';

Future<AppModel> _createModel({
  required int playerCount,
  required Player side,
  bool enableRotation = false,
  bool enablePieceRotation = false,
  bool flipOpponentPieces = false,
}) async {
  final prefs = UserPreferences();
  await prefs.load();
  await prefs.setEnableRotation(enableRotation);
  await prefs.setEnablePieceRotation(enablePieceRotation);
  await prefs.setFlipOpponentPieces(flipOpponentPieces);

  final appModel = AppModel(prefs: prefs);
  appModel.setPlayerCount(playerCount);
  if (playerCount == 1) {
    appModel.setPlayerSide(side);
  } else {
    appModel.setPlayerSideP1(side);
  }
  return appModel;
}

Future<void> _pumpChessView(WidgetTester tester, AppModel appModel) async {
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: appModel,
      child: CupertinoApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Scaffold(body: ChessView(appModel)),
        ),
      ),
    ),
  );
  // Drain post-frame newGame() and its 50ms animateBoardRotation timer.
  await tester.pump(const Duration(milliseconds: 100));
}

Future<int> _pumpPromotionAndGetTurns(
  WidgetTester tester,
  AppModel appModel,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: appModel,
      child: CupertinoApp(home: Scaffold(body: PromotionDialog(appModel))),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  return tester.widget<RotatedBox>(find.byType(RotatedBox)).quarterTurns;
}

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

  group('1P vs AI orientation, dead pills, and promotion', () {
    testWidgets('Human as White keeps White at bottom and facingUser', (
      tester,
    ) async {
      final appModel = await _createModel(
        playerCount: 1,
        side: Player.player1,
        enablePieceRotation: true,
      );
      await _pumpChessView(tester, appModel);

      final board = tester.widget<Chessboard>(find.byType(Chessboard));
      expect(board.orientation, dc.Side.white);
      expect(
        board.settings.pieceOrientationBehavior,
        PieceOrientationBehavior.facingUser,
      );

      final pills = tester
          .widgetList<CapturedPiecesRow>(find.byType(CapturedPiecesRow))
          .toList();
      expect(pills, hasLength(2));
      expect(pills[0].player, Player.player2); // Top: Black's captured pieces
      expect(
          pills[1].player, Player.player1); // Bottom: White's captured pieces
      expect(pills[0].rotatePieces, isFalse);
      expect(pills[1].rotatePieces, isFalse);

      expect(await _pumpPromotionAndGetTurns(tester, appModel), 0);
    });

    testWidgets('Human as Black puts Black at bottom and facingUser', (
      tester,
    ) async {
      final appModel = await _createModel(
        playerCount: 1,
        side: Player.player2,
        enablePieceRotation: true,
      );
      await _pumpChessView(tester, appModel);

      final board = tester.widget<Chessboard>(find.byType(Chessboard));
      expect(board.orientation, dc.Side.black);
      expect(
        board.settings.pieceOrientationBehavior,
        PieceOrientationBehavior.facingUser,
      );

      final pills = tester
          .widgetList<CapturedPiecesRow>(find.byType(CapturedPiecesRow))
          .toList();
      expect(pills, hasLength(2));
      expect(pills[0].player, Player.player1); // Top: White's captured pieces
      expect(
          pills[1].player, Player.player2); // Bottom: Black's captured pieces
      expect(pills[0].rotatePieces, isFalse);
      expect(pills[1].rotatePieces, isFalse);

      appModel.turn = Player.player2;
      expect(await _pumpPromotionAndGetTurns(tester, appModel), 0);
      appModel.gameController?.cancelAIMove();
      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  group('2P Auto-Rotate Board mode', () {
    testWidgets('Board and dead pills flip each turn with upright pieces', (
      tester,
    ) async {
      final appModel = await _createModel(
        playerCount: 2,
        side: Player.player1,
        enableRotation: true,
      );
      await _pumpChessView(tester, appModel);

      // White's turn
      var board = tester.widget<Chessboard>(find.byType(Chessboard));
      expect(board.orientation, dc.Side.white);
      expect(
        board.settings.pieceOrientationBehavior,
        PieceOrientationBehavior.facingUser,
      );
      var pills = tester
          .widgetList<CapturedPiecesRow>(find.byType(CapturedPiecesRow))
          .toList();
      expect(pills[0].player, Player.player2);
      expect(pills[1].player, Player.player1);
      expect(pills[0].rotatePieces, isFalse);

      // Black's turn
      appModel.turn = Player.player2;
      appModel.update();
      await tester.pump();

      board = tester.widget<Chessboard>(find.byType(Chessboard));
      expect(board.orientation, dc.Side.black);
      expect(
        board.settings.pieceOrientationBehavior,
        PieceOrientationBehavior.facingUser,
      );
      pills = tester
          .widgetList<CapturedPiecesRow>(find.byType(CapturedPiecesRow))
          .toList();
      expect(pills[0].player, Player.player1);
      expect(pills[1].player, Player.player2);
      expect(pills[0].rotatePieces, isFalse);

      expect(await _pumpPromotionAndGetTurns(tester, appModel), 0);
    });
  });

  group('2P Flip Pieces Each Turn mode', () {
    testWidgets('Player 1 = White keeps White at bottom and rotates for Black',
        (
      tester,
    ) async {
      final appModel = await _createModel(
        playerCount: 2,
        side: Player.player1,
        enablePieceRotation: true,
      );
      await _pumpChessView(tester, appModel);

      // White's turn (bottom player)
      var board = tester.widget<Chessboard>(find.byType(Chessboard));
      expect(board.orientation, dc.Side.white);
      expect(
        board.settings.pieceOrientationBehavior,
        PieceOrientationBehavior.sideToPlay,
      );
      var pills = tester
          .widgetList<CapturedPiecesRow>(find.byType(CapturedPiecesRow))
          .toList();
      expect(pills[0].player, Player.player2);
      expect(pills[1].player, Player.player1);
      expect(pills[0].rotatePieces, isFalse);

      // Black's turn (top player)
      appModel.turn = Player.player2;
      appModel.update();
      await tester.pump();

      board = tester.widget<Chessboard>(find.byType(Chessboard));
      expect(board.orientation, dc.Side.white);
      pills = tester
          .widgetList<CapturedPiecesRow>(find.byType(CapturedPiecesRow))
          .toList();
      expect(pills[0].rotatePieces, isTrue);
      expect(pills[1].rotatePieces, isTrue);

      // Top player promotes -> dialog inverted
      expect(await _pumpPromotionAndGetTurns(tester, appModel), 2);
    });

    testWidgets('Player 1 = Black keeps Black at bottom and rotates for White',
        (
      tester,
    ) async {
      final appModel = await _createModel(
        playerCount: 2,
        side: Player.player2,
        enablePieceRotation: true,
      );
      await _pumpChessView(tester, appModel);

      // White's turn (top player)
      var board = tester.widget<Chessboard>(find.byType(Chessboard));
      expect(board.orientation, dc.Side.black);
      expect(
        board.settings.pieceOrientationBehavior,
        PieceOrientationBehavior.sideToPlay,
      );
      var pills = tester
          .widgetList<CapturedPiecesRow>(find.byType(CapturedPiecesRow))
          .toList();
      expect(pills[0].player, Player.player1);
      expect(pills[1].player, Player.player2);
      expect(pills[0].rotatePieces, isTrue);
      expect(pills[1].rotatePieces, isTrue);

      // Black's turn (bottom player)
      appModel.turn = Player.player2;
      appModel.update();
      await tester.pump();

      board = tester.widget<Chessboard>(find.byType(Chessboard));
      expect(board.orientation, dc.Side.black);
      pills = tester
          .widgetList<CapturedPiecesRow>(find.byType(CapturedPiecesRow))
          .toList();
      expect(pills[0].rotatePieces, isFalse);
      expect(pills[1].rotatePieces, isFalse);

      // Bottom player promotes -> dialog upright
      expect(await _pumpPromotionAndGetTurns(tester, appModel), 0);
      // Top player promotes -> dialog inverted
      appModel.turn = Player.player1;
      expect(await _pumpPromotionAndGetTurns(tester, appModel), 2);
    });
  });

  group('2P Flip Opponent Pieces mode', () {
    testWidgets(
      'Player 1 = Black uses opponentUpsideDown and inverts White promotion',
      (tester) async {
        final appModel = await _createModel(
          playerCount: 2,
          side: Player.player2,
          flipOpponentPieces: true,
        );
        await _pumpChessView(tester, appModel);

        final board = tester.widget<Chessboard>(find.byType(Chessboard));
        expect(board.orientation, dc.Side.black);
        expect(
          board.settings.pieceOrientationBehavior,
          PieceOrientationBehavior.opponentUpsideDown,
        );

        final pills = tester
            .widgetList<CapturedPiecesRow>(find.byType(CapturedPiecesRow))
            .toList();
        expect(pills[0].player, Player.player1); // Top: White
        expect(pills[1].player, Player.player2); // Bottom: Black
        expect(pills[0].rotatePieces, isTrue);

        // White (top) promotes -> inverted
        expect(await _pumpPromotionAndGetTurns(tester, appModel), 2);

        // Black (bottom) promotes -> upright
        appModel.turn = Player.player2;
        expect(await _pumpPromotionAndGetTurns(tester, appModel), 0);
      },
    );
  });

  group('2P with all rotation disabled and History review', () {
    testWidgets('Player 1 = Black keeps Black at bottom with facingUser', (
      tester,
    ) async {
      final appModel = await _createModel(
        playerCount: 2,
        side: Player.player2,
      );
      await _pumpChessView(tester, appModel);

      final board = tester.widget<Chessboard>(find.byType(Chessboard));
      expect(board.orientation, dc.Side.black);
      expect(
        board.settings.pieceOrientationBehavior,
        PieceOrientationBehavior.facingUser,
      );
      final pills = tester
          .widgetList<CapturedPiecesRow>(find.byType(CapturedPiecesRow))
          .toList();
      expect(pills[0].rotatePieces, isFalse);

      expect(await _pumpPromotionAndGetTurns(tester, appModel), 0);
    });

    testWidgets('History review locks orientation to Player 1 and facingUser', (
      tester,
    ) async {
      final appModel = await _createModel(
        playerCount: 2,
        side: Player.player2,
        enablePieceRotation: true,
      );
      await _pumpChessView(tester, appModel);

      final meta1 = MoveMeta(Move(52, 36), Player.player1, ChessPieceType.pawn);
      final meta2 = MoveMeta(Move(12, 28), Player.player2, ChessPieceType.pawn);
      appModel.gameController!.board.push(meta1.move!);
      appModel.gameController!.board.push(meta2.move!);
      appModel.moveMetaList.addAll([meta1, meta2]);
      appModel.setHistoryViewIndex(0);
      await tester.pump();

      final board = tester.widget<Chessboard>(find.byType(Chessboard));
      expect(board.orientation, dc.Side.black);
      expect(
        board.settings.pieceOrientationBehavior,
        PieceOrientationBehavior.facingUser,
      );
      expect(appModel.isPieceRotated, isFalse);
    });
  });

  group('Settings mutual exclusivity', () {
    testWidgets(
      'Enabling any 2P rotation mode clears and disables the other two',
      (tester) async {
        final prefs = UserPreferences();
        await prefs.load();
        final appModel = AppModel(prefs: prefs);

        // Default: Auto-Rotate Board ON
        expect(prefs.enableRotation, isTrue);
        expect(prefs.enablePieceRotation, isFalse);
        expect(prefs.flipOpponentPieces, isFalse);

        // Switch to Flip Pieces Each Turn
        await prefs.setEnableRotation(false);
        await prefs.setEnablePieceRotation(true);
        expect(prefs.enableRotation, isFalse);
        expect(prefs.enablePieceRotation, isTrue);
        expect(prefs.flipOpponentPieces, isFalse);

        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: appModel,
            child: CupertinoApp(
              home: Scaffold(
                body: SingleChildScrollView(child: Toggles(appModel)),
              ),
            ),
          ),
        );

        final toggles = tester.widgetList<Toggle>(find.byType(Toggle)).toList();
        final boardToggle = toggles.firstWhere(
          (t) => t.label == 'Auto-Rotate Board (2P)',
        );
        final piecesToggle = toggles.firstWhere(
          (t) => t.label == 'Flip Pieces Each Turn (2P)',
        );
        final oppToggle = toggles.firstWhere(
          (t) => t.label == 'Flip Opponent Pieces (2P)',
        );
        final animToggle = toggles.firstWhere(
          (t) => t.label == 'Rotation Animation',
        );

        expect(boardToggle.enabled, isFalse);
        expect(piecesToggle.enabled, isTrue);
        expect(oppToggle.enabled, isFalse);
        expect(animToggle.enabled, isFalse);
      },
    );
  });
}
