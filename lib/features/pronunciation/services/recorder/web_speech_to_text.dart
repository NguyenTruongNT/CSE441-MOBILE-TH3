// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import '../../domain/pronunciation_logger.dart';
import '../../domain/speech_recognizer.dart';

class WebSpeechRecognizer implements SpeechRecognizerController {
  WebSpeechRecognizer();

  html.SpeechRecognition? _recognition;
  final _transcriptController = StreamController<String>.broadcast();
  String _currentTranscript = '';
  bool _isListening = false;

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

  @override
  String get latestTranscript => _currentTranscript;

  @override
  bool get isListening => _isListening;

  @override
  Future<void> start({String lang = 'en-US'}) async {
    _currentTranscript = '';
    _transcriptController.add('');

    if (!html.SpeechRecognition.supported) {
      PronunciationLogger.warn(
        'STT',
        'Web Speech API không được trình duyệt này hỗ trợ. Vui lòng dùng Chrome, Edge hoặc Opera.',
      );
      return;
    }

    try {
      _recognition?.stop();
      _recognition = html.SpeechRecognition()
        ..continuous = true
        ..interimResults = true
        ..lang = lang;

      _recognition!.onStart.listen((_) {
        _isListening = true;
        PronunciationLogger.stt('Web Speech Recognition đã bắt đầu (ngôn ngữ: $lang)');
      });

      _recognition!.onResult.listen((event) {
        final results = event.results;
        if (results != null && results.isNotEmpty) {
          final buffer = StringBuffer();
          for (var i = 0; i < results.length; i++) {
            final item = results[i];
            if ((item.length ?? 0) > 0) {
              final alt = item.item(0);
              final t = alt.transcript;
              if (t != null && t.isNotEmpty) {
                buffer.write('$t ');
              }
            }
          }
          final text = buffer.toString().trim();
          if (text.isNotEmpty && text != _currentTranscript) {
            _currentTranscript = text;
            _transcriptController.add(_currentTranscript);
            PronunciationLogger.stt('Văn bản nhận dạng thời gian thực: "$_currentTranscript"');
          }
        }
      });

      _recognition!.onError.listen((event) {
        PronunciationLogger.warn('STT', 'Lỗi nhận dạng Web Speech: $event');
      });

      _recognition!.onEnd.listen((_) {
        _isListening = false;
        PronunciationLogger.stt('Web Speech Recognition kết thúc phiên thu âm.');
      });

      _recognition!.start();
    } catch (e, stack) {
      _isListening = false;
      PronunciationLogger.error('STT', 'Không thể khởi động Web Speech Recognition: $e', e, stack);
    }
  }

  @override
  Future<String> stop() async {
    _isListening = false;
    try {
      _recognition?.stop();
    } catch (_) {}
    PronunciationLogger.stt('Dừng nhận dạng STT. Kết quả cuối cùng: "$_currentTranscript"');
    return _currentTranscript;
  }

  @override
  void cancel() {
    _isListening = false;
    try {
      _recognition?.abort();
    } catch (_) {}
    _currentTranscript = '';
    _transcriptController.add('');
    PronunciationLogger.stt('Hủy phiên nhận dạng STT.');
  }

  @override
  void dispose() {
    _isListening = false;
    cancel();
    _transcriptController.close();
  }
}

SpeechRecognizerController createPlatformSpeechRecognizer() => WebSpeechRecognizer();
