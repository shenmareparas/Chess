import 'package:flutter/material.dart';

import '../../../logic/chess_constants.dart';
import '../../../model/app_model.dart';
import '../shared/glass_panel.dart';
import 'promotion_option.dart';

class PromotionDialog extends StatelessWidget {
  final AppModel appModel;

  PromotionDialog(this.appModel);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: GlassPanel(
          borderRadius: 32,
          padding: const EdgeInsets.all(28),
          color: const Color(0x80201F1F),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pawn Promotion',
                  style: TextStyle(
                    fontSize: 26,
                    color: Color(0xFFE5E2E1),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Choose a piece to upgrade your pawn',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFC3C8C2),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
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
        ),
      ),
    );
  }
}
