import 'package:flame_audio/flame_audio.dart';

import '../model/player.dart';

/// Centralized audio playback service.
/// Extracted from AppModel to follow single-responsibility principle.
class AudioService {
  bool _enabled;
  AudioPool? _movePool;
  AudioPool? _winPool;
  AudioPool? _losePool;
  AudioPool? _tiePool;

  AudioService({bool enabled = true}) : _enabled = enabled;

  Future<void> initialize() async {
    try {
      _movePool = await FlameAudio.createPool(
        'piece_moved.mp3',
        maxPlayers: 1,
      );
      _winPool = await FlameAudio.createPool(
        'win.wav',
        maxPlayers: 1,
      );
      _losePool = await FlameAudio.createPool(
        'lose.wav',
        maxPlayers: 1,
      );
      _tiePool = await FlameAudio.createPool(
        'tie.wav',
        maxPlayers: 1,
      );
    } catch (_) {}
  }

  void dispose() {
    _movePool?.dispose();
    _movePool = null;
    _winPool?.dispose();
    _winPool = null;
    _losePool?.dispose();
    _losePool = null;
    _tiePool?.dispose();
    _tiePool = null;
  }

  bool get enabled => _enabled;
  set enabled(bool value) => _enabled = value;

  void playMovedSound() {
    if (!_enabled) return;
    if (_movePool != null) {
      _movePool!.start(volume: 1.0);
    } else {
      FlameAudio.play('piece_moved.mp3', volume: 1.0);
    }
  }

  void _playWin() {
    if (_winPool != null) {
      _winPool!.start(volume: 1.0);
    } else {
      FlameAudio.play('win.wav', volume: 1.0);
    }
  }

  void _playLose() {
    if (_losePool != null) {
      _losePool!.start(volume: 1.0);
    } else {
      FlameAudio.play('lose.wav', volume: 1.0);
    }
  }

  void _playTie() {
    if (_tiePool != null) {
      _tiePool!.start(volume: 1.0);
    } else {
      FlameAudio.play('tie.wav', volume: 1.0);
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
      _playTie();
      return;
    }

    Player winner;
    if (player1TimeLeft == Duration.zero && player2TimeLeft == Duration.zero) {
      winner = turn;
    } else if (player1TimeLeft == Duration.zero) {
      winner = Player.player2;
    } else if (player2TimeLeft == Duration.zero) {
      winner = Player.player1;
    } else {
      winner = turn;
    }

    if (playingWithAI) {
      if (winner == playerSide) {
        _playWin();
      } else {
        _playLose();
      }
    } else {
      _playWin();
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
    if (player1TimeLeft == Duration.zero && player2TimeLeft == Duration.zero) {
      winner = turn;
    } else if (player1TimeLeft == Duration.zero) {
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
