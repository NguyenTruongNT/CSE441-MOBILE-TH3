import 'dart:convert';

import '../../../core/contracts/contracts.dart';
import 'user_data_schema.dart';
import 'user_data_serializers.dart';
import 'user_data_store.dart';

/// Triển khai [LearningRepository] bằng [UserDataStore].
///
/// Repository chịu trách nhiệm:
/// - Lưu phiên luyện tập và kết quả một cách nguyên tử.
/// - Chống lưu trùng theo session ID.
/// - Tách lịch sử và cài đặt theo từng hồ sơ.
/// - Kiểm tra quyền sở hữu trước khi trả kết quả.
/// - Trả cài đặt mặc định nếu người dùng chưa có cấu hình.
class PersistentLearningRepository implements LearningRepository {
  PersistentLearningRepository({required UserDataStore store})
    : _documentManager = UserDataDocumentManager(store);

  final UserDataDocumentManager _documentManager;

  @override
  Future<void> savePractice({
    required PracticeSession session,
    PronunciationResult? result,
  }) async {
    _validateSession(session);
    _validateResultForSession(session: session, result: result);

    final UserDataDocument document = await _documentManager.read();

    _requireUserExists(document, session.userId);

    final int existingSessionIndex = document.practiceSessions.indexWhere((
      Map<String, Object?> json,
    ) {
      return json['id'] == session.id;
    });

    final Map<String, Object?> newSessionJson =
        UserDataSerializers.practiceSessionToJson(session);

    if (existingSessionIndex >= 0) {
      final Map<String, Object?> existingSessionJson =
          document.practiceSessions[existingSessionIndex];

      final PracticeSession existingSession =
          UserDataSerializers.practiceSessionFromJson(existingSessionJson);

      final PronunciationResult? existingResult = _findResultBySessionId(
        document,
        session.id,
      );

      final bool sameSession = _practiceSessionsAreEqual(
        existingSession,
        session,
      );

      final bool sameResult = _pronunciationResultsAreEqual(
        existingResult,
        result,
      );

      if (!sameSession || !sameResult) {
        throw AppFailure(
          AppFailureCode.storage,
          'Session ID "${session.id}" đã tồn tại '
          'với nội dung khác.',
        );
      }

      // Idempotent: cùng session ID và cùng nội dung
      // không tạo thêm bản ghi.
      return;
    }

    document.practiceSessions.add(newSessionJson);

    if (result != null) {
      final bool resultIdExists = document.pronunciationResults.any((
        Map<String, Object?> json,
      ) {
        return json['id'] == result.id;
      });

      if (resultIdExists) {
        throw AppFailure(
          AppFailureCode.storage,
          'Result ID "${result.id}" đã tồn tại.',
        );
      }

      final bool sessionResultExists = document.pronunciationResults.any((
        Map<String, Object?> json,
      ) {
        return json['sessionId'] == session.id;
      });

      if (sessionResultExists) {
        throw AppFailure(
          AppFailureCode.storage,
          'Phiên "${session.id}" đã có kết quả.',
        );
      }

      document.pronunciationResults.add(
        UserDataSerializers.pronunciationResultToJson(result),
      );
    }

    // Chỉ ghi một lần sau khi toàn bộ validation đã đạt.
    await _documentManager.write(document);
  }

  @override
  Future<List<PracticeSession>> listSessions({
    required String userId,
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    final String normalizedUserId = _requireNonEmptyId(userId, 'userId');

    final DateTime normalizedFrom = fromUtc.toUtc();

    final DateTime normalizedTo = toUtc.toUtc();

    if (!normalizedFrom.isBefore(normalizedTo)) {
      throw const AppFailure(
        AppFailureCode.storage,
        'fromUtc phải nhỏ hơn toUtc.',
      );
    }

    final UserDataDocument document = await _documentManager.read();

    _requireUserExists(document, normalizedUserId);

    final List<PracticeSession> sessions = <PracticeSession>[];

    for (final Map<String, Object?> json in document.practiceSessions) {
      final PracticeSession session =
          UserDataSerializers.practiceSessionFromJson(json);

      final bool belongsToUser = session.userId == normalizedUserId;

      final bool isInRange =
          !session.startedAt.isBefore(normalizedFrom) &&
          session.startedAt.isBefore(normalizedTo);

      if (belongsToUser && isInRange) {
        sessions.add(session);
      }
    }

    sessions.sort((PracticeSession first, PracticeSession second) {
      final int startedComparison = second.startedAt.compareTo(first.startedAt);

      if (startedComparison != 0) {
        return startedComparison;
      }

      return second.id.compareTo(first.id);
    });

    return List<PracticeSession>.unmodifiable(sessions);
  }

  @override
  Future<PronunciationResult?> getResult({
    required String userId,
    required String sessionId,
  }) async {
    final String normalizedUserId = _requireNonEmptyId(userId, 'userId');

    final String normalizedSessionId = _requireNonEmptyId(
      sessionId,
      'sessionId',
    );

    final UserDataDocument document = await _documentManager.read();

    _requireUserExists(document, normalizedUserId);

    PracticeSession? ownedSession;

    for (final Map<String, Object?> json in document.practiceSessions) {
      final PracticeSession session =
          UserDataSerializers.practiceSessionFromJson(json);

      if (session.id == normalizedSessionId) {
        ownedSession = session;
        break;
      }
    }

    if (ownedSession == null) {
      return null;
    }

    if (ownedSession.userId != normalizedUserId) {
      throw const AppFailure(
        AppFailureCode.storage,
        'Người dùng không sở hữu phiên luyện tập.',
      );
    }

    return _findResultBySessionId(document, normalizedSessionId);
  }

  @override
  Future<LearningSettings> getSettings(String userId) async {
    final String normalizedUserId = _requireNonEmptyId(userId, 'userId');

    final UserDataDocument document = await _documentManager.read();

    _requireUserExists(document, normalizedUserId);

    for (final Map<String, Object?> json in document.learningSettings) {
      if (json['userId'] == normalizedUserId) {
        return UserDataSerializers.learningSettingsFromJson(json);
      }
    }

    return LearningSettings(
      userId: normalizedUserId,
      dailyGoalMinutes: 15,
      reminderEnabled: false,
      reminderHour: 20,
      reminderMinute: 0,
      timeZone: defaultTimeZone,
    );
  }

  @override
  Future<void> saveSettings(LearningSettings settings) async {
    final String normalizedUserId = _requireNonEmptyId(
      settings.userId,
      'userId',
    );

    final UserDataDocument document = await _documentManager.read();

    _requireUserExists(document, normalizedUserId);

    final int existingIndex = document.learningSettings.indexWhere((
      Map<String, Object?> json,
    ) {
      return json['userId'] == normalizedUserId;
    });

    final Map<String, Object?> settingsJson =
        UserDataSerializers.learningSettingsToJson(settings);

    if (existingIndex >= 0) {
      document.learningSettings[existingIndex] = settingsJson;
    } else {
      document.learningSettings.add(settingsJson);
    }

    await _documentManager.write(document);
  }

  void _validateSession(PracticeSession session) {
    _requireNonEmptyId(session.id, 'session.id');

    _requireNonEmptyId(session.userId, 'session.userId');

    _requireNonEmptyId(session.exerciseId, 'session.exerciseId');

    if (session.status == PracticeStatus.completed &&
        session.durationSeconds <= 0) {
      throw const AppFailure(
        AppFailureCode.storage,
        'Phiên completed phải có thời lượng lớn hơn 0.',
      );
    }
  }

  void _validateResultForSession({
    required PracticeSession session,
    required PronunciationResult? result,
  }) {
    if (session.status == PracticeStatus.completed) {
      if (result == null) {
        throw const AppFailure(
          AppFailureCode.storage,
          'Phiên completed bắt buộc phải có kết quả.',
        );
      }

      if (result.sessionId != session.id) {
        throw const AppFailure(
          AppFailureCode.storage,
          'result.sessionId phải khớp session.id.',
        );
      }

      _requireNonEmptyId(result.id, 'result.id');

      return;
    }

    if (result != null) {
      throw const AppFailure(
        AppFailureCode.storage,
        'Phiên cancelled hoặc analysisFailed '
        'không được có kết quả.',
      );
    }
  }

  void _requireUserExists(UserDataDocument document, String userId) {
    final bool userExists = document.users.any((Map<String, Object?> json) {
      return json['id'] == userId;
    });

    if (!userExists) {
      throw AppFailure(
        AppFailureCode.storage,
        'Không tìm thấy hồ sơ: $userId.',
      );
    }
  }

  String _requireNonEmptyId(String value, String fieldName) {
    final String normalizedValue = value.trim();

    if (normalizedValue.isEmpty) {
      throw AppFailure(
        AppFailureCode.storage,
        '$fieldName không được để trống.',
      );
    }

    return normalizedValue;
  }

  PronunciationResult? _findResultBySessionId(
    UserDataDocument document,
    String sessionId,
  ) {
    for (final Map<String, Object?> json in document.pronunciationResults) {
      if (json['sessionId'] == sessionId) {
        return UserDataSerializers.pronunciationResultFromJson(json);
      }
    }

    return null;
  }

  bool _practiceSessionsAreEqual(
    PracticeSession first,
    PracticeSession second,
  ) {
    return first.id == second.id &&
        first.userId == second.userId &&
        first.exerciseId == second.exerciseId &&
        first.startedAt == second.startedAt &&
        first.endedAt == second.endedAt &&
        first.durationSeconds == second.durationSeconds &&
        first.status == second.status;
  }

  bool _pronunciationResultsAreEqual(
    PronunciationResult? first,
    PronunciationResult? second,
  ) {
    if (identical(first, second)) {
      return true;
    }

    if (first == null || second == null) {
      return false;
    }

    return jsonEncode(UserDataSerializers.pronunciationResultToJson(first)) ==
        jsonEncode(UserDataSerializers.pronunciationResultToJson(second));
  }
}
