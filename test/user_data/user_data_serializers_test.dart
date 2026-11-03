import 'package:flutter_test/flutter_test.dart';

import 'package:th3_english_ai/core/contracts/contracts.dart';
import 'package:th3_english_ai/features/user_data/data/user_data_serializers.dart';

void main() {
  group('UserDataSerializers', () {
    test('UserProfile chuyển đổi JSON hai chiều', () {
      final UserProfile profile = UserProfile(
        id: 'user-001',
        displayName: 'Khanh',
        createdAt: DateTime.utc(2026, 11, 2, 8),
      );

      final Map<String, Object?> json = UserDataSerializers.userProfileToJson(
        profile,
      );

      final UserProfile restored = UserDataSerializers.userProfileFromJson(
        json,
      );

      expect(restored.id, profile.id);
      expect(restored.displayName, profile.displayName);
      expect(restored.timeZone, profile.timeZone);
      expect(restored.createdAt, profile.createdAt);
      expect(restored.createdAt.isUtc, isTrue);
    });

    test('LearningSettings chuyển đổi JSON hai chiều', () {
      final LearningSettings settings = LearningSettings(
        userId: 'user-001',
        dailyGoalMinutes: 30,
        reminderEnabled: true,
        reminderHour: 19,
        reminderMinute: 30,
      );

      final Map<String, Object?> json =
          UserDataSerializers.learningSettingsToJson(settings);

      final LearningSettings restored =
          UserDataSerializers.learningSettingsFromJson(json);

      expect(restored.userId, 'user-001');
      expect(restored.dailyGoalMinutes, 30);
      expect(restored.reminderEnabled, isTrue);
      expect(restored.reminderHour, 19);
      expect(restored.reminderMinute, 30);
    });

    test('PracticeSession chuyển đổi JSON hai chiều', () {
      final PracticeSession session = PracticeSession(
        id: 'session-001',
        userId: 'user-001',
        exerciseId: 'exercise-001',
        startedAt: DateTime.utc(2026, 11, 2, 8),
        endedAt: DateTime.utc(2026, 11, 2, 8, 5),
        durationSeconds: 300,
        status: PracticeStatus.completed,
      );

      final Map<String, Object?> json =
          UserDataSerializers.practiceSessionToJson(session);

      final PracticeSession restored =
          UserDataSerializers.practiceSessionFromJson(json);

      expect(restored.id, session.id);
      expect(restored.userId, session.userId);
      expect(restored.exerciseId, session.exerciseId);
      expect(restored.startedAt, session.startedAt);
      expect(restored.endedAt, session.endedAt);
      expect(restored.durationSeconds, 300);
      expect(restored.status, PracticeStatus.completed);
    });

    test('PronunciationResult và phonemes '
        'chuyển đổi JSON hai chiều', () {
      final PronunciationResult result = PronunciationResult(
        id: 'result-001',
        sessionId: 'session-001',
        referenceText: 'Hello world',
        recognizedText: 'Hello world',
        overallScore: 92.5,
        provider: 'fake-provider',
        modelVersion: '1.0',
        analyzedAt: DateTime.utc(2026, 11, 2, 8, 6),
        phonemes: <PhonemeFeedback>[
          PhonemeFeedback(
            word: 'Hello',
            expectedIpa: 'həˈloʊ',
            recognizedIpa: 'həˈloʊ',
            score: 95,
            status: PhonemeStatus.correct,
            startMilliseconds: 0,
            endMilliseconds: 500,
            suggestion: 'Phát âm tốt.',
          ),
        ],
      );

      final Map<String, Object?> json =
          UserDataSerializers.pronunciationResultToJson(result);

      final PronunciationResult restored =
          UserDataSerializers.pronunciationResultFromJson(json);

      expect(restored.id, result.id);
      expect(restored.sessionId, result.sessionId);
      expect(restored.overallScore, 92.5);
      expect(restored.phonemes, hasLength(1));
      expect(restored.phonemes.single.status, PhonemeStatus.correct);
      expect(restored.phonemes.single.expectedIpa, 'həˈloʊ');
    });

    test('từ chối enum không hợp lệ', () {
      final Map<String, Object?> invalidJson = <String, Object?>{
        'id': 'session-001',
        'userId': 'user-001',
        'exerciseId': 'exercise-001',
        'startedAt': '2026-11-02T08:00:00.000Z',
        'endedAt': '2026-11-02T08:05:00.000Z',
        'durationSeconds': 300,
        'status': 'unknown-status',
      };

      expect(
        () => UserDataSerializers.practiceSessionFromJson(invalidJson),
        throwsA(isA<AppFailure>()),
      );
    });
  });
}
