import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../../core/contracts/contracts.dart';
import 'user_data_serializers.dart';
import 'user_data_schema.dart';
import 'user_data_store.dart';

/// SQL migrations are explicit so the same schema is used on Android and WASM.
class LearningDatabase extends GeneratedDatabase {
  LearningDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'english_ai',
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.dart.js'),
                onResult: (result) {
                  if (result.chosenImplementation ==
                      WasmStorageImplementation.inMemory) {
                    throw const AppFailure(
                      AppFailureCode.storage,
                      'Trình duyệt không hỗ trợ lưu dữ liệu bền vững. Hãy dùng cửa sổ thường và cho phép lưu trữ trang web.',
                    );
                  }
                },
              ),
            ),
      );

  @override
  int get schemaVersion => 1;
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async {
      for (final statement in schemaStatements) {
        await customStatement(statement);
      }
    },
    beforeOpen: (_) async => customStatement('PRAGMA foreign_keys = ON'),
  );

  static const schemaStatements = [
    '''CREATE TABLE users (
      id TEXT PRIMARY KEY, display_name TEXT NOT NULL,
      time_zone TEXT NOT NULL, created_at TEXT NOT NULL)''',
    '''CREATE TABLE app_state (
      key TEXT PRIMARY KEY, value TEXT)''',
    '''CREATE TABLE settings (
      user_id TEXT PRIMARY KEY REFERENCES users(id),
      daily_goal_minutes INTEGER NOT NULL CHECK(daily_goal_minutes > 0),
      reminder_enabled INTEGER NOT NULL CHECK(reminder_enabled IN (0,1)),
      reminder_hour INTEGER NOT NULL CHECK(reminder_hour BETWEEN 0 AND 23),
      reminder_minute INTEGER NOT NULL CHECK(reminder_minute BETWEEN 0 AND 59),
      time_zone TEXT NOT NULL)''',
    '''CREATE TABLE sessions (
      id TEXT PRIMARY KEY, user_id TEXT NOT NULL REFERENCES users(id),
      exercise_id TEXT NOT NULL, started_at TEXT NOT NULL, ended_at TEXT NOT NULL,
      duration_seconds INTEGER NOT NULL CHECK(duration_seconds >= 0),
      status TEXT NOT NULL CHECK(status IN ('completed','cancelled','analysisFailed')))''',
    'CREATE INDEX sessions_user_date ON sessions(user_id, started_at)',
    '''CREATE TABLE results (
      id TEXT PRIMARY KEY, session_id TEXT NOT NULL UNIQUE REFERENCES sessions(id),
      reference_text TEXT NOT NULL, recognized_text TEXT NOT NULL,
      overall_score REAL NOT NULL CHECK(overall_score BETWEEN 0 AND 100),
      provider TEXT NOT NULL, model_version TEXT NOT NULL, analyzed_at TEXT NOT NULL)''',
    '''CREATE TABLE phoneme_feedback (
      result_id TEXT NOT NULL REFERENCES results(id), position INTEGER NOT NULL,
      word TEXT NOT NULL, expected_ipa TEXT NOT NULL, recognized_ipa TEXT,
      score REAL CHECK(score BETWEEN 0 AND 100),
      status TEXT NOT NULL CHECK(status IN ('correct','needsPractice','notAssessed')),
      start_ms INTEGER, end_ms INTEGER, suggestion TEXT NOT NULL,
      PRIMARY KEY(result_id, position),
      CHECK((start_ms IS NULL AND end_ms IS NULL) OR
        (start_ms >= 0 AND end_ms >= start_ms)))''',
  ];

  Future<List<Map<String, dynamic>>> rows(
    String sql, [
    List<Object> args = const [],
  ]) async => (await customSelect(
    sql,
    variables: args.map(_variable).toList(),
  ).get()).map((row) => row.data).toList();

  Future<void> execute(String sql, [List<Object?> args = const []]) =>
      customStatement(sql, args);
  static Variable _variable(Object value) =>
      value is int ? Variable<int>(value) : Variable<String>(value.toString());
}

/// Import once, atomically. Keep the original document available for recovery.
Future<void> migrateLegacyUserData(
  LearningDatabase db,
  UserDataStore legacy,
) async {
  if ((await db.rows("SELECT key FROM app_state WHERE key='legacy_import_v1'"))
      .isNotEmpty) {
    return;
  }
  final document = await UserDataDocumentManager(legacy).read();
  final users = DriftUserRepository(db);
  final learning = DriftLearningRepository(db);
  try {
    await db.transaction(() async {
      for (final row in document.users) {
        await users.saveProfile(UserDataSerializers.userProfileFromJson(row));
      }
      for (final row in document.learningSettings) {
        await learning.saveSettings(
          UserDataSerializers.learningSettingsFromJson(row),
        );
      }
      for (final row in document.practiceSessions) {
        final session = UserDataSerializers.practiceSessionFromJson(row);
        final results = document.pronunciationResults.where(
          (r) => r['sessionId'] == session.id,
        );
        await learning.savePractice(
          session: session,
          result: results.isEmpty
              ? null
              : UserDataSerializers.pronunciationResultFromJson(results.first),
        );
      }
      await db.execute(
        "INSERT INTO app_state VALUES ('legacy_import_v1','done')",
      );
    });
  } finally {
    users.dispose();
    learning.dispose();
  }
}

UserProfile _user(Map<String, dynamic> row) => UserProfile(
  id: row['id'] as String,
  displayName: row['display_name'] as String,
  timeZone: row['time_zone'] as String,
  createdAt: DateTime.parse(row['created_at'] as String),
);

PracticeSession _session(Map<String, dynamic> row) => PracticeSession(
  id: row['id'] as String,
  userId: row['user_id'] as String,
  exerciseId: row['exercise_id'] as String,
  startedAt: DateTime.parse(row['started_at'] as String),
  endedAt: DateTime.parse(row['ended_at'] as String),
  durationSeconds: row['duration_seconds'] as int,
  status: PracticeStatus.values.byName(row['status'] as String),
);

class DriftUserRepository extends ChangeNotifier implements UserRepository {
  DriftUserRepository(this.db);
  final LearningDatabase db;

  @override
  Future<List<UserProfile>> listProfiles() async =>
      (await db.rows('SELECT * FROM users ORDER BY created_at, id'))
          .map(_user)
          .toList();

  @override
  Future<UserProfile?> getSelectedProfile() async {
    final rows = await db.rows(
      "SELECT users.* FROM users JOIN app_state ON users.id = app_state.value WHERE app_state.key = 'selected_user'",
    );
    return rows.isEmpty ? null : _user(rows.first);
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    if (profile.id.trim().isEmpty || profile.displayName.trim().isEmpty) {
      throw const AppFailure(
        AppFailureCode.storage,
        'Thông tin tài khoản không hợp lệ.',
      );
    }
    await db.execute(
      '''INSERT INTO users VALUES (?,?,?,?)
      ON CONFLICT(id) DO UPDATE SET display_name=excluded.display_name,
      time_zone=excluded.time_zone''',
      [
        profile.id,
        profile.displayName,
        profile.timeZone,
        profile.createdAt.toIso8601String(),
      ],
    );
    notifyListeners();
  }

  @override
  Future<void> selectProfile(String userId) async {
    if ((await db.rows('SELECT id FROM users WHERE id=?', [userId])).isEmpty) {
      throw const AppFailure(
        AppFailureCode.storage,
        'Không tìm thấy tài khoản.',
      );
    }
    await db.execute(
      "INSERT INTO app_state VALUES ('selected_user',?) ON CONFLICT(key) DO UPDATE SET value=excluded.value",
      [userId],
    );
    notifyListeners();
  }

  Future<void> signOut() async {
    await db.execute("DELETE FROM app_state WHERE key='selected_user'");
    notifyListeners();
  }
}

class DriftLearningRepository extends ChangeNotifier
    implements LearningRepository {
  DriftLearningRepository(this.db);
  final LearningDatabase db;

  Future<void> _requireUser(String id) async {
    if ((await db.rows('SELECT id FROM users WHERE id=?', [id])).isEmpty) {
      throw const AppFailure(
        AppFailureCode.storage,
        'Không tìm thấy tài khoản.',
      );
    }
  }

  @override
  Future<void> savePractice({
    required PracticeSession session,
    PronunciationResult? result,
  }) async {
    if (session.id.isEmpty ||
        session.exerciseId.isEmpty ||
        (session.status == PracticeStatus.completed &&
            (result == null || session.durationSeconds <= 0)) ||
        (session.status != PracticeStatus.completed && result != null) ||
        (result != null && result.sessionId != session.id)) {
      throw const AppFailure(
        AppFailureCode.storage,
        'Phiên luyện và kết quả không nhất quán.',
      );
    }
    await db.transaction(() async {
      await _requireUser(session.userId);
      final existing = await db.rows('SELECT * FROM sessions WHERE id=?', [
        session.id,
      ]);
      if (existing.isNotEmpty) {
        final saved = _session(existing.first);
        if (saved.userId != session.userId ||
            jsonEncode(UserDataSerializers.practiceSessionToJson(saved)) !=
                jsonEncode(
                  UserDataSerializers.practiceSessionToJson(session),
                )) {
          throw const AppFailure(
            AppFailureCode.storage,
            'ID phiên luyện đã tồn tại với dữ liệu khác.',
          );
        }
        final old = await getResult(
          userId: session.userId,
          sessionId: session.id,
        );
        if (jsonEncode(
              old == null
                  ? null
                  : UserDataSerializers.pronunciationResultToJson(old),
            ) !=
            jsonEncode(
              result == null
                  ? null
                  : UserDataSerializers.pronunciationResultToJson(result),
            )) {
          throw const AppFailure(
            AppFailureCode.storage,
            'Kết quả đã lưu khác với lần thử lại.',
          );
        }
        return;
      }
      await db.execute('INSERT INTO sessions VALUES (?,?,?,?,?,?,?)', [
        session.id,
        session.userId,
        session.exerciseId,
        session.startedAt.toIso8601String(),
        session.endedAt.toIso8601String(),
        session.durationSeconds,
        session.status.name,
      ]);
      if (result != null) {
        await db.execute('INSERT INTO results VALUES (?,?,?,?,?,?,?,?)', [
          result.id,
          result.sessionId,
          result.referenceText,
          result.recognizedText,
          result.overallScore,
          result.provider,
          result.modelVersion,
          result.analyzedAt.toIso8601String(),
        ]);
        for (var i = 0; i < result.phonemes.length; i++) {
          final p = result.phonemes[i];
          await db.execute(
            'INSERT INTO phoneme_feedback VALUES (?,?,?,?,?,?,?,?,?,?)',
            [
              result.id,
              i,
              p.word,
              p.expectedIpa,
              p.recognizedIpa,
              p.score,
              p.status.name,
              p.startMilliseconds,
              p.endMilliseconds,
              p.suggestion,
            ],
          );
        }
      }
    });
    notifyListeners();
  }

  @override
  Future<List<PracticeSession>> listSessions({
    required String userId,
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    if (!fromUtc.isBefore(toUtc)) {
      throw const AppFailure(
        AppFailureCode.storage,
        'Khoảng thời gian không hợp lệ.',
      );
    }
    await _requireUser(userId);
    return (await db.rows(
      'SELECT * FROM sessions WHERE user_id=? AND started_at>=? AND started_at<? ORDER BY started_at DESC, id DESC',
      [
        userId,
        fromUtc.toUtc().toIso8601String(),
        toUtc.toUtc().toIso8601String(),
      ],
    )).map(_session).toList();
  }

  @override
  Future<PronunciationResult?> getResult({
    required String userId,
    required String sessionId,
  }) async {
    await _requireUser(userId);
    final sessions = await db.rows('SELECT user_id FROM sessions WHERE id=?', [
      sessionId,
    ]);
    if (sessions.isEmpty) return null;
    if (sessions.first['user_id'] != userId) {
      throw const AppFailure(
        AppFailureCode.storage,
        'Tài khoản không sở hữu phiên luyện.',
      );
    }
    final rows = await db.rows('SELECT * FROM results WHERE session_id=?', [
      sessionId,
    ]);
    if (rows.isEmpty) return null;
    final r = rows.first;
    final feedback = await db.rows(
      'SELECT * FROM phoneme_feedback WHERE result_id=? ORDER BY position',
      [r['id'] as String],
    );
    return PronunciationResult(
      id: r['id'] as String,
      sessionId: sessionId,
      referenceText: r['reference_text'] as String,
      recognizedText: r['recognized_text'] as String,
      overallScore: (r['overall_score'] as num).toDouble(),
      provider: r['provider'] as String,
      modelVersion: r['model_version'] as String,
      analyzedAt: DateTime.parse(r['analyzed_at'] as String),
      phonemes: feedback
          .map(
            (p) => PhonemeFeedback(
              word: p['word'] as String,
              expectedIpa: p['expected_ipa'] as String,
              recognizedIpa: p['recognized_ipa'] as String?,
              score: (p['score'] as num?)?.toDouble(),
              status: PhonemeStatus.values.byName(p['status'] as String),
              suggestion: p['suggestion'] as String,
              startMilliseconds: p['start_ms'] as int?,
              endMilliseconds: p['end_ms'] as int?,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<LearningSettings> getSettings(String userId) async {
    await _requireUser(userId);
    final rows = await db.rows('SELECT * FROM settings WHERE user_id=?', [
      userId,
    ]);
    if (rows.isEmpty) {
      return LearningSettings(
        userId: userId,
        dailyGoalMinutes: 15,
        reminderEnabled: false,
        reminderHour: 20,
        reminderMinute: 0,
      );
    }
    final r = rows.first;
    return LearningSettings(
      userId: userId,
      dailyGoalMinutes: r['daily_goal_minutes'] as int,
      reminderEnabled: r['reminder_enabled'] == 1,
      reminderHour: r['reminder_hour'] as int,
      reminderMinute: r['reminder_minute'] as int,
      timeZone: r['time_zone'] as String,
    );
  }

  @override
  Future<void> saveSettings(LearningSettings settings) async {
    await _requireUser(settings.userId);
    await db.execute(
      '''INSERT INTO settings VALUES (?,?,?,?,?,?) ON CONFLICT(user_id) DO UPDATE SET
      daily_goal_minutes=excluded.daily_goal_minutes, reminder_enabled=excluded.reminder_enabled,
      reminder_hour=excluded.reminder_hour, reminder_minute=excluded.reminder_minute, time_zone=excluded.time_zone''',
      [
        settings.userId,
        settings.dailyGoalMinutes,
        settings.reminderEnabled ? 1 : 0,
        settings.reminderHour,
        settings.reminderMinute,
        settings.timeZone,
      ],
    );
    notifyListeners();
  }
}
