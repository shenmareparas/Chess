import 'package:en_passant/model/player.dart';
import 'package:flame_audio/flame_audio.dart';

/// Centralized audio playback service.
/// Extracted from AppModel to follow single-responsibility principle.
class AudioService {
  bool _enabled;

  AudioService({bool enabled = true}) : _enabled = enabled;

  bool get enabled => _enabled;
  set enabled(bool value) => _enabled = value;

  void playMovedSound() {
    if (_enabled) FlameAudio.play('piece_moved.mp3');
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
