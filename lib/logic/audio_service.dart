import 'package:sound_effect/sound_effect.dart';

/// Centralized audio playback service.
/// Extracted from AppModel to follow single-responsibility principle.
class AudioService {
  final SoundEffect _soundEffect = SoundEffect();
  bool _enabled;
  bool _isInitialized = false;

  AudioService({bool enabled = true}) : _enabled = enabled;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _soundEffect.initialize(maxStreams: 4);
      await _soundEffect.load('move', 'assets/audio/piece_moved.mp3');
      await _soundEffect.load('win', 'assets/audio/win.wav');
      await _soundEffect.load('lose', 'assets/audio/lose.wav');
      await _soundEffect.load('tie', 'assets/audio/tie.wav');
      _isInitialized = true;
    } catch (_) {}
  }

  void dispose() {
    _soundEffect.release();
    _isInitialized = false;
  }

  bool get enabled => _enabled;
  set enabled(bool value) => _enabled = value;

  void playMovedSound() {
    if (!_enabled) return;
    _soundEffect.play('move', volume: 1.0);
  }

  void _playWin() {
    _soundEffect.play('win', volume: 1.0);
  }

  void _playLose() {
    _soundEffect.play('lose', volume: 1.0);
  }

  void _playTie() {
    _soundEffect.play('tie', volume: 1.0);
  }

  void playGameEndSound({
    required bool userWon,
    required bool stalemate,
    required bool playingWithAI,
  }) {
    if (!_enabled) return;

    if (stalemate) {
      _playTie();
      return;
    }

    if (playingWithAI) {
      if (userWon) {
        _playWin();
      } else {
        _playLose();
      }
    } else {
      _playWin();
    }
  }
}
