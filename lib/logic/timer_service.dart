import 'dart:async' as async;

import 'package:flutter/foundation.dart';

import '../model/player.dart';

const TIMER_ACCURACY_MS = 100;

/// Isolated timer management for chess game clocks.
/// Extracted from AppModel to follow single-responsibility principle.
class TimerService {
  async.Timer? _timer;
  ValueNotifier<Duration> player1TimeLeft = ValueNotifier(Duration.zero);
  ValueNotifier<Duration> player2TimeLeft = ValueNotifier(Duration.zero);
  int _timeLimit = 0;

  /// Called when a player's time runs out.
  VoidCallback? onExpired;

  int get timeLimit => _timeLimit;

  void configure(int timeLimitMinutes) {
    _timeLimit = timeLimitMinutes;
    player1TimeLeft.value = Duration(minutes: timeLimitMinutes);
    player2TimeLeft.value = Duration(minutes: timeLimitMinutes);
  }

  void start(Player Function() getCurrentTurn, bool Function() isGameOver) {
    if (_timeLimit == 0) return;
    _timer = async.Timer.periodic(Duration(milliseconds: TIMER_ACCURACY_MS), (_) {
      if (isGameOver()) {
        stop();
        return;
      }
      var turn = getCurrentTurn();
      if (turn == Player.player1) {
        _decrementPlayer1();
      } else {
        _decrementPlayer2();
      }
      if (player1TimeLeft.value == Duration.zero ||
          player2TimeLeft.value == Duration.zero) {
        onExpired?.call();
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void reset() {
    stop();
    player1TimeLeft.value = Duration(minutes: _timeLimit);
    player2TimeLeft.value = Duration(minutes: _timeLimit);
  }

  void _decrementPlayer1() {
    if (player1TimeLeft.value.inMilliseconds > 0) {
      player1TimeLeft.value = Duration(
          milliseconds: player1TimeLeft.value.inMilliseconds - TIMER_ACCURACY_MS);
    }
  }

  void _decrementPlayer2() {
    if (player2TimeLeft.value.inMilliseconds > 0) {
      player2TimeLeft.value = Duration(
          milliseconds: player2TimeLeft.value.inMilliseconds - TIMER_ACCURACY_MS);
    }
  }
}

typedef VoidCallback = void Function();
