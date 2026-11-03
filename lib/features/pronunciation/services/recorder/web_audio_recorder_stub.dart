import '../../domain/audio_recorder.dart';

AudioRecorderController createPlatformAudioRecorder() {
  throw UnsupportedError('No audio recorder available on this platform.');
}

