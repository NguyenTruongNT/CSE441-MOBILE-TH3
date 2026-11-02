import 'dart:async';
import 'package:th3_english_ai/core/contracts/models.dart';
import 'package:th3_english_ai/core/contracts/ports.dart';
import '../domain/phoneme_scoring_engine.dart';

enum FakePronunciationMode {
  realistic,
  perfect,
  heavyAccent,
  silenceError,
  timeoutError,
  networkError,
}

/// Fake implementation of [PronunciationService] for testing, preview, and independent development.
class FakePronunciationService implements PronunciationService {
  FakePronunciationService({
    this.mode = FakePronunciationMode.realistic,
    this.simulatedLatency = const Duration(milliseconds: 600),
    PhonemeScoringEngine? engine,
  }) : _engine = engine ?? const PhonemeScoringEngine();

  FakePronunciationMode mode;
  Duration simulatedLatency;
  final PhonemeScoringEngine _engine;

  @override
  Future<PronunciationResult> analyze({
    required String sessionId,
    required AudioSample audio,
    required Exercise exercise,
  }) async {
    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }

    switch (mode) {
      case FakePronunciationMode.networkError:
        throw const AppFailure(
          AppFailureCode.network,
          'Mất kết nối mạng tới máy chủ phân tích phát âm. Vui lòng kiểm tra Wi-Fi/4G.',
        );

      case FakePronunciationMode.timeoutError:
        throw const AppFailure(
          AppFailureCode.timeout,
          'Quá thời gian chờ phản hồi từ máy chủ AI. Vui lòng thử lại.',
        );

      case FakePronunciationMode.silenceError:
        throw const AppFailure(
          AppFailureCode.insufficientEvidence,
          'Không ghi nhận tín hiệu âm thanh hợp lệ (quá nhỏ hoặc im lặng).',
        );

      case FakePronunciationMode.perfect:
        return _engine.evaluate(
          sessionId: sessionId,
          audio: audio,
          exercise: exercise,
          acousticScoreBias: 25.0,
          recognizedTranscriptOverride: exercise.referenceText,
        );

      case FakePronunciationMode.heavyAccent:
        return _engine.evaluate(
          sessionId: sessionId,
          audio: audio,
          exercise: exercise,
          acousticScoreBias: -22.0,
        );

      case FakePronunciationMode.realistic:
        return _engine.evaluate(
          sessionId: sessionId,
          audio: audio,
          exercise: exercise,
        );
    }
  }
}
