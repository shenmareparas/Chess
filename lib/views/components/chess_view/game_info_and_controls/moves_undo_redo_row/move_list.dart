import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../../../logic/chess_piece.dart';
import '../../../../../logic/move_calculation/move_classes/move_meta.dart';
import '../../../../../logic/shared_functions.dart';
import '../../../../../model/app_model.dart';
import '../../../../../model/player.dart';
import '../../../shared/glass_panel.dart';

class MoveList extends StatelessWidget {
  final AppModel appModel;
  final ScrollController scrollController = ScrollController();

  MoveList(this.appModel);

  void _copyMovesToClipboard(BuildContext context) {
    final moves = _allMoves();
    if (moves.isEmpty) return;
    Clipboard.setData(ClipboardData(text: moves));
    HapticFeedback.mediumImpact();
    _showCopiedOverlay(context);
  }

  void _showCopiedOverlay(BuildContext context) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).size.height * 0.15,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Moves copied to clipboard',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 14,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(Duration(seconds: 2), () => overlayEntry.remove());
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    final turns = <Widget>[];
    final list = appModel.moveMetaList;
    final theme = appModel.theme;

    int totalMoves = list.length;
    int turnCount = (totalMoves / 2).ceil();

    for (int i = 0; i < turnCount; i++) {
      final turnNum = i + 1;
      final whiteMove = list[i * 2];
      final blackMove = (i * 2 + 1 < totalMoves) ? list[i * 2 + 1] : null;
      final isLastTurn = (turnNum == turnCount);

      turns.add(
        Opacity(
          opacity: isLastTurn ? 1 : 0.4,
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0x662A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(
                  color:
                      isLastTurn ? theme.moveHint : CupertinoColors.transparent,
                  width: 4,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$turnNum.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color:
                        isLastTurn ? theme.moveHint : const Color(0xFF8D928C),
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _moveToString(whiteMove),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE5E2E1),
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  blackMove != null ? _moveToString(blackMove) : '___',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: blackMove != null
                        ? const Color(0xFFC3C8C2)
                        : const Color(0xFF8D928C),
                    fontStyle:
                        blackMove != null ? FontStyle.normal : FontStyle.italic,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (turns.isEmpty) {
      turns.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0x28201F1F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0x14F5F5F0),
              width: 1.0,
            ),
          ),
          child: Text(
            'Waiting for first move',
            style: TextStyle(
              fontSize: 14,
              color: theme.lightTile.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: () => _copyMovesToClipboard(context),
      child: GlassPanel(
        padding: EdgeInsets.zero,
        borderRadius: 14,
        child: Container(
          height: 56,
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: turns,
            ),
          ),
        ),
      ),
    );
  }

  void _scrollToBottom() {
    if (appModel.moveListUpdated && scrollController.hasClients) {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
      appModel.moveListUpdated = false;
    }
  }

  String _allMoves() {
    var moveString = '';
    appModel.moveMetaList.asMap().forEach((index, move) {
      var turnNumber = ((index + 1) / 2).ceil();
      if (index % 2 == 0) {
        moveString += index == 0 ? '$turnNumber. ' : '\n$turnNumber. ';
      }
      moveString += _moveToString(move);
      if (index % 2 == 0) {
        moveString += ' ';
      }
    });
    if (appModel.gameOver) {
      if (appModel.turn == Player.player1) {
        moveString += ' ';
      }
      if (appModel.stalemate) {
        moveString += '  ½-½';
      } else {
        moveString += appModel.turn == Player.player2 ? '  1-0' : '  0-1';
      }
    }
    return moveString;
  }

  String _moveToString(MoveMeta meta) {
    String move;
    if (meta.kingCastle) {
      move = 'O-O';
    } else if (meta.queenCastle) {
      move = 'O-O-O';
    } else {
      String ambiguity = meta.rowIsAmbiguous
          ? '${_colToChar(tileToCol(meta.move?.from ?? 0))}'
          : '';
      ambiguity +=
          meta.colIsAmbiguous ? '${8 - tileToRow(meta.move?.from ?? 0)}' : '';
      String takeString = meta.took ? 'x' : '';
      String promotion = meta.promotion
          ? '=${_pieceToChar(meta.promotionType ?? ChessPieceType.promotion)}'
          : '';
      String row = '${8 - tileToRow(meta.move?.to ?? 0)}';
      String col = '${_colToChar(tileToCol(meta.move?.to ?? 0))}';
      move =
          '${_pieceToChar(meta.type ?? ChessPieceType.promotion)}$ambiguity$takeString' +
              '$col$row$promotion';
    }
    String check = meta.isCheck ? '+' : '';
    String checkmate = meta.isCheckmate && !meta.isStalemate ? '#' : '';
    return move + '$check$checkmate';
  }

  String _pieceToChar(ChessPieceType type) {
    switch (type) {
      case ChessPieceType.king:
        {
          return 'K';
        }
      case ChessPieceType.queen:
        {
          return 'Q';
        }
      case ChessPieceType.rook:
        {
          return 'R';
        }
      case ChessPieceType.bishop:
        {
          return 'B';
        }
      case ChessPieceType.knight:
        {
          return 'N';
        }
      case ChessPieceType.pawn:
        {
          return '';
        }
      default:
        {
          return '?';
        }
    }
  }

  String _colToChar(int col) {
    return String.fromCharCode(97 + col);
  }
}
