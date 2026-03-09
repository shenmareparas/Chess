import 'dart:math' as math;

import '../model/player.dart';
import 'chess_constants.dart';
import 'chess_piece.dart';
import 'move_calculation/move_classes/direction.dart';
import 'move_calculation/move_classes/move.dart';
import 'move_calculation/move_classes/move_and_value.dart';
import 'move_calculation/move_classes/move_meta.dart';
import 'move_calculation/move_classes/move_stack_object.dart';
import 'move_calculation/openings.dart';
import 'move_calculation/piece_square_tables.dart';
import 'shared_functions.dart';

// Zobrist hashing constants
// 12 piece types (6 types x 2 colors) x 64 squares + 1 side-to-move
final List<List<int>> _zobristTable = _initZobristTable();
final int _zobristSideToMove = math.Random(9999).nextInt(0x7FFFFFFF);

const _pieceTypeIndex = {
  ChessPieceType.pawn: 0,
  ChessPieceType.knight: 1,
  ChessPieceType.bishop: 2,
  ChessPieceType.rook: 3,
  ChessPieceType.queen: 4,
  ChessPieceType.king: 5,
};

List<List<int>> _initZobristTable() {
  var rng = math.Random(42);
  return List.generate(
      12, (_) => List.generate(64, (_) => rng.nextInt(0x7FFFFFFF)));
}

const KING_ROW_PIECES = [
  ChessPieceType.rook,
  ChessPieceType.knight,
  ChessPieceType.bishop,
  ChessPieceType.queen,
  ChessPieceType.king,
  ChessPieceType.bishop,
  ChessPieceType.knight,
  ChessPieceType.rook
];

// Move direction constants
const _PAWN_DIAGONALS_1 = [DOWN_LEFT, DOWN_RIGHT];
const _PAWN_DIAGONALS_2 = [UP_LEFT, UP_RIGHT];
const _KNIGHT_MOVES = [
  Direction(1, 2),
  Direction(-1, 2),
  Direction(1, -2),
  Direction(-1, -2),
  Direction(2, 1),
  Direction(-2, 1),
  Direction(2, -1),
  Direction(-2, -1)
];
const _BISHOP_MOVES = [UP_RIGHT, DOWN_RIGHT, DOWN_LEFT, UP_LEFT];
const _ROOK_MOVES = [UP, RIGHT, DOWN, LEFT];
const _KING_QUEEN_MOVES = [
  UP,
  UP_RIGHT,
  RIGHT,
  DOWN_RIGHT,
  DOWN,
  DOWN_LEFT,
  LEFT,
  UP_LEFT
];

class ChessBoard {
  List<ChessPiece?> tiles = List.filled(64, null);
  List<MoveStackObject> moveStack = [];
  List<MoveStackObject> redoStack = [];
  List<ChessPiece> player1Pieces = [];
  List<ChessPiece> player2Pieces = [];
  List<ChessPiece> player1Rooks = [];
  List<ChessPiece> player2Rooks = [];
  List<ChessPiece> player1Queens = [];
  List<ChessPiece> player2Queens = [];
  ChessPiece? player1King;
  ChessPiece? player2King;
  ChessPiece? enPassantPiece;
  bool player1KingInCheck = false;
  bool player2KingInCheck = false;
  List<List<Move>> possibleOpenings = List.from(openings);
  int moveCount = 0;
  int zobristHash = 0;

  // Incremental evaluation state
  int incrementalValue = 0;
  bool inEndGameCached = false;

  ChessBoard() {
    _addPiecesForPlayer(Player.player1);
    _addPiecesForPlayer(Player.player2);
    _initZobristHash();
    _initIncrementalValue();
  }

  // ──────────────────────────────────────────────
  // Initialization
  // ──────────────────────────────────────────────

  void _initZobristHash() {
    zobristHash = 0;
    for (var piece in player1Pieces.followedBy(player2Pieces)) {
      zobristHash ^= _zobristPieceValue(piece);
    }
  }

  void _initIncrementalValue() {
    incrementalValue = 0;
    for (var piece in player1Pieces.followedBy(player2Pieces)) {
      incrementalValue += piece.value + squareValue(piece, false);
    }
    inEndGameCached = _computeInEndGame();
  }

  bool _computeInEndGame() {
    return (player1Queens.isEmpty && player2Queens.isEmpty) ||
        player1Pieces.length <= 3 ||
        player2Pieces.length <= 3;
  }

  void _addPiecesForPlayer(Player player) {
    var kingRowOffset = player == Player.player1 ? 56 : 0;
    var pawnRowOffset = player == Player.player1 ? -8 : 8;
    var index = 0;
    for (var pieceType in KING_ROW_PIECES) {
      var id = player == Player.player1 ? index * 2 : index * 2 + 16;
      var piece = ChessPiece(id, pieceType, player, kingRowOffset + index);
      var pawn = ChessPiece(id + 1, ChessPieceType.pawn, player,
          kingRowOffset + pawnRowOffset + index);
      _setTile(piece.tile, piece);
      _setTile(pawn.tile, pawn);
      piecesForPlayer(player).addAll([piece, pawn]);
      if (piece.type == ChessPieceType.king) {
        player == Player.player1 ? player1King = piece : player2King = piece;
      } else if (piece.type == ChessPieceType.queen) {
        queensForPlayer(player).add(piece);
      } else if (piece.type == ChessPieceType.rook) {
        rooksForPlayer(player).add(piece);
      }
      index++;
    }
  }

  // ──────────────────────────────────────────────
  // Piece / Player Accessors
  // ──────────────────────────────────────────────

  List<ChessPiece> piecesForPlayer(Player player) {
    return player == Player.player1 ? player1Pieces : player2Pieces;
  }

  ChessPiece? kingForPlayer(Player player) {
    return player == Player.player1 ? player1King : player2King;
  }

  List<ChessPiece> rooksForPlayer(Player player) {
    return player == Player.player1 ? player1Rooks : player2Rooks;
  }

  List<ChessPiece> queensForPlayer(Player player) {
    return player == Player.player1 ? player1Queens : player2Queens;
  }

  int get boardValue => incrementalValue;

  // ──────────────────────────────────────────────
  // Push / Pop (make / unmake move)
  // ──────────────────────────────────────────────

  MoveMeta push(Move move,
      {bool getMeta = false,
      ChessPieceType promotionType = ChessPieceType.promotion}) {
    var mso = MoveStackObject(move, tiles[move.from], tiles[move.to],
        enPassantPiece, List.from(possibleOpenings));
    mso.previousHash = zobristHash;
    mso.previousBoardValue = incrementalValue;
    mso.previousInEndGame = inEndGameCached;
    var meta = MoveMeta(move, mso.movedPiece?.player, mso.movedPiece?.type);
    if (possibleOpenings.isNotEmpty) {
      _filterPossibleOpenings(move);
    }
    if (getMeta) {
      _checkMoveAmbiguity(move, meta);
    }
    // Toggle side to move
    zobristHash ^= _zobristSideToMove;
    if (_castled(mso.movedPiece, mso.takenPiece)) {
      _castle(mso, meta);
    } else {
      _standardMove(mso, meta);
      if (mso.movedPiece?.type == ChessPieceType.pawn) {
        if (_promotion(mso.movedPiece)) {
          mso.promotionType = promotionType;
          meta.promotionType = promotionType;
          _promote(mso, meta);
        }
        _checkEnPassant(mso, meta);
      }
    }
    if (_canTakeEnPassant(mso.movedPiece)) {
      enPassantPiece = mso.movedPiece;
    } else {
      enPassantPiece = null;
    }
    if (meta.type == ChessPieceType.pawn && meta.took) {
      meta.rowIsAmbiguous = true;
    }
    moveStack.add(mso);
    moveCount++;
    // Update endgame flag (board value is tracked incrementally)
    _updateEndGameFlag();
    return meta;
  }

  MoveMeta pushMSO(MoveStackObject mso) {
    return push(mso.move,
        promotionType: mso.promotionType ?? ChessPieceType.promotion);
  }

  MoveStackObject pop() {
    var mso = moveStack.removeLast();
    zobristHash = mso.previousHash;
    incrementalValue = mso.previousBoardValue;
    inEndGameCached = mso.previousInEndGame;
    enPassantPiece = mso.enPassantPiece;
    possibleOpenings = mso.possibleOpenings ?? [];
    if (mso.castled) {
      _undoCastle(mso);
    } else {
      _undoStandardMove(mso);
      if (mso.promotion) {
        _undoPromote(mso);
      }
      if (mso.enPassant) {
        _addPiece(mso.enPassantPiece);
        _setTile(mso.enPassantPiece?.tile, mso.enPassantPiece);
      }
    }
    moveCount--;
    return mso;
  }

  // ──────────────────────────────────────────────
  // Move Calculation
  // ──────────────────────────────────────────────

  List<Move> allMoves(Player player, int aiDifficulty,
      {bool capturesOnly = false}) {
    List<MoveAndValue> moves = [];
    for (var piece in piecesForPlayer(player)) {
      var tiles = movesForPiece(piece);
      for (var tile in tiles) {
        var victim = this.tiles[tile];
        bool isCapture = victim != null && victim.player != piece.player;
        bool isPromotion = piece.type == ChessPieceType.pawn &&
            (tileToRow(tile) == 0 || tileToRow(tile) == 7);

        // In captures-only mode, skip quiet moves
        if (capturesOnly && !isCapture && !isPromotion) continue;

        int priority = 0;
        // MVV-LVA: prioritize captures by victim value - attacker value
        if (isCapture) {
          priority =
              (10000 + victim.materialValue - piece.materialValue).toInt();
        }
        if (isPromotion) {
          for (var promotion in PROMOTIONS) {
            moves.add(MoveAndValue(
                Move(piece.tile, tile, promotionType: promotion),
                priority + 9000));
          }
        } else {
          moves.add(MoveAndValue(Move(piece.tile, tile), priority));
        }
      }
    }
    // Sort by priority descending: captures and promotions first
    moves.sort((a, b) => b.value.compareTo(a.value));
    return List<Move>.generate(moves.length, (i) => moves[i].move);
  }

  List<int> movesForPiece(ChessPiece piece, {bool legal = true}) {
    List<int> moves;
    switch (piece.type) {
      case ChessPieceType.pawn:
        moves = _pawnMoves(piece);
        break;
      case ChessPieceType.knight:
        moves = _knightMoves(piece);
        break;
      case ChessPieceType.bishop:
        moves = _bishopMoves(piece);
        break;
      case ChessPieceType.rook:
        moves = _rookMoves(piece, legal);
        break;
      case ChessPieceType.queen:
        moves = _queenMoves(piece);
        break;
      case ChessPieceType.king:
        moves = _kingMoves(piece, legal);
        break;
      default:
        moves = [];
    }
    if (legal) {
      moves.removeWhere((move) => _movePutsKingInCheck(piece, move));
    }
    return moves;
  }

  bool kingInCheck(Player player) {
    for (var piece in piecesForPlayer(oppositePlayer(player))) {
      if (movesForPiece(piece, legal: false)
          .contains(kingForPlayer(player)?.tile)) {
        return true;
      }
    }
    return false;
  }

  bool kingInCheckmate(Player player) {
    for (var piece in piecesForPlayer(player)) {
      if (movesForPiece(piece).isNotEmpty) {
        return false;
      }
    }
    return true;
  }

  // ──────────────────────────────────────────────
  // Private: Move Execution
  // ──────────────────────────────────────────────

  void _standardMove(MoveStackObject mso, MoveMeta meta) {
    var piece = mso.movedPiece;
    if (piece != null) {
      zobristHash ^= _zobristPieceAt(piece, mso.move.from);
      zobristHash ^= _zobristPieceAt(piece, mso.move.to);
      incrementalValue -= squareValue(piece, inEndGameCached);
    }
    if (mso.takenPiece != null) {
      zobristHash ^= _zobristPieceValue(mso.takenPiece!);
    }
    _setTile(mso.move.to, mso.movedPiece);
    _setTile(mso.move.from, null);
    if (piece != null) {
      incrementalValue += squareValue(piece, inEndGameCached);
    }
    mso.movedPiece?.moveCount++;
    if (mso.takenPiece != null) {
      incrementalValue -= mso.takenPiece!.value +
          squareValue(mso.takenPiece!, inEndGameCached);
      _removePiece(mso.takenPiece);
      meta.took = true;
    }
  }

  void _undoStandardMove(MoveStackObject mso) {
    _setTile(mso.move.from, mso.movedPiece);
    _setTile(mso.move.to, null);
    if (mso.takenPiece != null) {
      _addPiece(mso.takenPiece);
      _setTile(mso.move.to, mso.takenPiece);
    }
    mso.movedPiece?.moveCount--;
  }

  void _castle(MoveStackObject mso, MoveMeta meta) {
    var king = mso.movedPiece?.type == ChessPieceType.king
        ? mso.movedPiece
        : mso.takenPiece;
    var rook = mso.movedPiece?.type == ChessPieceType.rook
        ? mso.movedPiece
        : mso.takenPiece;
    if (king != null) {
      incrementalValue -= squareValue(king, inEndGameCached);
    }
    if (rook != null) {
      incrementalValue -= squareValue(rook, inEndGameCached);
    }
    _setTile(king?.tile, null);
    _setTile(rook?.tile, null);
    var kingCol = tileToCol(rook?.tile ?? 0) == 0 ? 2 : 6;
    var rookCol = tileToCol(rook?.tile ?? 0) == 0 ? 3 : 5;
    _setTile(tileToRow(king?.tile ?? 0) * 8 + kingCol, king);
    _setTile(tileToRow(rook?.tile ?? 0) * 8 + rookCol, rook);
    if (king != null) {
      incrementalValue += squareValue(king, inEndGameCached);
    }
    if (rook != null) {
      incrementalValue += squareValue(rook, inEndGameCached);
    }
    tileToCol(rook?.tile ?? 0) == 3
        ? meta.queenCastle = true
        : meta.kingCastle = true;
    king?.moveCount++;
    rook?.moveCount++;
    mso.castled = true;
  }

  void _undoCastle(MoveStackObject mso) {
    var king = mso.movedPiece?.type == ChessPieceType.king
        ? mso.movedPiece
        : mso.takenPiece;
    var rook = mso.movedPiece?.type == ChessPieceType.rook
        ? mso.movedPiece
        : mso.takenPiece;
    _setTile(king?.tile, null);
    _setTile(rook?.tile, null);
    var rookCol = tileToCol(rook?.tile ?? 0) == 3 ? 0 : 7;
    _setTile(tileToRow(king?.tile ?? 0) * 8 + 4, king);
    _setTile(tileToRow(rook?.tile ?? 0) * 8 + rookCol, rook);
    king?.moveCount--;
    rook?.moveCount--;
  }

  void _promote(MoveStackObject mso, MoveMeta meta) {
    var piece = mso.movedPiece;
    if (piece != null) {
      incrementalValue -=
          piece.value + squareValue(piece, inEndGameCached);
    }
    mso.movedPiece?.type = mso.promotionType ?? ChessPieceType.promotion;
    if (mso.promotionType != ChessPieceType.promotion) {
      addPromotedPiece(mso);
    }
    if (piece != null) {
      incrementalValue +=
          piece.value + squareValue(piece, inEndGameCached);
    }
    meta.promotion = true;
    mso.promotion = true;
  }

  void addPromotedPiece(MoveStackObject mso) {
    switch (mso.promotionType) {
      case ChessPieceType.queen:
        if (mso.movedPiece != null) {
          queensForPlayer(mso.movedPiece?.player ?? Player.player1)
              .add(mso.movedPiece!);
        }
        break;
      case ChessPieceType.rook:
        if (mso.movedPiece != null) {
          rooksForPlayer(mso.movedPiece?.player ?? Player.player1)
              .add(mso.movedPiece!);
        }
        break;
      default:
        {}
    }
  }

  void _undoPromote(MoveStackObject mso) {
    mso.movedPiece?.type = ChessPieceType.pawn;
    switch (mso.promotionType) {
      case ChessPieceType.queen:
        queensForPlayer(mso.movedPiece?.player ?? Player.player1)
            .remove(mso.movedPiece);
        break;
      case ChessPieceType.rook:
        rooksForPlayer(mso.movedPiece?.player ?? Player.player1)
            .remove(mso.movedPiece);
        break;
      default:
        {}
    }
  }

  void _checkEnPassant(MoveStackObject mso, MoveMeta meta) {
    var offset = mso.movedPiece?.player == Player.player1 ? 8 : -8;
    var tile = (mso.movedPiece?.tile ?? 0) + offset;
    var takenPiece = tiles[tile];
    if (takenPiece != null && takenPiece == enPassantPiece) {
      incrementalValue -= takenPiece.value +
          squareValue(takenPiece, inEndGameCached);
      _removePiece(takenPiece);
      _setTile(takenPiece.tile, null);
      mso.enPassant = true;
    }
  }

  // ──────────────────────────────────────────────
  // Private: Move Calculation Helpers
  // ──────────────────────────────────────────────

  List<int> _pawnMoves(ChessPiece pawn) {
    List<int> moves = [];
    var offset = pawn.player == Player.player1 ? -8 : 8;
    var firstTile = pawn.tile + offset;
    if (tiles[firstTile] == null) {
      moves.add(firstTile);
      if (pawn.moveCount == 0) {
        var secondTile = firstTile + offset;
        if (tiles[secondTile] == null) {
          moves.add(secondTile);
        }
      }
    }
    moves.addAll(_pawnDiagonalAttacks(pawn));
    return moves;
  }

  List<int> _pawnDiagonalAttacks(ChessPiece pawn) {
    List<int> moves = [];
    var diagonals =
        pawn.player == Player.player1 ? _PAWN_DIAGONALS_1 : _PAWN_DIAGONALS_2;
    for (var diagonal in diagonals) {
      var row = tileToRow(pawn.tile) + diagonal.up;
      var col = tileToCol(pawn.tile) + diagonal.right;
      if (_inBounds(row, col)) {
        var takenPiece = tiles[_rowColToTile(row, col)];
        if ((takenPiece != null &&
                takenPiece.player == oppositePlayer(pawn.player)) ||
            _canTakeEnPassantAt(pawn.player, _rowColToTile(row, col))) {
          moves.add(_rowColToTile(row, col));
        }
      }
    }
    return moves;
  }

  bool _canTakeEnPassantAt(Player pawnPlayer, int diagonal) {
    var offset = (pawnPlayer == Player.player1) ? 8 : -8;
    var takenPiece = tiles[diagonal + offset];
    return takenPiece != null &&
        takenPiece.player != pawnPlayer &&
        takenPiece == enPassantPiece;
  }

  List<int> _knightMoves(ChessPiece knight) {
    return _movesFromDirections(knight, _KNIGHT_MOVES, false);
  }

  List<int> _bishopMoves(ChessPiece bishop) {
    return _movesFromDirections(bishop, _BISHOP_MOVES, true);
  }

  List<int> _rookMoves(ChessPiece rook, bool legal) {
    var moves = _movesFromDirections(rook, _ROOK_MOVES, true);
    moves.addAll(_rookCastleMove(rook, legal));
    return moves;
  }

  List<int> _queenMoves(ChessPiece queen) {
    return _movesFromDirections(queen, _KING_QUEEN_MOVES, true);
  }

  List<int> _kingMoves(ChessPiece king, bool legal) {
    var moves = _movesFromDirections(king, _KING_QUEEN_MOVES, false);
    moves.addAll(_kingCastleMoves(king, legal));
    return moves;
  }

  List<int> _rookCastleMove(ChessPiece rook, bool legal) {
    if (!legal || !kingInCheck(rook.player)) {
      var king = kingForPlayer(rook.player);
      if (_canCastle(king, rook, legal)) {
        return [king?.tile ?? 0];
      }
    }
    return [];
  }

  List<int> _kingCastleMoves(ChessPiece king, bool legal) {
    List<int> moves = [];
    if (!legal || !kingInCheck(king.player)) {
      for (var rook in rooksForPlayer(king.player)) {
        if (_canCastle(king, rook, legal)) {
          moves.add(rook.tile);
        }
      }
    }
    return moves;
  }

  bool _canCastle(ChessPiece? king, ChessPiece rook, bool legal) {
    if (rook.moveCount == 0 && king?.moveCount == 0) {
      var offset = (king?.tile ?? 0) - rook.tile > 0 ? 1 : -1;
      var tile = rook.tile;
      while (tile != king?.tile) {
        tile += offset;
        if ((tiles[tile] != null && tile != king?.tile) ||
            (legal &&
                _kingInCheckAtTile(
                    tile, king?.player ?? Player.player1))) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  List<int> _movesFromDirections(
      ChessPiece piece, List<Direction> directions, bool repeat) {
    List<int> moves = [];
    for (var direction in directions) {
      var row = tileToRow(piece.tile);
      var col = tileToCol(piece.tile);
      do {
        row += direction.up;
        col += direction.right;
        if (_inBounds(row, col)) {
          var possiblePiece = tiles[_rowColToTile(row, col)];
          if (possiblePiece != null) {
            if (possiblePiece.player != piece.player) {
              moves.add(_rowColToTile(row, col));
            }
            break;
          } else {
            moves.add(_rowColToTile(row, col));
          }
        }
        if (!repeat) {
          break;
        }
      } while (_inBounds(row, col));
    }
    return moves;
  }

  bool _movePutsKingInCheck(ChessPiece piece, int move) {
    push(Move(piece.tile, move));
    var check = kingInCheck(piece.player);
    pop();
    return check;
  }

  bool _kingInCheckAtTile(int tile, Player player) {
    for (var piece in piecesForPlayer(oppositePlayer(player))) {
      if (movesForPiece(piece, legal: false).contains(tile)) {
        return true;
      }
    }
    return false;
  }

  // ──────────────────────────────────────────────
  // Private: Board Utility
  // ──────────────────────────────────────────────

  void _checkMoveAmbiguity(Move move, MoveMeta moveMeta) {
    var piece = tiles[move.from];
    for (var otherPiece
        in _piecesOfTypeForPlayer(piece?.type, piece?.player)) {
      if (piece != otherPiece) {
        if (movesForPiece(otherPiece).contains(move.to)) {
          if (tileToCol(otherPiece.tile) == tileToCol(piece?.tile ?? 0)) {
            moveMeta.colIsAmbiguous = true;
          } else {
            moveMeta.rowIsAmbiguous = true;
          }
        }
      }
    }
  }

  void _filterPossibleOpenings(Move move) {
    possibleOpenings = possibleOpenings
        .where((opening) =>
            opening[moveCount] == move &&
            opening.length > moveCount + 1)
        .toList();
  }

  void _setTile(int? tile, ChessPiece? piece) {
    if (tile != null) {
      tiles[tile] = piece;
    }
    if (piece != null) {
      piece.tile = tile ?? 0;
    }
  }

  void _addPiece(ChessPiece? piece) {
    if (piece != null) {
      piecesForPlayer(piece.player).add(piece);
      if (piece.type == ChessPieceType.rook) {
        rooksForPlayer(piece.player).add(piece);
      }
      if (piece.type == ChessPieceType.queen) {
        queensForPlayer(piece.player).add(piece);
      }
    }
  }

  void _removePiece(ChessPiece? piece) {
    if (piece != null) {
      piecesForPlayer(piece.player).remove(piece);
      if (piece.type == ChessPieceType.rook) {
        rooksForPlayer(piece.player).remove(piece);
      }
      if (piece.type == ChessPieceType.queen) {
        queensForPlayer(piece.player).remove(piece);
      }
    }
  }

  List<ChessPiece> _piecesOfTypeForPlayer(
      ChessPieceType? type, Player? player) {
    List<ChessPiece> pieces = [];
    if (type != null && player != null) {
      for (var piece in piecesForPlayer(player)) {
        if (piece.type == type) {
          pieces.add(piece);
        }
      }
    }
    return pieces;
  }

  // ──────────────────────────────────────────────
  // Private: Move Predicates
  // ──────────────────────────────────────────────

  bool _castled(ChessPiece? movedPiece, ChessPiece? takenPiece) {
    return takenPiece != null && takenPiece.player == movedPiece?.player;
  }

  bool _promotion(ChessPiece? movedPiece) {
    return movedPiece?.type == ChessPieceType.pawn &&
        (tileToRow(movedPiece?.tile ?? 0) == 7 ||
            tileToRow(movedPiece?.tile ?? 0) == 0);
  }

  bool _canTakeEnPassant(ChessPiece? movedPiece) {
    return movedPiece?.moveCount == 1 &&
        movedPiece?.type == ChessPieceType.pawn &&
        (tileToRow(movedPiece?.tile ?? 0) == 3 ||
            tileToRow(movedPiece?.tile ?? 0) == 4);
  }

  void _updateEndGameFlag() {
    inEndGameCached = _computeInEndGame();
  }

  // ──────────────────────────────────────────────
  // Private: Zobrist Helpers
  // ──────────────────────────────────────────────

  static int _zobristIndex(ChessPiece piece) {
    int base = _pieceTypeIndex[piece.type] ?? 0;
    if (piece.player == Player.player2) base += 6;
    return base;
  }

  static int _zobristPieceValue(ChessPiece piece) {
    return _zobristTable[_zobristIndex(piece)][piece.tile];
  }

  static int _zobristPieceAt(ChessPiece piece, int tile) {
    return _zobristTable[_zobristIndex(piece)][tile];
  }

  static bool _inBounds(int row, int col) {
    return row >= 0 && row < 8 && col >= 0 && col < 8;
  }

  static int _rowColToTile(int row, int col) {
    return row * 8 + col;
  }

  /// Exposed for null-move pruning in AI search.
  static int get zobristSideToMoveValue => _zobristSideToMove;
}
