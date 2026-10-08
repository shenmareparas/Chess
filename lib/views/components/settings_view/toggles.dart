import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import '../../../logic/notification_service.dart';
import '../../../model/app_model.dart';
import '../shared/glass_panel.dart';
import 'toggle.dart';

class Toggles extends StatelessWidget {
  final AppModel appModel;

  const Toggles(this.appModel, {Key? key}) : super(key: key);

  void _showPermissionDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: GlassPanel(
              borderRadius: 24,
              padding: const EdgeInsets.all(20),
              color: const Color(0x80201F1F),
              animation: anim1,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Notifications Blocked',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE5E2E1),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Notifications are turned off in your system settings. Please enable them to receive daily chess practice reminders.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFC3C8C2),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        // Cancel Button
                        Expanded(
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Container(
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFC3C8C2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Settings Button
                        Expanded(
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              NotificationService.instance
                                  .openNotificationSettings();
                            },
                            child: Container(
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Settings',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B1B1B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

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
            'Auto-Rotate Board (2P)',
            icon: Icons.sync,
            toggle: appModel.enableRotation,
            setFunc: appModel.setEnableRotation,
          ),
          Divider(height: 1, color: themeColor, thickness: 1),
          Toggle(
            'Auto-Rotate Pieces (2P)',
            icon: Icons.rotate_left_rounded,
            toggle:
                appModel.enableRotation ? false : appModel.enablePieceRotation,
            setFunc: appModel.setEnablePieceRotation,
            enabled: !appModel.enableRotation,
          ),
          Divider(height: 1, color: themeColor, thickness: 1),
          Toggle(
            'Move Hints & Highlights',
            icon: Icons.track_changes_rounded,
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
            'Show Captured Pieces',
            icon: Icons.shield_outlined,
            toggle: appModel.showCapturedPieces,
            setFunc: appModel.setShowCapturedPieces,
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
          Divider(height: 1, color: themeColor, thickness: 1),
          Toggle(
            'Daily Practice Reminder',
            subtitle: 'Adapts intelligently to your daily play timings',
            icon: Icons.notifications_active_outlined,
            toggle: appModel.dailyPracticeNotification,
            setFunc: (enabled) async {
              if (enabled) {
                // Capture navigator before any async gap to avoid stale context.
                final nav = Navigator.of(context);

                // Check if system notifications are already granted
                final alreadyGranted =
                    await NotificationService.instance.arePermissionsGranted();
                if (alreadyGranted) {
                  appModel.setDailyPracticeNotification(true);
                  return;
                }

                // Try requesting permissions (works on first-ever prompt).
                // After the OS has suppressed further prompts, this returns
                // false immediately without showing any system dialog.
                final granted =
                    await NotificationService.instance.requestPermissions();
                if (granted) {
                  appModel.setDailyPracticeNotification(true);
                  return;
                }

                // Permission denied or OS-suppressed — keep toggle off and
                // show in-app dialog offering to open system notification settings.
                appModel.setDailyPracticeNotification(false);
                _showPermissionDialog(nav.context);
                return;
              }
              appModel.setDailyPracticeNotification(enabled);
            },
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
