// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'speech_synthesizer.dart';

/// Real browser speech synthesis using Web Speech API (window.speechSynthesis).
class WebTextToSpeechPlayer implements TextToSpeechPlayer {
  WebTextToSpeechPlayer();

  final _playingController = StreamController<bool>.broadcast();
  bool _isPlaying = false;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Stream<bool> get isPlayingStream => _playingController.stream;

  @override
  Future<void> speak(String text, {double rate = 0.85}) async {
    final synth = html.window.speechSynthesis;
    if (synth == null) {
      return;
    }

    try {
      synth.cancel();
      _isPlaying = false;

      final utterance = html.SpeechSynthesisUtterance(text)
        ..lang = 'en-US'
        ..rate = rate
        ..pitch = 1.0;

      utterance.onStart.listen((_) {
        _isPlaying = true;
        _playingController.add(true);
      });

      utterance.onEnd.listen((_) {
        _isPlaying = false;
        _playingController.add(false);
      });

      utterance.onError.listen((_) {
        _isPlaying = false;
        _playingController.add(false);
      });

      synth.speak(utterance);
    } catch (_) {
      _isPlaying = false;
      _playingController.add(false);
    }
  }

  @override
  Future<void> stop() async {
    try {
      html.window.speechSynthesis?.cancel();
    } catch (_) {}
    _isPlaying = false;
    _playingController.add(false);
  }

  @override
  void dispose() {
    stop();
    _playingController.close();
  }
}

TextToSpeechPlayer createTextToSpeechPlayer() => WebTextToSpeechPlayer();
