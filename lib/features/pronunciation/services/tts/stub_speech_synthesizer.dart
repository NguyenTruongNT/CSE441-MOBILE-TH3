import 'dart:async';
import 'speech_synthesizer.dart';

/// Simulated / fallback speech player for mobile/unit tests.
class StubTextToSpeechPlayer implements TextToSpeechPlayer {
  StubTextToSpeechPlayer();

  final _playingController = StreamController<bool>.broadcast();
  bool _isPlaying = false;
  Timer? _timer;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Stream<bool> get isPlayingStream => _playingController.stream;

  @override
  Future<void> speak(String text, {double rate = 0.85}) async {
    _timer?.cancel();
    _isPlaying = true;
    _playingController.add(true);

    final durationMs = (text.split(' ').length * 400).clamp(1200, 4000);
    _timer = Timer(Duration(milliseconds: durationMs), () {
      _isPlaying = false;
      _playingController.add(false);
    });
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _isPlaying = false;
    _playingController.add(false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playingController.close();
  }
}

TextToSpeechPlayer createTextToSpeechPlayer() => StubTextToSpeechPlayer();

