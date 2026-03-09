import 'package:en_passant/logic/chess_constants.dart';
import 'package:en_passant/model/app_model.dart';
import 'package:en_passant/views/components/chess_view/promotion_option.dart';
import 'package:flutter/cupertino.dart';

class PromotionDialog extends StatelessWidget {
  final AppModel appModel;

  PromotionDialog(this.appModel);

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      actions: [
        Container(
          height: 66,
          child: Row(
            children: PROMOTIONS
                .map(
                  (promotionType) => PromotionOption(
                    appModel,
                    promotionType,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
