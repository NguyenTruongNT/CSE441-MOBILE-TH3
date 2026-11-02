import 'dart:async';
import '../../domain/pronunciation_logger.dart';
import '../../domain/speech_recognizer.dart';

class MockSpeechRecognizer implements SpeechRecognizerController {
  MockSpeechRecognizer({this.simulatedTranscript = ''});

  String simulatedTranscript;
  final _transcriptController = StreamController<String>.broadcast();
  bool _isListening = false;
  Timer? _timer;

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

  @override
  String get latestTranscript => simulatedTranscript;

  @override
  bool get isListening => _isListening;

  @override
  Future<void> start({String lang = 'en-US'}) async {
    _isListening = true;
    PronunciationLogger.stt('Mock Speech Recognizer đã kích hoạt');

    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 600), () {
      if (_isListening && simulatedTranscript.isNotEmpty) {
        _transcriptController.add(simulatedTranscript);
        PronunciationLogger.stt('Mock STT transcript: "$simulatedTranscript"');
      }
    });
  }

  @override
  Future<String> stop() async {
    _isListening = false;
    _timer?.cancel();
    return simulatedTranscript;
  }

  @override
  void cancel() {
    _isListening = false;
    _timer?.cancel();
  }

  @override
  void dispose() {
    _isListening = false;
    _timer?.cancel();
    _transcriptController.close();
  }
}

SpeechRecognizerController createPlatformSpeechRecognizer() => MockSpeechRecognizer();
