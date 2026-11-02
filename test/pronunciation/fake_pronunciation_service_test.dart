import 'package:flutter_test/flutter_test.dart';
import 'package:th3_english_ai/core/contracts/ports.dart';
import 'package:th3_english_ai/features/pronunciation/data/audio_sample_fixtures.dart';
import 'package:th3_english_ai/features/pronunciation/data/default_exercises.dart';
import 'package:th3_english_ai/features/pronunciation/services/fake_pronunciation_service.dart';

void main() {
  final exercise = DefaultExercises.catalog.first.exercise;
  final validAudio = AudioSampleFixtures.createWavSample(durationSeconds: 1.8);

  test('Realistic mode returns valid result with phonemes and score', () async {
    final service = FakePronunciationService(
      mode: FakePronunciationMode.realistic,
      simulatedLatency: Duration.zero,
    );

    final result = await service.analyze(
      sessionId: 'sess-fake-01',
      audio: validAudio,
      exercise: exercise,
    );

    expect(result.sessionId, 'sess-fake-01');
    expect(result.overallScore, inInclusiveRange(0.0, 100.0));
    expect(result.phonemes, isNotEmpty);
  });

  test('Network error mode throws AppFailure with network code', () async {
    final service = FakePronunciationService(
      mode: FakePronunciationMode.networkError,
      simulatedLatency: Duration.zero,
    );

    expect(
      () => service.analyze(
        sessionId: 'sess-net-err',
        audio: validAudio,
        exercise: exercise,
      ),
      throwsA(
        isA<AppFailure>().having(
          (e) => e.code,
          'code',
          AppFailureCode.network,
        ),
      ),
    );
  });

  test('Timeout error mode throws AppFailure with timeout code', () async {
    final service = FakePronunciationService(
      mode: FakePronunciationMode.timeoutError,
      simulatedLatency: Duration.zero,
    );

    expect(
      () => service.analyze(
        sessionId: 'sess-timeout',
        audio: validAudio,
        exercise: exercise,
      ),
      throwsA(
        isA<AppFailure>().having(
          (e) => e.code,
          'code',
          AppFailureCode.timeout,
        ),
      ),
    );
  });

  test('Silence mode throws AppFailure with insufficientEvidence code', () async {
    final service = FakePronunciationService(
      mode: FakePronunciationMode.silenceError,
      simulatedLatency: Duration.zero,
    );

    expect(
      () => service.analyze(
        sessionId: 'sess-silence',
        audio: validAudio,
        exercise: exercise,
      ),
      throwsA(
        isA<AppFailure>().having(
          (e) => e.code,
          'code',
          AppFailureCode.insufficientEvidence,
        ),
      ),
    );
  });
}
