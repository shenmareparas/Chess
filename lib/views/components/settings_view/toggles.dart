import 'package:flutter/material.dart';
import '../../../model/app_model.dart';
import '../shared/glass_panel.dart';
import 'toggle.dart';

class Toggles extends StatelessWidget {
  final AppModel appModel;

  const Toggles(this.appModel, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeColor =
        const Color(0x1A424843); // outline-variant/10 (0x1A is ~10% opacity)

    return GlassPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Toggle(
            'Board Rotation (2P)',
            icon: Icons.sync,
            toggle: appModel.enableRotation,
            setFunc: appModel.setEnableRotation,
          ),
          Divider(height: 1, color: themeColor, thickness: 1),
          Toggle(
            'Show Hints',
            icon: Icons.lightbulb_outline_rounded,
            toggle: appModel.showHints,
            setFunc: appModel.setShowHints,
          ),
          Divider(height: 1, color: themeColor, thickness: 1),
          Toggle(
            'Show Notation',
            icon: Icons.description_outlined,
            toggle: appModel.showNotation,
            setFunc: appModel.setShowNotation,
          ),
          Divider(height: 1, color: themeColor, thickness: 1),
          Toggle(
            'Allow Undo/Redo',
            icon: Icons.history_rounded,
            toggle: appModel.allowUndoRedo,
            setFunc: appModel.setAllowUndoRedo,
          ),
          Divider(height: 1, color: themeColor, thickness: 1),
          Toggle(
            'Show Move History',
            icon: Icons.list_alt_rounded,
            toggle: appModel.showMoveHistory,
            setFunc: appModel.setShowMoveHistory,
          ),
          Divider(height: 1, color: themeColor, thickness: 1),
          Toggle(
            'Sound',
            icon: Icons.volume_up_rounded,
            toggle: appModel.soundEnabled,
            setFunc: appModel.setSoundEnabled,
          ),
        ],
      ),
    );
  }
}
