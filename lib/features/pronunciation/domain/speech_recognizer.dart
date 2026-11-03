import 'dart:async';

abstract interface class SpeechRecognizerController {
  Stream<String> get transcriptStream;
  String get latestTranscript;
  bool get isListening;

  Future<void> start({String lang = 'en-US'});
  Future<String> stop();
  void cancel();
  void dispose();
}

