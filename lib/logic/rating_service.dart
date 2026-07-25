import 'package:flutter/widgets.dart';
import 'package:in_app_review/in_app_review.dart';

import '../model/user_preferences.dart';

/// Centralized service for Google Play Store / App Store rating prompt.
class RatingService {
  RatingService._privateConstructor();
  static final RatingService instance = RatingService._privateConstructor();

  final InAppReview _inAppReview = InAppReview.instance;

  /// Directly triggers the native Google Play Store in-app rating prompt
  /// after a win before exiting back to the main menu.
  Future<void> showRatingPrompt(
    BuildContext context, {
    required UserPreferences prefs,
    required VoidCallback onComplete,
  }) async {
    if (!prefs.hasRatedApp) {
      try {
        if (await _inAppReview.isAvailable()) {
          await prefs.setHasRatedApp(true);
          await _inAppReview.requestReview();
        } else {
          await prefs.setHasRatedApp(true);
          await _inAppReview.openStoreListing();
        }
      } catch (_) {}
    }
    onComplete();
  }
}
