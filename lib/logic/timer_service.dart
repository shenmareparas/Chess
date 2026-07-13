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
  ValueNotifier<int> player1DelayLeft = ValueNotifier(0);
  ValueNotifier<int> player2DelayLeft = ValueNotifier(0);
  int _timeLimit = 0;
  String timerMode = 'increment'; // 'increment' or 'delay'
  int _incrementSeconds = 0;
  Player? _lastTurn;

  /// Called when a player's time runs out.
  VoidCallback? onExpired;

  int get timeLimit => _timeLimit;

  void configure(int timeLimitMinutes,
      {int incrementSeconds = 0, String mode = 'increment'}) {
    _timeLimit = timeLimitMinutes;
    _incrementSeconds = incrementSeconds;
    timerMode = mode;

    int initialExtra = (mode == 'increment') ? incrementSeconds : 0;
    player1TimeLeft.value =
        Duration(minutes: timeLimitMinutes) + Duration(seconds: initialExtra);
    player2TimeLeft.value =
        Duration(minutes: timeLimitMinutes) + Duration(seconds: initialExtra);

    player1DelayLeft.value = (mode == 'delay') ? incrementSeconds * 1000 : 0;
    player2DelayLeft.value = 0;
    _lastTurn = null;
  }

  Player Function()? _getCurrentTurn;
  bool Function()? _isGameOver;

  void start(Player Function() getCurrentTurn, bool Function() isGameOver) {
    _getCurrentTurn = getCurrentTurn;
    _isGameOver = isGameOver;
    if (_timeLimit == 0) return;
    _startPeriodicTimer();
  }

  void _startPeriodicTimer() {
    _timer?.cancel();
    _timer =
        async.Timer.periodic(Duration(milliseconds: TIMER_ACCURACY_MS), (_) {
      if (_isGameOver?.call() ?? true) {
        stop();
        return;
      }
      var turn = _getCurrentTurn?.call() ?? Player.player1;
      if (_lastTurn != turn) {
        _lastTurn = turn;
        if (timerMode == 'delay') {
          if (turn == Player.player1) {
            player1DelayLeft.value = _incrementSeconds * 1000;
          } else {
            player2DelayLeft.value = _incrementSeconds * 1000;
          }
        }
      }
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

  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  void resume() {
    if (_timeLimit > 0 &&
        _timer == null &&
        _getCurrentTurn != null &&
        _isGameOver != null) {
      _startPeriodicTimer();
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _getCurrentTurn = null;
    _isGameOver = null;
    _lastTurn = null;
  }

  void reset() {
    pause();
    int initialExtra = (timerMode == 'increment') ? _incrementSeconds : 0;
    player1TimeLeft.value =
        Duration(minutes: _timeLimit) + Duration(seconds: initialExtra);
    player2TimeLeft.value =
        Duration(minutes: _timeLimit) + Duration(seconds: initialExtra);
    player1DelayLeft.value =
        (timerMode == 'delay') ? _incrementSeconds * 1000 : 0;
    player2DelayLeft.value = 0;
    _lastTurn = null;
  }

  void _decrementPlayer1() {
    if (timerMode == 'delay' && player1DelayLeft.value > 0) {
      player1DelayLeft.value =
          (player1DelayLeft.value - TIMER_ACCURACY_MS).clamp(0, 999999).toInt();
      return;
    }
    if (player1TimeLeft.value.inMilliseconds > 0) {
      player1TimeLeft.value = Duration(
          milliseconds:
              player1TimeLeft.value.inMilliseconds - TIMER_ACCURACY_MS);
    }
  }

  void _decrementPlayer2() {
    if (timerMode == 'delay' && player2DelayLeft.value > 0) {
      player2DelayLeft.value =
          (player2DelayLeft.value - TIMER_ACCURACY_MS).clamp(0, 999999).toInt();
      return;
    }
    if (player2TimeLeft.value.inMilliseconds > 0) {
      player2TimeLeft.value = Duration(
          milliseconds:
              player2TimeLeft.value.inMilliseconds - TIMER_ACCURACY_MS);
    }
  }

  void addIncrement(Player player, int incrementSeconds) {
    if (incrementSeconds <= 0 || _timeLimit == 0) return;
    if (player == Player.player1) {
      player1TimeLeft.value += Duration(seconds: incrementSeconds);
    } else {
      player2TimeLeft.value += Duration(seconds: incrementSeconds);
    }
  }
}

typedef VoidCallback = void Function();
