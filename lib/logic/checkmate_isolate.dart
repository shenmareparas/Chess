import '../model/player.dart';
import 'chess_board.dart';
import 'chess_piece.dart';

// ── Serialization helpers ──────────────────────────────────────────────────

/// Converts a [ChessPiece] to a plain, isolate-safe [Map].
Map<String, int> _serializePiece(ChessPiece p) => {
      'id': p.id,
      'type': p.type.index,
      'player': p.player.index,
      'tile': p.tile,
      'moveCount': p.moveCount,
    };

/// Reconstructs a [ChessPiece] from a serialized [Map].
ChessPiece _deserializePiece(Map<String, dynamic> m) => ChessPiece(
      m['id'] as int,
      ChessPieceType.values[m['type'] as int],
      Player.values[m['player'] as int],
      m['tile'] as int,
    )..moveCount = m['moveCount'] as int;

// ── Public API ────────────────────────────────────────────────────────────

/// Produces the minimum board snapshot needed to run [kingInCheckmate].
///
/// Only the 64-tile layout, piece lists (type/player/tile/moveCount),
/// enPassant state, and the player-to-check are serialized — the full
/// Zobrist hash, incremental eval, and move-stack history are not needed.
Map<String, dynamic> serializeBoardForCheckmate(
    ChessBoard board, Player player) {
  return {
    'player': player.index,
    'tiles':
        board.tiles.map((p) => p != null ? _serializePiece(p) : null).toList(),
    'enPassantPiece': board.enPassantPiece != null
        ? _serializePiece(board.enPassantPiece!)
        : null,
  };
}

/// Top-level entry point for [compute()].
///
/// Reconstructs a bare [ChessBoard] from [data] and calls [kingInCheckmate].
/// Must be a top-level (not instance/static) function so Flutter can spawn it
/// in a background isolate.
bool checkmateIsolateEntry(Map<String, dynamic> data) {
  final player = Player.values[data['player'] as int];
  final rawTiles = data['tiles'] as List<dynamic>;
  final rawEnPassant = data['enPassantPiece'] as Map<String, dynamic>?;

  // Build a blank board (no pieces) then populate from the snapshot.
  final board = ChessBoard.blank();

  // Reconstruct each piece and place it on the board.
  for (int i = 0; i < 64; i++) {
    final raw = rawTiles[i];
    if (raw == null) continue;
    final piece = _deserializePiece(raw as Map<String, dynamic>);
    board.tiles[i] = piece;
    board.piecesForPlayer(piece.player).add(piece);
    if (piece.type == ChessPieceType.king) {
      if (piece.player == Player.player1) {
        board.player1King = piece;
      } else {
        board.player2King = piece;
      }
    } else if (piece.type == ChessPieceType.rook) {
      board.rooksForPlayer(piece.player).add(piece);
    } else if (piece.type == ChessPieceType.queen) {
      board.queensForPlayer(piece.player).add(piece);
    }
  }

  // Restore en-passant state.
  if (rawEnPassant != null) {
    final epPiece = _deserializePiece(rawEnPassant);
    // Find the reconstructed piece instance that matches by id.
    board.enPassantPiece = board
        .piecesForPlayer(epPiece.player)
        .where((p) => p.id == epPiece.id)
        .firstOrNull;
  }

  return board.kingInCheckmate(player);
}
