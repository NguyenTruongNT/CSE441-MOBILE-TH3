import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:th3_english_ai/core/contracts/contracts.dart';
import 'package:th3_english_ai/features/user_data/data/learning_database.dart';
import 'package:th3_english_ai/features/user_data/data/user_data_store.dart';
import 'package:th3_english_ai/features/user_data/data/persistent_user_repository.dart';
import 'package:th3_english_ai/features/user_data/data/persistent_learning_repository.dart';

void main() {
  late LearningDatabase db;
  late DriftUserRepository users;
  late DriftLearningRepository learning;
  setUp(() async {
    db = LearningDatabase(NativeDatabase.memory());
    users = DriftUserRepository(db);
    learning = DriftLearningRepository(db);
    for (final id in ['a', 'b']) {
      await users.saveProfile(
        UserProfile(id: id, displayName: id, createdAt: DateTime.utc(2026)),
      );
    }
  });
  tearDown(() async {
    users.dispose();
    learning.dispose();
    await db.close();
  });
  PracticeSession session(String id, [String userId = 'a']) => PracticeSession(
    id: id,
    userId: userId,
    exerciseId: 'exercise',
    startedAt: DateTime.utc(2026, 11, 3),
    endedAt: DateTime.utc(2026, 11, 3, 0, 0, 10),
    durationSeconds: 10,
    status: PracticeStatus.completed,
  );
  PronunciationResult result(String id, [String resultId = 'result']) =>
      PronunciationResult(
        id: resultId,
        sessionId: id,
        referenceText: 'think',
        recognizedText: 'think',
        overallScore: 80,
        provider: 'test',
        modelVersion: 'test',
        analyzedAt: DateTime.utc(2026),
        phonemes: [
          PhonemeFeedback(
            word: 'think',
            expectedIpa: 'θ',
            status: PhonemeStatus.correct,
            suggestion: 'OK',
            score: 80,
          ),
        ],
      );
  test(
    'transaction roundtrip and idempotent retry preserve feedback',
    () async {
      await learning.savePractice(
        session: session('one'),
        result: result('one'),
      );
      await learning.savePractice(
        session: session('one'),
        result: result('one'),
      );
      expect(await db.rows('SELECT * FROM sessions'), hasLength(1));
      expect(
        (await learning.getResult(
          userId: 'a',
          sessionId: 'one',
        ))!.phonemes.single.expectedIpa,
        'θ',
      );
      await expectLater(
        learning.getResult(userId: 'b', sessionId: 'one'),
        throwsA(isA<AppFailure>()),
      );
    },
  );
  test('result constraint failure rolls back session insertion', () async {
    await learning.savePractice(session: session('one'), result: result('one'));
    await expectLater(
      learning.savePractice(session: session('two'), result: result('two')),
      throwsA(anything),
    );
    expect(await db.rows("SELECT * FROM sessions WHERE id='two'"), isEmpty);
  });
  test(
    'concurrent settings and practice writes do not lose either update',
    () async {
      await Future.wait([
        learning.savePractice(session: session('one'), result: result('one')),
        learning.saveSettings(
          LearningSettings(
            userId: 'a',
            dailyGoalMinutes: 20,
            reminderEnabled: false,
            reminderHour: 19,
            reminderMinute: 30,
          ),
        ),
      ]);
      expect((await learning.getSettings('a')).dailyGoalMinutes, 20);
      expect(await db.rows('SELECT * FROM sessions'), hasLength(1));
    },
  );
  test('logout clears selected account without deleting history', () async {
    await users.selectProfile('a');
    await learning.savePractice(session: session('one'), result: result('one'));
    await users.signOut();
    expect(await users.getSelectedProfile(), isNull);
    expect(await db.rows('SELECT * FROM sessions'), hasLength(1));
  });

  test(
    'legacy migration imports complete data once and retains original',
    () async {
      final store = MemoryUserDataStore();
      final oldUsers = PersistentUserRepository(store: store);
      final oldLearning = PersistentLearningRepository(store: store);
      await oldUsers.saveProfile(
        UserProfile(
          id: 'legacy',
          displayName: 'Legacy',
          createdAt: DateTime.utc(2026),
        ),
      );
      await oldLearning.savePractice(
        session: session('legacy-session', 'legacy'),
        result: result('legacy-session', 'legacy-result'),
      );
      final original = await store.read();
      await migrateLegacyUserData(db, store);
      await migrateLegacyUserData(db, store);
      expect(
        await db.rows("SELECT * FROM sessions WHERE id='legacy-session'"),
        hasLength(1),
      );
      expect(
        (await learning.getResult(
          userId: 'legacy',
          sessionId: 'legacy-session',
        ))!.phonemes,
        hasLength(1),
      );
      expect(await store.read(), original);
    },
  );
}
