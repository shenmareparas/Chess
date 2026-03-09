import 'package:en_passant/model/app_model.dart';
import 'package:en_passant/views/components/settings_view/piece_theme_picker.dart';
import 'package:en_passant/views/components/shared/rounded_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'components/settings_view/app_theme_picker.dart';
import 'components/settings_view/toggles.dart';
import 'components/shared/bottom_padding.dart';

import 'package:flutter/material.dart';

class SettingsView extends StatelessWidget {
  void _showResetConfirmation(BuildContext context, AppModel appModel) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: Duration(milliseconds: 250),
      pageBuilder: (dialogContext, anim1, anim2) {
        return Consumer<AppModel>(
          builder: (dialogContext, appModel, child) => Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(maxWidth: 340),
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  gradient: appModel.theme.background,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15), width: 1.5),
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
                      'Reset Settings?',
                      style: TextStyle(
                        fontSize: 32,
                        fontFamily: 'Jura',
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Are you sure you want to reset all settings to their defaults?',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Jura',
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 35),
                    RoundedButton(
                      'Reset',
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        appModel.resetSettingsToDefaults();
                      },
                    ),
                    SizedBox(height: 15),
                    RoundedButton(
                      'Cancel',
                      onPressed: () {
                        Navigator.pop(dialogContext);
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
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, appModel, child) => Container(
        decoration: BoxDecoration(gradient: appModel.theme.background),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(30),
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top),
                  Expanded(
                    child: CupertinoScrollbar(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        physics: ClampingScrollPhysics(),
                        children: [
                          AppThemePicker(),
                          SizedBox(height: 10),
                          PieceThemePicker(),
                          SizedBox(height: 10),
                          Toggles(appModel),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  RoundedButton(
                    'Back',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  BottomPadding(),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 30,
              right: 30,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  _showResetConfirmation(context, appModel);
                },
                child: Icon(
                  Icons.settings_backup_restore_rounded,
                  color: const Color(0x99FFFFFF), // semi-transparent white
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
