import '../../domain/speech_recognizer.dart';

SpeechRecognizerController createPlatformSpeechRecognizer() {
  throw UnsupportedError('No speech recognizer available on this platform.');
}

