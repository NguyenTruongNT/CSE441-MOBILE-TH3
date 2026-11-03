import 'package:flutter_test/flutter_test.dart';

import 'package:th3_english_ai/core/contracts/contracts.dart';
import 'package:th3_english_ai/features/user_data/data/persistent_learning_repository.dart';
import 'package:th3_english_ai/features/user_data/data/persistent_user_repository.dart';
import 'package:th3_english_ai/features/user_data/data/user_data_store.dart';

void main() {
  group('PersistentLearningRepository', () {
    late MemoryUserDataStore store;
    late PersistentUserRepository userRepository;
    late PersistentLearningRepository learningRepository;

    setUp(() async {
      store = MemoryUserDataStore();

      userRepository = PersistentUserRepository(store: store);

      learningRepository = PersistentLearningRepository(store: store);

      await userRepository.saveProfile(
        UserProfile(
          id: 'user-a',
          displayName: 'Người dùng A',
          createdAt: DateTime.utc(2026, 11, 1),
        ),
      );

      await userRepository.saveProfile(
        UserProfile(
          id: 'user-b',
          displayName: 'Người dùng B',
          createdAt: DateTime.utc(2026, 11, 2),
        ),
      );
    });

    PracticeSession createCompletedSession({
      String id = 'session-001',
      String userId = 'user-a',
      DateTime? startedAt,
      int durationSeconds = 180,
    }) {
      final DateTime start = startedAt ?? DateTime.utc(2026, 11, 2, 8);

      return PracticeSession(
        id: id,
        userId: userId,
        exerciseId: 'exercise-001',
        startedAt: start,
        endedAt: start.add(Duration(seconds: durationSeconds)),
        durationSeconds: durationSeconds,
        status: PracticeStatus.completed,
      );
    }

    PronunciationResult createResult({
      String id = 'result-001',
      String sessionId = 'session-001',
      double score = 90,
    }) {
      return PronunciationResult(
        id: id,
        sessionId: sessionId,
        referenceText: 'Hello world',
        recognizedText: 'Hello world',
        overallScore: score,
        provider: 'fake-provider',
        modelVersion: '1.0',
        analyzedAt: DateTime.utc(2026, 11, 2, 8, 4),
        phonemes: <PhonemeFeedback>[
          PhonemeFeedback(
            word: 'Hello',
            expectedIpa: 'həˈloʊ',
            recognizedIpa: 'həˈloʊ',
            score: score,
            status: PhonemeStatus.correct,
            startMilliseconds: 0,
            endMilliseconds: 500,
            suggestion: 'Phát âm tốt.',
          ),
        ],
      );
    }

    test('lưu và đọc phiên completed cùng kết quả', () async {
      final PracticeSession session = createCompletedSession();

      final PronunciationResult result = createResult();

      await learningRepository.savePractice(session: session, result: result);

      final List<PracticeSession> sessions = await learningRepository
          .listSessions(
            userId: 'user-a',
            fromUtc: DateTime.utc(2026, 11, 1),
            toUtc: DateTime.utc(2026, 11, 3),
          );

      final PronunciationResult? restored = await learningRepository.getResult(
        userId: 'user-a',
        sessionId: session.id,
      );

      expect(sessions, hasLength(1));
      expect(sessions.single.id, session.id);
      expect(restored, isNotNull);
      expect(restored!.overallScore, 90);
    });

    test('lưu lại cùng session ID và cùng nội dung '
        'không tạo bản ghi trùng', () async {
      final PracticeSession session = createCompletedSession();

      final PronunciationResult result = createResult();

      await learningRepository.savePractice(session: session, result: result);

      await learningRepository.savePractice(session: session, result: result);

      final List<PracticeSession> sessions = await learningRepository
          .listSessions(
            userId: 'user-a',
            fromUtc: DateTime.utc(2026, 11, 1),
            toUtc: DateTime.utc(2026, 11, 3),
          );

      expect(sessions, hasLength(1));
    });

    test('cùng session ID nhưng nội dung khác '
        'bị từ chối', () async {
      final PracticeSession session = createCompletedSession();

      await learningRepository.savePractice(
        session: session,
        result: createResult(),
      );

      final PracticeSession changedSession = createCompletedSession(
        durationSeconds: 240,
      );

      await expectLater(
        learningRepository.savePractice(
          session: changedSession,
          result: createResult(),
        ),
        throwsA(isA<AppFailure>()),
      );
    });

    test('completed không có result bị từ chối', () async {
      await expectLater(
        learningRepository.savePractice(session: createCompletedSession()),
        throwsA(isA<AppFailure>()),
      );
    });

    test('result.sessionId không khớp bị từ chối', () async {
      await expectLater(
        learningRepository.savePractice(
          session: createCompletedSession(),
          result: createResult(sessionId: 'other-session'),
        ),
        throwsA(isA<AppFailure>()),
      );
    });

    test('cancelled có result bị từ chối', () async {
      final PracticeSession cancelledSession = PracticeSession(
        id: 'session-cancelled',
        userId: 'user-a',
        exerciseId: 'exercise-001',
        startedAt: DateTime.utc(2026, 11, 2, 8),
        endedAt: DateTime.utc(2026, 11, 2, 8, 1),
        durationSeconds: 30,
        status: PracticeStatus.cancelled,
      );

      await expectLater(
        learningRepository.savePractice(
          session: cancelledSession,
          result: createResult(sessionId: 'session-cancelled'),
        ),
        throwsA(isA<AppFailure>()),
      );
    });

    test('lịch sử được tách theo user', () async {
      await learningRepository.savePractice(
        session: createCompletedSession(id: 'session-a', userId: 'user-a'),
        result: createResult(id: 'result-a', sessionId: 'session-a'),
      );

      await learningRepository.savePractice(
        session: createCompletedSession(id: 'session-b', userId: 'user-b'),
        result: createResult(id: 'result-b', sessionId: 'session-b'),
      );

      final List<PracticeSession> userASessions = await learningRepository
          .listSessions(
            userId: 'user-a',
            fromUtc: DateTime.utc(2026, 11, 1),
            toUtc: DateTime.utc(2026, 11, 3),
          );

      final List<PracticeSession> userBSessions = await learningRepository
          .listSessions(
            userId: 'user-b',
            fromUtc: DateTime.utc(2026, 11, 1),
            toUtc: DateTime.utc(2026, 11, 3),
          );

      expect(userASessions, hasLength(1));
      expect(userASessions.single.userId, 'user-a');

      expect(userBSessions, hasLength(1));
      expect(userBSessions.single.userId, 'user-b');
    });

    test('user khác không được đọc kết quả', () async {
      await learningRepository.savePractice(
        session: createCompletedSession(),
        result: createResult(),
      );

      await expectLater(
        learningRepository.getResult(
          userId: 'user-b',
          sessionId: 'session-001',
        ),
        throwsA(isA<AppFailure>()),
      );
    });

    test('trả settings mặc định khi chưa lưu', () async {
      final LearningSettings settings = await learningRepository.getSettings(
        'user-a',
      );

      expect(settings.userId, 'user-a');
      expect(settings.dailyGoalMinutes, 15);
      expect(settings.reminderEnabled, isFalse);
      expect(settings.reminderHour, 20);
      expect(settings.reminderMinute, 0);
      expect(settings.timeZone, 'Asia/Ho_Chi_Minh');
    });

    test('lưu settings riêng cho từng user', () async {
      await learningRepository.saveSettings(
        LearningSettings(
          userId: 'user-a',
          dailyGoalMinutes: 30,
          reminderEnabled: true,
          reminderHour: 19,
          reminderMinute: 15,
        ),
      );

      await learningRepository.saveSettings(
        LearningSettings(
          userId: 'user-b',
          dailyGoalMinutes: 20,
          reminderEnabled: false,
          reminderHour: 21,
          reminderMinute: 0,
        ),
      );

      final LearningSettings userASettings = await learningRepository
          .getSettings('user-a');

      final LearningSettings userBSettings = await learningRepository
          .getSettings('user-b');

      expect(userASettings.dailyGoalMinutes, 30);

      expect(userBSettings.dailyGoalMinutes, 20);

      expect(userASettings.reminderEnabled, isTrue);

      expect(userBSettings.reminderEnabled, isFalse);
    });

    test('listSessions lọc theo phạm vi '
        'và sắp mới nhất trước', () async {
      await learningRepository.savePractice(
        session: createCompletedSession(
          id: 'session-old',
          startedAt: DateTime.utc(2026, 11, 1, 8),
        ),
        result: createResult(id: 'result-old', sessionId: 'session-old'),
      );

      await learningRepository.savePractice(
        session: createCompletedSession(
          id: 'session-new',
          startedAt: DateTime.utc(2026, 11, 2, 8),
        ),
        result: createResult(id: 'result-new', sessionId: 'session-new'),
      );

      final List<PracticeSession> sessions = await learningRepository
          .listSessions(
            userId: 'user-a',
            fromUtc: DateTime.utc(2026, 11, 1),
            toUtc: DateTime.utc(2026, 11, 3),
          );

      expect(sessions, hasLength(2));
      expect(sessions.first.id, 'session-new');
      expect(sessions.last.id, 'session-old');
    });

    test('từ chối khoảng ngày không hợp lệ', () async {
      await expectLater(
        learningRepository.listSessions(
          userId: 'user-a',
          fromUtc: DateTime.utc(2026, 11, 3),
          toUtc: DateTime.utc(2026, 11, 2),
        ),
        throwsA(isA<AppFailure>()),
      );
    });
  });
}
