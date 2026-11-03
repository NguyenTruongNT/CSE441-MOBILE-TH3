import '../../domain/speech_recognizer.dart';
import 'speech_to_text_stub.dart'
    if (dart.library.html) 'web_speech_to_text.dart'
    if (dart.library.io) 'mock_speech_to_text.dart';

SpeechRecognizerController getPlatformSpeechRecognizer() =>
    createPlatformSpeechRecognizer();

