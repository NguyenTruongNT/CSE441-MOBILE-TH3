import 'dart:async';

/// Interface for native voice audio playback of English reference sentences.
abstract interface class TextToSpeechPlayer {
  Future<void> speak(String text, {double rate = 0.85});
  Future<void> stop();
  bool get isPlaying;
  Stream<bool> get isPlayingStream;
  void dispose();
}
