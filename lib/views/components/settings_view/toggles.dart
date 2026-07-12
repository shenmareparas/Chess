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

    final platform = Theme.of(context).platform;
    final String achievementsSubtitle = 'Enables Google Play Games integration';

    final theme = appModel.theme;

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
          Divider(height: 1, color: themeColor, thickness: 1),
          Toggle(
            'Haptic Feedback',
            icon: Icons.vibration_rounded,
            toggle: appModel.hapticEnabled,
            setFunc: appModel.setHapticEnabled,
          ),
          if (platform != TargetPlatform.iOS) ...[
            Divider(height: 1, color: themeColor, thickness: 1),
            _SettingsTile(
              label: 'Achievements',
              icon: Icons.sports_esports_outlined,
              subtitle: achievementsSubtitle,
              theme: theme,
              onTap: appModel.showAchievements,
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final dynamic
      theme; // Using dynamic to avoid explicit AppTheme import type casting issues if any, or just import/use it directly since it is in scope.

  const _SettingsTile({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.theme,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: theme.lightTile,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFE5E2E1),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFFC3C8C2).withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: const Color(0xFFC3C8C2).withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
