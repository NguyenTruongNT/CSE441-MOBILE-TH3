import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:th3_english_ai/core/contracts/contracts.dart';

void main() {
  test('Profile timestamps normalize an explicit offset to UTC', () {
    final user = UserProfile(
      id: 'user-1',
      displayName: 'Test',
      createdAt: DateTime.parse('2026-11-01T00:30:00+07:00'),
    );
    expect(user.createdAt.isUtc, isTrue);
    expect(user.createdAt.toIso8601String(), '2026-10-31T17:30:00.000Z');
  });

  test('Invalid goal and reminder time are rejected', () {
    expect(
      () => LearningSettings(userId: 'u', dailyGoalMinutes: 0),
      throwsArgumentError,
    );
    expect(
      () => LearningSettings(userId: 'u', reminderHour: 24),
      throwsArgumentError,
    );
    expect(
      () => LearningSettings(userId: 'u', reminderMinute: -1),
      throwsArgumentError,
    );
  });

  test('Invalid or non-finite phoneme scores are rejected', () {
    for (final score in [-1.0, 101.0, double.nan, double.infinity]) {
      expect(
        () => PhonemeFeedback(
          word: 'think',
          expectedIpa: 'θ',
          status: PhonemeStatus.needsPractice,
          suggestion: 'Practice',
          score: score,
        ),
        throwsArgumentError,
      );
    }
  });

  test('Phoneme time range must have both ends and be ordered', () {
    PhonemeFeedback feedback(int? start, int? end) => PhonemeFeedback(
      word: 'think',
      expectedIpa: 'θ',
      status: PhonemeStatus.notAssessed,
      suggestion: '',
      startMilliseconds: start,
      endMilliseconds: end,
    );
    expect(() => feedback(0, null), throwsArgumentError);
    expect(() => feedback(null, 50), throwsArgumentError);
    expect(() => feedback(50, 10), throwsArgumentError);
    expect(() => feedback(-1, 10), throwsArgumentError);
    expect(feedback(null, null).score, isNull);
  });

  test('Audio bytes are copied and cannot be changed by the caller', () {
    final source = Uint8List.fromList([1, 2, 3]);
    final audio = AudioSample(bytes: source, mimeType: 'audio/wav');
    source[0] = 9;
    expect(audio.bytes[0], 1);
    expect(() => audio.bytes[0] = 9, throwsUnsupportedError);
    expect(
      () => AudioSample(bytes: Uint8List(0), mimeType: 'audio/wav'),
      throwsArgumentError,
    );
  });
}
