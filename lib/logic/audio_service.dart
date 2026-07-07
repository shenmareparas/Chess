import 'package:flame_audio/flame_audio.dart';

import '../model/player.dart';

/// Centralized audio playback service.
/// Extracted from AppModel to follow single-responsibility principle.
class AudioService {
  bool _enabled;
  AudioPool? _moveSoundPool;

  AudioService({bool enabled = true}) : _enabled = enabled;

  Future<void> initialize() async {
    try {
      _moveSoundPool = await FlameAudio.createPool(
        'piece_moved.mp3',
        minPlayers: 1,
        maxPlayers: 4,
      );
    } catch (_) {
      // Fallback gracefully if pool initialization fails
    }
  }

  bool get enabled => _enabled;
  set enabled(bool value) => _enabled = value;

  void playMovedSound() {
    if (!_enabled) return;
    if (_moveSoundPool != null) {
      _moveSoundPool!.start();
    } else {
      FlameAudio.play('piece_moved.mp3');
    }
  }

  void playGameEndSound({
    required bool stalemate,
    required bool playingWithAI,
    required Player playerSide,
    required Player turn,
    required Duration player1TimeLeft,
    required Duration player2TimeLeft,
  }) {
    if (!_enabled) return;

    if (stalemate) {
      FlameAudio.play('tie.wav');
      return;
    }

    Player winner;
    if (player1TimeLeft == Duration.zero) {
      winner = Player.player2;
    } else if (player2TimeLeft == Duration.zero) {
      winner = Player.player1;
    } else {
      winner = turn;
    }

    if (playingWithAI) {
      if (winner == playerSide) {
        FlameAudio.play('win.wav');
      } else {
        FlameAudio.play('lose.wav');
      }
    } else {
      FlameAudio.play('win.wav');
    }
  }

  /// Returns true if the user won (for confetti, etc.)
  bool didUserWin({
    required bool playingWithAI,
    required Player playerSide,
    required Player turn,
    required Duration player1TimeLeft,
    required Duration player2TimeLeft,
  }) {
    Player winner;
    if (player1TimeLeft == Duration.zero) {
      winner = Player.player2;
    } else if (player2TimeLeft == Duration.zero) {
      winner = Player.player1;
    } else {
      winner = turn;
    }
    if (playingWithAI) {
      return winner == playerSide;
    }
    return true;
  }
}
