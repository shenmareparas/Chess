import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Service to handle in-app updates via the Google Play Store on Android devices.
class InAppUpdateService {
  InAppUpdateService._();
  static final InAppUpdateService instance = InAppUpdateService._();

  bool get _isEnabled => !kIsWeb && Platform.isAndroid;

  /// Checks for available updates and prompts the user using a Google Play Store popup.
  /// Silently handles errors if the Play Store API is not available or if the app
  /// is not running in a Play Store installed context (e.g. debug mode/sideloaded).
  Future<void> checkForUpdate() async {
    if (!_isEnabled) return;

    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (updateInfo.immediateUpdateAllowed) {
          // Perform an immediate (blocking) update flow.
          await InAppUpdate.performImmediateUpdate();
        } else if (updateInfo.flexibleUpdateAllowed) {
          // Start a flexible update flow (downloads in background).
          await InAppUpdate.startFlexibleUpdate();
        }
      }
    } catch (e) {
      debugPrint('InAppUpdateService: Failed to check for updates: $e');
    }
  }
}
