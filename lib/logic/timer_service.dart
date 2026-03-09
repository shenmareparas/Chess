import 'dart:async';

import 'package:en_passant/model/player.dart';

const TIMER_ACCURACY_MS = 100;

/// Isolated timer management for chess game clocks.
/// Extracted from AppModel to follow single-responsibility principle.
class TimerService {
  Timer? _timer;
  Duration player1TimeLeft = Duration.zero;
  Duration player2TimeLeft = Duration.zero;
  int _timeLimit = 0;

  /// Called whenever a timer tick occurs.
  VoidCallback? onTick;

  /// Called when a player's time runs out.
  VoidCallback? onExpired;

  int get timeLimit => _timeLimit;

  void configure(int timeLimitMinutes) {
    _timeLimit = timeLimitMinutes;
    player1TimeLeft = Duration(minutes: timeLimitMinutes);
    player2TimeLeft = Duration(minutes: timeLimitMinutes);
  }

  void start(Player Function() getCurrentTurn, bool Function() isGameOver) {
    if (_timeLimit == 0) return;
    _timer = Timer.periodic(Duration(milliseconds: TIMER_ACCURACY_MS), (_) {
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
      onTick?.call();
      if (player1TimeLeft == Duration.zero ||
          player2TimeLeft == Duration.zero) {
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
    player1TimeLeft = Duration(minutes: _timeLimit);
    player2TimeLeft = Duration(minutes: _timeLimit);
  }

  void _decrementPlayer1() {
    if (player1TimeLeft.inMilliseconds > 0) {
      player1TimeLeft = Duration(
          milliseconds: player1TimeLeft.inMilliseconds - TIMER_ACCURACY_MS);
    }
  }

  void _decrementPlayer2() {
    if (player2TimeLeft.inMilliseconds > 0) {
      player2TimeLeft = Duration(
          milliseconds: player2TimeLeft.inMilliseconds - TIMER_ACCURACY_MS);
    }
  }
}

typedef VoidCallback = void Function();
