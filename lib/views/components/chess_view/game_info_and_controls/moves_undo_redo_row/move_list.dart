import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../../../logic/chess_piece.dart';
import '../../../../../logic/move_calculation/move_classes/move_meta.dart';
import '../../../../../logic/shared_functions.dart';
import '../../../../../model/app_model.dart';
import '../../../../../model/player.dart';
import '../../../shared/text_variable.dart';

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
                fontFamily: 'Jura',
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
    return GestureDetector(
      onLongPress: () => _copyMovesToClipboard(context),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          color: Color(0x20000000),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          controller: scrollController,
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: TextRegular(_allMoves()),
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
