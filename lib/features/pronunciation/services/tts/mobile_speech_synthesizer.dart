import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

import 'speech_synthesizer.dart';

TextToSpeechPlayer createTextToSpeechPlayer() => MobileTextToSpeechPlayer();

class MobileTextToSpeechPlayer implements TextToSpeechPlayer {
  final _tts = FlutterTts();
  final _changes = StreamController<bool>.broadcast();
  bool _playing = false;
  MobileTextToSpeechPlayer() {
    _tts.setCompletionHandler(() => _setPlaying(false));
    _tts.setCancelHandler(() => _setPlaying(false));
    _tts.setErrorHandler((_) => _setPlaying(false));
  }
  void _setPlaying(bool value) {
    _playing = value;
    if (!_changes.isClosed) _changes.add(value);
  }

  @override
  bool get isPlaying => _playing;
  @override
  Stream<bool> get isPlayingStream => _changes.stream;
  @override
  Future<void> speak(String text, {double rate = 0.85}) async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(rate * 0.5);
    _setPlaying(true);
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
    _setPlaying(false);
  }

  @override
  void dispose() {
    unawaited(_tts.stop());
    unawaited(_changes.close());
  }
}
