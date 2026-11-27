import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update_flutter/in_app_update_flutter.dart';

/// Service to handle in-app updates via Google Play Store (Android) and
/// App Store StoreKit (iOS).
class InAppUpdateService {
  InAppUpdateService._();
  static final InAppUpdateService instance = InAppUpdateService._();

  final InAppUpdateFlutter _plugin = InAppUpdateFlutter();
  StreamSubscription<InstallStateAndroid>? _flexibleUpdateSubscription;

  bool get _isEnabled => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Checks for available updates and prompts the user using native platform UI:
  /// - On Android: Uses Google Play In-App Updates (immediate or flexible flow).
  /// - On iOS: Checks App Store version and displays native StoreKit sheet.
  ///
  /// Silently handles errors if store APIs are unavailable or if running in
  /// debug/sideloaded context.
  Future<void> checkForUpdate() async {
    if (!_isEnabled) return;

    if (Platform.isAndroid) {
      await _checkForUpdateAndroid();
    } else if (Platform.isIOS) {
      await _checkForUpdateIos();
    }
  }

  Future<void> _checkForUpdateAndroid() async {
    try {
      final AppUpdateInfoAndroid updateInfo =
          await _plugin.checkUpdateAndroid();

      // If an update was already downloaded in a previous session, complete it.
      if (updateInfo.installStatus == InstallStatusAndroid.downloaded) {
        await _plugin.completeUpdateAndroid();
        return;
      }

      // If an update is currently downloading from a previous session, monitor it.
      if (updateInfo.installStatus == InstallStatusAndroid.downloading) {
        _listenForFlexibleUpdateCompletion();
        return;
      }

      if (updateInfo.updateAvailability ==
          UpdateAvailabilityAndroid.updateAvailable) {
        if (updateInfo.isFlexibleUpdateAllowed) {
          // Prioritize flexible (background download) flow so gameplay is uninterrupted.
          final result = await _plugin.startFlexibleUpdateAndroid();
          if (result == UpdateResultAndroid.success) {
            _listenForFlexibleUpdateCompletion();
          }
        } else if (updateInfo.isImmediateUpdateAllowed) {
          // Fallback to immediate (blocking) only if flexible is disallowed.
          await _plugin.startImmediateUpdateAndroid();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'InAppUpdateService (Android): Failed to check/start update: $e',
        );
      }
    }
  }

  void _listenForFlexibleUpdateCompletion() {
    _flexibleUpdateSubscription?.cancel();
    _flexibleUpdateSubscription = _plugin.installStateStreamAndroid.listen(
      (InstallStateAndroid state) async {
        if (state.status == InstallStatusAndroid.downloaded) {
          _flexibleUpdateSubscription?.cancel();
          _flexibleUpdateSubscription = null;
          try {
            await _plugin.completeUpdateAndroid();
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                'InAppUpdateService: Failed to complete flexible update: $e',
              );
            }
          }
        }
      },
      onError: (Object error) {
        if (kDebugMode) {
          debugPrint(
            'InAppUpdateService: Flexible update stream error: $error',
          );
        }
        _flexibleUpdateSubscription?.cancel();
        _flexibleUpdateSubscription = null;
      },
    );
  }

  Future<void> _checkForUpdateIos() async {
    try {
      final AppUpdateInfoIos updateInfo = await _plugin.checkUpdateIos();
      if (updateInfo.updateAvailability ==
          UpdateAvailabilityIos.updateAvailable) {
        await _plugin.showUpdateForIos(appStoreId: updateInfo.appStoreId);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('InAppUpdateService (iOS): Failed to check/show update: $e');
      }
    }
  }

  /// Cancels any active flexible update subscription.
  void dispose() {
    _flexibleUpdateSubscription?.cancel();
    _flexibleUpdateSubscription = null;
  }
}
