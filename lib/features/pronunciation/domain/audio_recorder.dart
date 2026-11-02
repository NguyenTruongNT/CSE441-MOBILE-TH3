import 'dart:async';
import 'package:th3_english_ai/core/contracts/models.dart';

enum AudioRecorderState {
  uninitialized,
  ready,
  recording,
  paused,
  processing,
  error,
}

abstract interface class AudioRecorderController {
  AudioRecorderState get state;
  bool get isRecording;
  int get elapsedMilliseconds;
  Stream<double> get amplitudeStream;
  Stream<AudioRecorderState> get stateStream;

  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<void> startRecording();
  Future<AudioSample> stopRecording();
  Future<void> cancelRecording();
  void dispose();
}
