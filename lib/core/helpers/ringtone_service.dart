import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Manages ringtone and dial tone playback for calls.
///
/// Uses [AudioPlayer] from the `audioplayers` package.
/// Call [dispose] when the service is no longer needed.
class RingtoneService {
  AudioPlayer? _player;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  /// Plays the incoming call ringtone on loop.
  Future<void> playRingtone() async {
    await stop();
    try {
      _player = AudioPlayer();
      await _player!.setReleaseMode(ReleaseMode.loop);
      await _player!.setVolume(1.0);
      // Use the bundled ringtone asset.
      // Place your ringtone file at: android/assets/audio/ringtone.mp3
      await _player!.play(AssetSource('audio/ringtone.mp3'));
      _isPlaying = true;
    } catch (e) {
      if (kDebugMode) print('RingtoneService.playRingtone error: $e');
      _isPlaying = false;
    }
  }

  /// Plays a dial/ringback tone for outgoing calls on loop.
  Future<void> playDialTone() async {
    await stop();
    try {
      _player = AudioPlayer();
      await _player!.setReleaseMode(ReleaseMode.loop);
      await _player!.setVolume(0.6);
      // Use the bundled dial tone asset.
      // Place your dial tone file at: android/assets/audio/dial_tone.mp3
      await _player!.play(AssetSource('audio/dial_tone.mp3'));
      _isPlaying = true;
    } catch (e) {
      if (kDebugMode) print('RingtoneService.playDialTone error: $e');
      _isPlaying = false;
    }
  }

  /// Stops any currently playing tone.
  Future<void> stop() async {
    if (_player != null) {
      try {
        await _player!.stop();
        await _player!.dispose();
      } catch (e) {
        if (kDebugMode) print('RingtoneService.stop error: $e');
      }
      _player = null;
      _isPlaying = false;
    }
  }

  /// Release resources.
  void dispose() {
    stop();
  }
}
