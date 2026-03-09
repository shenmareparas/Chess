import 'package:en_passant/logic/chess_constants.dart';
import 'package:en_passant/model/app_model.dart';
import 'package:en_passant/views/components/chess_view/promotion_option.dart';
import 'package:flutter/material.dart';

class PromotionDialog extends StatelessWidget {
  final AppModel appModel;

  PromotionDialog(this.appModel);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: appModel.theme.background,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 2,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Promote Pawn',
              style: TextStyle(
                fontSize: 28,
                fontFamily: 'Jura',
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: PROMOTIONS
                  .map(
                    (promotionType) => PromotionOption(
                      appModel,
                      promotionType,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
