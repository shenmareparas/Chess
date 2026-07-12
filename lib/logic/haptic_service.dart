import 'package:flutter/services.dart';

/// Centralized haptic feedback service.
/// Wraps Flutter's HapticFeedback APIs and honors the user's settings.
class HapticService {
  bool _enabled;

  HapticService({bool enabled = false}) : _enabled = enabled;

  bool get enabled => _enabled;
  set enabled(bool value) => _enabled = value;

  void selection() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  void light() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  void medium() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  void heavy() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  void vibrate() {
    if (!_enabled) return;
    HapticFeedback.vibrate();
  }
}
