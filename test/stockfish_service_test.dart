import 'package:flutter_test/flutter_test.dart';
import '../lib/logic/chess_piece.dart';
import '../lib/logic/move_calculation/move_classes/move.dart';
import '../lib/logic/move_calculation/move_classes/move_stack_object.dart';
import '../lib/logic/stockfish_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StockfishService UCI Translation Tests', () {
    test('Standard pawn move converts to UCI', () {
      // e2 (row 6, col 4 => tile 6*8+4 = 52) to e4 (row 4, col 4 => tile 4*8+4 = 36)
      final mso = MoveStackObject(Move(52, 36), null, null, null);
      expect(StockfishService.msoToUCI(mso), 'e2e4');
    });

    test('Knight move converts to UCI', () {
      // g1 (row 7, col 6 => tile 7*8+6 = 62) to f3 (row 5, col 5 => tile 5*8+5 = 45)
      final mso = MoveStackObject(Move(62, 45), null, null, null);
      expect(StockfishService.msoToUCI(mso), 'g1f3');
    });

    test('White kingside castling converts to e1g1', () {
      final mso = MoveStackObject(Move(60, 63), null, null, null)
        ..castled = true;
      expect(StockfishService.msoToUCI(mso), 'e1g1');
    });

    test('White queenside castling converts to e1c1', () {
      final mso = MoveStackObject(Move(60, 56), null, null, null)
        ..castled = true;
      expect(StockfishService.msoToUCI(mso), 'e1c1');
    });

    test('Black kingside castling converts to e8g8', () {
      final mso = MoveStackObject(Move(4, 7), null, null, null)..castled = true;
      expect(StockfishService.msoToUCI(mso), 'e8g8');
    });

    test('Black queenside castling converts to e8c8', () {
      final mso = MoveStackObject(Move(4, 0), null, null, null)..castled = true;
      expect(StockfishService.msoToUCI(mso), 'e8c8');
    });

    test('Pawn promotion to queen converts to UCI with q suffix', () {
      // a7 (row 1, col 0 => tile 1*8+0 = 8) to a8 (row 0, col 0 => tile 0)
      final mso = MoveStackObject(Move(8, 0), null, null, null)
        ..promotion = true
        ..promotionType = ChessPieceType.queen;
      expect(StockfishService.msoToUCI(mso), 'a7a8q');
    });

    test('Pawn promotion to knight converts to UCI with n suffix', () {
      final mso = MoveStackObject(Move(8, 0), null, null, null)
        ..promotion = true
        ..promotionType = ChessPieceType.knight;
      expect(StockfishService.msoToUCI(mso), 'a7a8n');
    });

    test('StockfishService.instance dispose does not throw when idle',
        () async {
      await expectLater(StockfishService.instance.dispose(), completes);
    });
  });
}
