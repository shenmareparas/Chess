import '../model/player.dart';
import 'chess_piece.dart';
import 'move_calculation/move_classes/direction.dart';
import 'move_calculation/move_classes/move.dart';
import 'move_calculation/move_classes/move_meta.dart';
import 'move_calculation/move_classes/move_stack_object.dart';
import 'shared_functions.dart';

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
  int moveCount = 0;

  // Cached captured pieces (invalidated on push/pop)
  List<ChessPieceType>? _capturedP1Cache;
  List<ChessPieceType>? _capturedP2Cache;

  void _invalidateCapturedCache() {
    _capturedP1Cache = null;
    _capturedP2Cache = null;
  }

  ChessBoard() {
    _addPiecesForPlayer(Player.player1);
    _addPiecesForPlayer(Player.player2);
  }

  /// Creates an empty board with no pieces.
  /// Used by [checkmateIsolateEntry] to reconstruct state from a serialized snapshot.
  ChessBoard.blank();

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

  /// Returns a sorted list of piece types that have been captured from [player]'s side.
  /// Sorted by descending material value for stable, canonical display order.
  /// If a promoted piece (e.g. queen, rook, bishop, knight) is captured,
  /// it is displayed as that promoted piece type instead of a pawn.
  List<ChessPieceType> capturedPiecesFor(Player player) {
    if (player == Player.player1 && _capturedP1Cache != null) {
      return _capturedP1Cache!;
    }
    if (player == Player.player2 && _capturedP2Cache != null) {
      return _capturedP2Cache!;
    }

    const Map<ChessPieceType, int> initial = {
      ChessPieceType.queen: 1,
      ChessPieceType.rook: 2,
      ChessPieceType.bishop: 2,
      ChessPieceType.knight: 2,
      ChessPieceType.pawn: 8,
    };

    final alive = piecesForPlayer(player);
    final Map<ChessPieceType, int> aliveStandard = {};
    final List<ChessPiece> alivePromoted = [];

    for (final p in alive) {
      if (p.type == ChessPieceType.king || p.type == ChessPieceType.promotion) {
        continue;
      }
      if (p.id % 2 != 0) {
        // ID is odd: started as a pawn
        if (p.type == ChessPieceType.pawn) {
          aliveStandard[ChessPieceType.pawn] =
              (aliveStandard[ChessPieceType.pawn] ?? 0) + 1;
        } else {
          // Pawn that got promoted and is still alive
          alivePromoted.add(p);
        }
      } else {
        // Started as standard back-rank piece
        aliveStandard[p.type] = (aliveStandard[p.type] ?? 0) + 1;
      }
    }

    // Determine how many pawns promoted in total for this player across the game history
    final Map<ChessPieceType, int> totalPromoted = {};
    for (final mso in moveStack) {
      if (mso.promotion &&
          mso.movedPiece != null &&
          mso.movedPiece!.player == player) {
        final promoType = mso.promotionType;
        if (promoType != null &&
            promoType != ChessPieceType.promotion &&
            promoType != ChessPieceType.pawn) {
          totalPromoted[promoType] = (totalPromoted[promoType] ?? 0) + 1;
        }
      }
    }

    // Promoted pieces that were captured = total promoted minus currently alive promoted
    final Map<ChessPieceType, int> capturedPromoted = {};
    for (final entry in totalPromoted.entries) {
      final aliveCount = alivePromoted.where((p) => p.type == entry.key).length;
      final capturedCount = entry.value - aliveCount;
      if (capturedCount > 0) {
        capturedPromoted[entry.key] = capturedCount;
      }
    }

    // Calculate total pawns promoted
    int totalPromotedCount = 0;
    for (final count in totalPromoted.values) {
      totalPromotedCount += count;
    }

    final List<ChessPieceType> captured = [];
    for (final type in [
      ChessPieceType.queen,
      ChessPieceType.rook,
      ChessPieceType.bishop,
      ChessPieceType.knight,
      ChessPieceType.pawn,
    ]) {
      if (type == ChessPieceType.pawn) {
        // Pawns captured as pawns = 8 - (alive standard pawns + total promoted pawns)
        final alivePawns = aliveStandard[ChessPieceType.pawn] ?? 0;
        final gonePawns = 8 - alivePawns - totalPromotedCount;
        for (int i = 0; i < gonePawns; i++) {
          captured.add(ChessPieceType.pawn);
        }
      } else {
        // Initial non-pawn pieces captured
        final initCount = initial[type] ?? 0;
        final aliveCount = aliveStandard[type] ?? 0;
        final goneStandard = (initCount - aliveCount).clamp(0, initCount);
        for (int i = 0; i < goneStandard; i++) {
          captured.add(type);
        }
        // Promoted pieces captured as this type
        final promoCaptured = capturedPromoted[type] ?? 0;
        for (int i = 0; i < promoCaptured; i++) {
          captured.add(type);
        }
      }
    }

    if (player == Player.player1) {
      _capturedP1Cache = captured;
    } else {
      _capturedP2Cache = captured;
    }

    return captured;
  }

  // ──────────────────────────────────────────────
  // Push / Pop (make / unmake move)
  // ──────────────────────────────────────────────

  MoveMeta push(Move move,
      {bool getMeta = false,
      ChessPieceType promotionType = ChessPieceType.promotion}) {
    _invalidateCapturedCache();
    var mso =
        MoveStackObject(move, tiles[move.from], tiles[move.to], enPassantPiece);
    var meta = MoveMeta(move, mso.movedPiece?.player, mso.movedPiece?.type);
    if (getMeta) {
      _checkMoveAmbiguity(move, meta);
    }
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
    return meta;
  }

  MoveMeta pushMSO(MoveStackObject mso) {
    return push(mso.move,
        promotionType: mso.promotionType ?? ChessPieceType.promotion);
  }

  MoveStackObject pop() {
    _invalidateCapturedCache();
    var mso = moveStack.removeLast();
    enPassantPiece = mso.enPassantPiece;
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

  /// Returns [true] if [player]'s king is currently under attack.
  ///
  /// Checks each opponent piece's raw (pseudo-legal) attack squares using
  /// direct tile iteration rather than building and searching a full moves
  /// list, avoiding per-piece list allocations in the hot path.
  bool kingInCheck(Player player) {
    final kingTile = kingForPlayer(player)?.tile;
    if (kingTile == null) return false;
    for (var piece in piecesForPlayer(oppositePlayer(player))) {
      if (_pieceAttacksTile(piece, kingTile)) return true;
    }
    return false;
  }

  /// Returns [true] if [piece] can attack [targetTile] (pseudo-legal, no
  /// king-safety check) without allocating a complete move list.
  bool _pieceAttacksTile(ChessPiece piece, int targetTile) {
    switch (piece.type) {
      case ChessPieceType.pawn:
        final diagonals = piece.player == Player.player1
            ? _PAWN_DIAGONALS_1
            : _PAWN_DIAGONALS_2;
        for (final d in diagonals) {
          final r = tileToRow(piece.tile) + d.up;
          final c = tileToCol(piece.tile) + d.right;
          if (_inBounds(r, c) && _rowColToTile(r, c) == targetTile) return true;
        }
        return false;
      case ChessPieceType.knight:
        for (final d in _KNIGHT_MOVES) {
          final r = tileToRow(piece.tile) + d.up;
          final c = tileToCol(piece.tile) + d.right;
          if (_inBounds(r, c) && _rowColToTile(r, c) == targetTile) return true;
        }
        return false;
      case ChessPieceType.bishop:
        return _slidingAttacks(piece, _BISHOP_MOVES, targetTile);
      case ChessPieceType.rook:
        return _slidingAttacks(piece, _ROOK_MOVES, targetTile);
      case ChessPieceType.queen:
        return _slidingAttacks(piece, _KING_QUEEN_MOVES, targetTile);
      case ChessPieceType.king:
        for (final d in _KING_QUEEN_MOVES) {
          final r = tileToRow(piece.tile) + d.up;
          final c = tileToCol(piece.tile) + d.right;
          if (_inBounds(r, c) && _rowColToTile(r, c) == targetTile) return true;
        }
        return false;
      default:
        return false;
    }
  }

  /// Checks whether a sliding piece (bishop / rook / queen) attacks [targetTile].
  bool _slidingAttacks(
      ChessPiece piece, List<Direction> directions, int targetTile) {
    for (final dir in directions) {
      var r = tileToRow(piece.tile);
      var c = tileToCol(piece.tile);
      while (true) {
        r += dir.up;
        c += dir.right;
        if (!_inBounds(r, c)) break;
        final t = _rowColToTile(r, c);
        if (t == targetTile) return true;
        if (tiles[t] != null) break; // Blocked
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
    _setTile(mso.move.to, mso.movedPiece);
    _setTile(mso.move.from, null);
    mso.movedPiece?.moveCount++;
    if (mso.takenPiece != null) {
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
    _setTile(king?.tile, null);
    _setTile(rook?.tile, null);
    var kingCol = tileToCol(rook?.tile ?? 0) == 0 ? 2 : 6;
    var rookCol = tileToCol(rook?.tile ?? 0) == 0 ? 3 : 5;
    _setTile(tileToRow(king?.tile ?? 0) * 8 + kingCol, king);
    _setTile(tileToRow(rook?.tile ?? 0) * 8 + rookCol, rook);
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
    mso.movedPiece?.type = mso.promotionType ?? ChessPieceType.promotion;
    if (mso.promotionType != ChessPieceType.promotion) {
      addPromotedPiece(mso);
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
                _kingInCheckAtTile(tile, king?.player ?? Player.player1))) {
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
      if (_pieceAttacksTile(piece, tile)) return true;
    }
    return false;
  }

  // ──────────────────────────────────────────────
  // Private: Board Utility
  // ──────────────────────────────────────────────

  void _checkMoveAmbiguity(Move move, MoveMeta moveMeta) {
    var piece = tiles[move.from];
    for (var otherPiece in _piecesOfTypeForPlayer(piece?.type, piece?.player)) {
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

  Iterable<ChessPiece> _piecesOfTypeForPlayer(
      ChessPieceType? type, Player? player) {
    if (type == null || player == null) return const [];
    // Return a lazy iterable — avoids allocating a full List<ChessPiece> for
    // ambiguity checks that typically only need to test existence or iterate once.
    return piecesForPlayer(player).where((p) => p.type == type);
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

  static bool _inBounds(int row, int col) {
    return row >= 0 && row < 8 && col >= 0 && col < 8;
  }

  static int _rowColToTile(int row, int col) {
    return row * 8 + col;
  }
}
