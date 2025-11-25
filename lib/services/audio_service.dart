import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  /// Play the selesai.mp3 file when session expires
  Future<void> playSelesaiSound() async {
    try {
      if (_isPlaying) {
        await stopSound();
      }
      
      await _audioPlayer.play(AssetSource('mp3/selesai.mp3'));
      _isPlaying = true;
      
      // Listen for when the audio completes
      _audioPlayer.onPlayerComplete.listen((event) {
        _isPlaying = false;
      });
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error playing selesai sound: $e');
      }
      _isPlaying = false;
    }
  }

  /// Stop the currently playing sound
  Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error stopping sound: $e');
      }
    }
  }

  /// Dispose the audio player
  void dispose() {
    _audioPlayer.dispose();
  }
}