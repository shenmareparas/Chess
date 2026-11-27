import 'package:flutter_test/flutter_test.dart';

import '../lib/logic/chess_notation_service.dart';
import '../lib/logic/chess_piece.dart';
import '../lib/logic/move_calculation/move_classes/move.dart';
import '../lib/logic/move_calculation/move_classes/move_stack_object.dart';
import '../lib/model/app_model.dart';
import '../lib/model/user_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChessNotationService Tests', () {
    test('Standard opening replay and FEN export', () {
      // 1. e4 (52->36) e5 (12->28) 2. Nf3 (62->45) Nc6 (1->18)
      final moves = [
        MoveStackObject(Move(52, 36), null, null, null),
        MoveStackObject(Move(12, 28), null, null, null),
        MoveStackObject(Move(62, 45), null, null, null),
        MoveStackObject(Move(1, 18), null, null, null),
      ];

      final service = ChessNotationService.instance;
      final fen = service.exportFen(moves);
      expect(
        fen,
        'r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3',
      );
    });

    test('Castling generates valid SAN and FEN', () {
      // 1. e4 e5 2. Nf3 Nc6 3. Bc4 Bc5 4. O-O
      final moves = [
        MoveStackObject(Move(52, 36), null, null, null),
        MoveStackObject(Move(12, 28), null, null, null),
        MoveStackObject(Move(62, 45), null, null, null),
        MoveStackObject(Move(1, 18), null, null, null),
        MoveStackObject(Move(61, 34), null, null, null),
        MoveStackObject(Move(5, 26), null, null, null),
        // White O-O
        MoveStackObject(Move(60, 63), null, null, null)..castled = true,
      ];

      final service = ChessNotationService.instance;
      final pgn = service.generatePgn(moveStack: moves);
      expect(pgn, contains('4. O-O'));
    });

    test('Pawn promotion to Queen outputs SAN with Q', () {
      // Setup a game leading to promotion
      final moves = [
        MoveStackObject(Move(52, 36), null, null, null), // e4
        MoveStackObject(Move(11, 27), null, null, null), // d5
        MoveStackObject(Move(36, 27), null, null, null), // exd5
        MoveStackObject(Move(10, 18), null, null, null), // c6
        MoveStackObject(Move(27, 18), null, null, null), // dxc6
        MoveStackObject(Move(2, 20), null, null, null), // Bc5
        MoveStackObject(Move(18, 9), null, null, null), // cxb7
        MoveStackObject(Move(20, 53), null, null, null), // Bxf2+
        MoveStackObject(Move(60, 53), null, null, null), // Kxf2
        MoveStackObject(Move(3, 11), null, null, null), // Qd6
        // White b7xa8=Q
        MoveStackObject(Move(9, 0), null, null, null)
          ..promotion = true
          ..promotionType = ChessPieceType.queen,
      ];

      final service = ChessNotationService.instance;
      final pgn = service.generatePgn(moveStack: moves);
      expect(pgn, contains('bxa8=Q'));
    });

    test('Scholar\'s mate is detected as checkmate', () {
      // 1. e4 e5 2. Bc4 Nc6 3. Qh5 Nf6 4. Qxf7#
      final moves = [
        MoveStackObject(Move(52, 36), null, null, null), // e4
        MoveStackObject(Move(12, 28), null, null, null), // e5
        MoveStackObject(Move(61, 34), null, null, null), // Bc4
        MoveStackObject(Move(1, 18), null, null, null), // Nc6
        MoveStackObject(Move(59, 31), null, null, null), // Qh5
        MoveStackObject(Move(6, 21), null, null, null), // Nf6
        MoveStackObject(Move(31, 13), null, null, null), // Qxf7#
      ];

      final service = ChessNotationService.instance;
      expect(service.isCheckmate(moves), isTrue);

      final outcome = service.evaluateOutcome(moves);
      expect(outcome.isCheckmate, isTrue);
      expect(outcome.isDraw, isFalse);

      final pgn = service.generatePgn(moveStack: moves, result: '1-0');
      expect(pgn, contains('Qxf7# 1-0'));
    });

    test('Threefold repetition is accurately detected via evaluateOutcome', () {
      // Knight dance: 1. Nf3 Nf6 2. Ng1 Ng8 3. Nf3 Nf6 4. Ng1 Ng8
      final moves = [
        MoveStackObject(Move(62, 45), null, null, null), // Nf3 (pos 1)
        MoveStackObject(Move(6, 21), null, null, null), // Nf6
        MoveStackObject(Move(45, 62), null, null, null), // Ng1
        MoveStackObject(Move(21, 6), null, null, null), // Ng8 (pos 1 - initial)
        MoveStackObject(Move(62, 45), null, null, null), // Nf3 (pos 2)
        MoveStackObject(Move(6, 21), null, null, null), // Nf6
        MoveStackObject(Move(45, 62), null, null, null), // Ng1
        MoveStackObject(Move(21, 6), null, null, null), // Ng8 (pos 2)
        MoveStackObject(Move(62, 45), null, null, null), // Nf3 (pos 3)
        MoveStackObject(Move(6, 21), null, null, null), // Nf6
        MoveStackObject(Move(45, 62), null, null, null), // Ng1
        MoveStackObject(Move(21, 6), null, null, null), // Ng8 (pos 3 -> Draw!)
      ];

      final service = ChessNotationService.instance;
      final outcome = service.evaluateOutcome(moves);
      expect(outcome.isCheckmate, isFalse);
      expect(outcome.isDraw, isTrue);
      expect(outcome.drawReason, equals(FideDrawReason.threefoldRepetition));
      expect(outcome.drawReason?.description, 'Threefold Repetition');
    });

    test('PGN header generation includes player names and dates', () {
      final moves = [
        MoveStackObject(Move(52, 36), null, null, null), // e4
        MoveStackObject(Move(12, 28), null, null, null), // e5
      ];

      final testDate = DateTime(2026, 11, 15);
      final service = ChessNotationService.instance;
      final pgn = service.generatePgn(
        moveStack: moves,
        whiteName: 'Alice',
        blackName: 'Bob',
        event: 'Championship',
        date: testDate,
        result: '*',
      );

      expect(pgn, contains('[Event "Championship"]'));
      expect(pgn, contains('[White "Alice"]'));
      expect(pgn, contains('[Black "Bob"]'));
      expect(pgn, contains('[Date "2026.11.15"]'));
      expect(pgn, contains('1. e4 e5'));
    });

    test('Queenside castling (O-O-O) generates valid SAN', () {
      // 1. d4 d5 2. Nc3 Nc6 3. Bf4 Bf5 4. Qd2 Qd7 5. O-O-O O-O-O
      // Tile indices:
      // d4: 51->35, d5: 11->27
      // Nc3: 57->42, Nc6: 1->18
      // Bf4: 58->37, Bf5: 2->26
      // Qd2: 59->51, Qd7: 3->11
      // White O-O-O (King 60 -> Rook 56)
      // Black O-O-O (King 4 -> Rook 0)
      final moves = [
        MoveStackObject(Move(51, 35), null, null, null), // 1. d4
        MoveStackObject(Move(11, 27), null, null, null), // 1... d5
        MoveStackObject(Move(57, 42), null, null, null), // 2. Nc3
        MoveStackObject(Move(1, 18), null, null, null), // 2... Nc6
        MoveStackObject(Move(58, 37), null, null, null), // 3. Bf4
        MoveStackObject(Move(2, 29), null, null, null), // 3... Bf5
        MoveStackObject(Move(59, 51), null, null, null), // 4. Qd2
        MoveStackObject(Move(3, 11), null, null, null), // 4... Qd7
        MoveStackObject(Move(60, 56), null, null, null)
          ..castled = true, // 5. O-O-O
        MoveStackObject(Move(4, 0), null, null, null)
          ..castled = true, // 5... O-O-O
      ];

      final service = ChessNotationService.instance;
      final pgn = service.generatePgn(moveStack: moves);
      expect(pgn, contains('5. O-O-O O-O-O'));
    });

    test('AppModel exportPgn and exportFen integration', () async {
      final prefs = UserPreferences();
      final appModel = AppModel(prefs: prefs);
      appModel.newGame(notify: false);

      expect(
        appModel.exportFen(),
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      );

      // Make a move
      final controller = appModel.gameController!;
      controller.handleTap(52); // e2
      controller.handleTap(36); // e4

      final pgn = appModel.exportPgn();
      expect(pgn, contains('[Event "Casual Match"]'));
      expect(pgn, contains('[White "Player 1"]'));
      expect(pgn, contains('[Black "Stockfish L1 (400 ELO)"]'));
      expect(pgn, contains('1. e4'));

      final fen = appModel.exportFen();
      expect(
        fen,
        contains('rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq'),
      );
    });
  });
}
