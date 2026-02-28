import 'package:en_passant/model/app_model.dart';
import 'package:en_passant/views/components/chess_view/chess_board_widget.dart';
import 'package:en_passant/views/components/chess_view/game_info_and_controls.dart';
import 'package:en_passant/views/components/chess_view/promotion_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'components/chess_view/game_info_and_controls/game_status.dart';
import 'components/shared/bottom_padding.dart';

class ChessView extends StatefulWidget {
  final AppModel appModel;

  ChessView(this.appModel);

  @override
  _ChessViewState createState() => _ChessViewState(appModel);
}

class _ChessViewState extends State<ChessView> with WidgetsBindingObserver {
  AppModel appModel;

  _ChessViewState(this.appModel);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (!appModel.gameOver) {
        appModel.saveGameState();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, appModel, child) {
        if (appModel.promotionRequested) {
          appModel.promotionRequested = false;
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _showPromotionDialog(appModel));
        }
        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) {
              appModel.exitChessView();
            }
          },
          child: Container(
            decoration: BoxDecoration(gradient: appModel.theme.background),
            padding: EdgeInsets.all(30),
            child: Column(
              children: [
                Spacer(),
                ChessBoardWidget(appModel),
                SizedBox(height: 30),
                GameStatus(),
                Spacer(),
                GameInfoAndControls(appModel),
                BottomPadding(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPromotionDialog(AppModel appModel) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return PromotionDialog(appModel);
      },
    );
  }
}
