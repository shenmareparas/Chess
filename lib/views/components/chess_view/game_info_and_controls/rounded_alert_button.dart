import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../model/app_model.dart';
import '../../shared/rounded_button.dart';

class RoundedAlertButton extends StatelessWidget {
  final String label;
  final Function onConfirm;

  RoundedAlertButton(this.label, {required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return RoundedButton(label, onPressed: () {
      showGeneralDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        barrierDismissible: true,
        barrierLabel: '',
        transitionDuration: Duration(milliseconds: 250),
        pageBuilder: (context, anim1, anim2) {
          return Consumer<AppModel>(
            builder: (context, appModel, child) => Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: BoxConstraints(maxWidth: 340),
                  padding: EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    gradient: appModel.theme.background,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1.5),
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
                        label,
                        style: TextStyle(
                          fontSize: 32,
                          fontFamily: 'Jura',
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 15),
                      Text(
                        'Are you sure you want to ${label.toLowerCase()}?',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Jura',
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 35),
                      RoundedButton(
                        label,
                        onPressed: () {
                          onConfirm();
                          Navigator.pop(context);
                        },
                      ),
                      SizedBox(height: 15),
                      RoundedButton(
                        'Cancel',
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        transitionBuilder: (context, anim1, anim2, child) {
          return Transform.scale(
            scale: 0.95 + 0.05 * anim1.value,
            child: FadeTransition(
              opacity: anim1,
              child: child,
            ),
          );
        },
      );
    });
  }
}
