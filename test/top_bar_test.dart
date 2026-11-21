import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../lib/logic/ad_service.dart';
import '../lib/logic/chess_piece.dart';
import '../lib/logic/move_calculation/move_classes/move.dart';
import '../lib/logic/move_calculation/move_classes/move_meta.dart';
import '../lib/logic/shared_functions.dart';
import '../lib/model/app_model.dart';
import '../lib/model/player.dart';
import '../lib/model/user_preferences.dart';
import '../lib/views/chess_view.dart';
import '../lib/views/components/chess_view/game_info_and_controls/game_status.dart';

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

  for (final width in [320.0, 360.0, 375.0, 390.0, 414.0]) {
    testWidgets('Top bar renders GameStatus properly at width $width',
        (tester) async {
      final prefs = UserPreferences();
      await prefs.load();
      final appModel = AppModel(prefs: prefs);
      appModel.newGame();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appModel,
          child: CupertinoApp(
            home: MediaQuery(
              data: MediaQueryData(size: Size(width, 812)),
              child: Scaffold(
                body: ChessView(appModel),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      final gameStatusFinder = find.byType(GameStatus);
      expect(gameStatusFinder, findsOneWidget);
      final renderBox = tester.renderObject(gameStatusFinder) as RenderBox;
      expect(renderBox.size.width, greaterThan(0));
      expect(renderBox.size.height, greaterThan(0));

      // 1. Initial human turn: should see "YOUR TURN"
      expect(find.text('YOUR TURN'), findsOneWidget);

      // 2. Simulate AI's turn
      appModel.turn = oppositePlayer(appModel.playerSide);
      appModel.update();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('AI IS THINKING'), findsOneWidget);

      // 3. Simulate history review: should see "RESUME"
      final meta1 = MoveMeta(Move(52, 36), Player.player1, ChessPieceType.pawn);
      final meta2 = MoveMeta(Move(12, 28), Player.player2, ChessPieceType.pawn);
      appModel.gameController!.board.push(meta1.move!);
      appModel.gameController!.board.push(meta2.move!);
      appModel.moveMetaList.addAll([meta1, meta2]);
      appModel.setHistoryViewIndex(0);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('RESUME'), findsOneWidget);
    });
  }
}
