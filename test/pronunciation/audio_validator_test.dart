import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:th3_english_ai/core/contracts/models.dart';
import 'package:th3_english_ai/core/contracts/ports.dart';
import 'package:th3_english_ai/features/pronunciation/data/audio_sample_fixtures.dart';
import 'package:th3_english_ai/features/pronunciation/domain/audio_validator.dart';

void main() {
  const validator = AudioValidator();

  test('Valid WAV sample passes validation with positive energy', () {
    final audio = AudioSampleFixtures.createWavSample(
      durationSeconds: 1.5,
      frequencyHz: 350.0,
      volume: 0.5,
    );
    final result = validator.validate(audio);
    expect(result.isValid, isTrue);
    expect(result.rmsEnergy, greaterThan(0.01));
    expect(result.durationEstimateSeconds, greaterThanOrEqualTo(1.0));
  });

  test('Empty audio bytes throw invalidAudio', () {
    expect(
      () => AudioSample(bytes: Uint8List(0), mimeType: 'audio/wav'),
      throwsArgumentError,
    );
  });

  test('Unsupported MIME type throws invalidAudio', () {
    final audio = AudioSample(
      bytes: Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
      mimeType: 'video/mp4',
    );
    expect(
      () => validator.validate(audio),
      throwsA(
        isA<AppFailure>().having(
          (e) => e.code,
          'code',
          AppFailureCode.invalidAudio,
        ),
      ),
    );
  });

  test('Silent audio sample throws insufficientEvidence', () {
    final silentAudio = AudioSampleFixtures.createSilentWavSample(durationSeconds: 1.5);
    expect(
      () => validator.validate(silentAudio),
      throwsA(
        isA<AppFailure>().having(
          (e) => e.code,
          'code',
          AppFailureCode.insufficientEvidence,
        ),
      ),
    );
  });

  test('Audio that is too short throws insufficientEvidence', () {
    final shortAudio = AudioSampleFixtures.createTooShortWavSample();
    expect(
      () => validator.validate(shortAudio),
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

