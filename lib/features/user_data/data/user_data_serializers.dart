import '../../../core/contracts/contracts.dart';

/// Chuyển đổi các model dùng chung của ứng dụng sang JSON và ngược lại.
///
/// Tất cả dữ liệu thời gian được chuẩn hóa về UTC trước khi lưu.
/// Dữ liệu sai kiểu hoặc thiếu trường bắt buộc sẽ tạo [AppFailure]
/// với mã lỗi [AppFailureCode.storage].
class UserDataSerializers {
  const UserDataSerializers._();

  // ===================================================================
  // USER PROFILE
  // ===================================================================

  static Map<String, Object?> userProfileToJson(UserProfile profile) {
    return <String, Object?>{
      'id': profile.id,
      'displayName': profile.displayName,
      'timeZone': profile.timeZone,
      'createdAt': profile.createdAt.toUtc().toIso8601String(),
    };
  }

  static UserProfile userProfileFromJson(Map<String, Object?> json) {
    return UserProfile(
      id: _readRequiredString(json, 'id'),
      displayName: _readRequiredString(json, 'displayName'),
      timeZone: _readRequiredString(json, 'timeZone'),
      createdAt: _readUtcDateTime(json, 'createdAt'),
    );
  }

  // ===================================================================
  // LEARNING SETTINGS
  // ===================================================================

  static Map<String, Object?> learningSettingsToJson(
    LearningSettings settings,
  ) {
    return <String, Object?>{
      'userId': settings.userId,
      'dailyGoalMinutes': settings.dailyGoalMinutes,
      'reminderEnabled': settings.reminderEnabled,
      'reminderHour': settings.reminderHour,
      'reminderMinute': settings.reminderMinute,
      'timeZone': settings.timeZone,
    };
  }

  static LearningSettings learningSettingsFromJson(Map<String, Object?> json) {
    try {
      return LearningSettings(
        userId: _readRequiredString(json, 'userId'),
        dailyGoalMinutes: _readRequiredInt(json, 'dailyGoalMinutes'),
        reminderEnabled: _readRequiredBool(json, 'reminderEnabled'),
        reminderHour: _readRequiredInt(json, 'reminderHour'),
        reminderMinute: _readRequiredInt(json, 'reminderMinute'),
        timeZone: _readRequiredString(json, 'timeZone'),
      );
    } on AppFailure {
      rethrow;
    } on ArgumentError catch (error) {
      throw AppFailure(
        AppFailureCode.storage,
        'LearningSettings không hợp lệ: ${error.message}',
      );
    }
  }

  // ===================================================================
  // PRACTICE SESSION
  // ===================================================================

  static Map<String, Object?> practiceSessionToJson(PracticeSession session) {
    return <String, Object?>{
      'id': session.id,
      'userId': session.userId,
      'exerciseId': session.exerciseId,
      'startedAt': session.startedAt.toUtc().toIso8601String(),
      'endedAt': session.endedAt.toUtc().toIso8601String(),
      'durationSeconds': session.durationSeconds,
      'status': session.status.name,
    };
  }

  static PracticeSession practiceSessionFromJson(Map<String, Object?> json) {
    try {
      return PracticeSession(
        id: _readRequiredString(json, 'id'),
        userId: _readRequiredString(json, 'userId'),
        exerciseId: _readRequiredString(json, 'exerciseId'),
        startedAt: _readUtcDateTime(json, 'startedAt'),
        endedAt: _readUtcDateTime(json, 'endedAt'),
        durationSeconds: _readRequiredInt(json, 'durationSeconds'),
        status: _readPracticeStatus(json, 'status'),
      );
    } on AppFailure {
      rethrow;
    } on ArgumentError catch (error) {
      throw AppFailure(
        AppFailureCode.storage,
        'PracticeSession không hợp lệ: ${error.message}',
      );
    }
  }

  // ===================================================================
  // PHONEME FEEDBACK
  // ===================================================================

  static Map<String, Object?> phonemeFeedbackToJson(PhonemeFeedback feedback) {
    return <String, Object?>{
      'word': feedback.word,
      'expectedIpa': feedback.expectedIpa,
      'recognizedIpa': feedback.recognizedIpa,
      'score': feedback.score,
      'status': feedback.status.name,
      'startMilliseconds': feedback.startMilliseconds,
      'endMilliseconds': feedback.endMilliseconds,
      'suggestion': feedback.suggestion,
    };
  }

  static PhonemeFeedback phonemeFeedbackFromJson(Map<String, Object?> json) {
    try {
      return PhonemeFeedback(
        word: _readRequiredString(json, 'word'),
        expectedIpa: _readRequiredString(json, 'expectedIpa'),
        recognizedIpa: _readOptionalString(json, 'recognizedIpa'),
        score: _readOptionalDouble(json, 'score'),
        status: _readPhonemeStatus(json, 'status'),
        startMilliseconds: _readOptionalInt(json, 'startMilliseconds'),
        endMilliseconds: _readOptionalInt(json, 'endMilliseconds'),
        suggestion: _readRequiredString(json, 'suggestion'),
      );
    } on AppFailure {
      rethrow;
    } on ArgumentError catch (error) {
      throw AppFailure(
        AppFailureCode.storage,
        'PhonemeFeedback không hợp lệ: ${error.message}',
      );
    }
  }

  // ===================================================================
  // PRONUNCIATION RESULT
  // ===================================================================

  static Map<String, Object?> pronunciationResultToJson(
    PronunciationResult result,
  ) {
    return <String, Object?>{
      'id': result.id,
      'sessionId': result.sessionId,
      'referenceText': result.referenceText,
      'recognizedText': result.recognizedText,
      'overallScore': result.overallScore,
      'provider': result.provider,
      'modelVersion': result.modelVersion,
      'analyzedAt': result.analyzedAt.toUtc().toIso8601String(),
      'phonemes': result.phonemes
          .map((PhonemeFeedback feedback) => phonemeFeedbackToJson(feedback))
          .toList(),
    };
  }

  static PronunciationResult pronunciationResultFromJson(
    Map<String, Object?> json,
  ) {
    final Object? rawPhonemes = json['phonemes'];

    if (rawPhonemes is! List<Object?>) {
      throw const AppFailure(
        AppFailureCode.storage,
        'Trường "phonemes" phải là danh sách.',
      );
    }

    final List<PhonemeFeedback> phonemes = rawPhonemes.map((Object? item) {
      if (item is! Map<String, Object?>) {
        throw const AppFailure(
          AppFailureCode.storage,
          'Dữ liệu phoneme phải là JSON object.',
        );
      }

      return phonemeFeedbackFromJson(Map<String, Object?>.from(item));
    }).toList();

    try {
      return PronunciationResult(
        id: _readRequiredString(json, 'id'),
        sessionId: _readRequiredString(json, 'sessionId'),
        referenceText: _readRequiredString(json, 'referenceText'),
        recognizedText: _readRequiredString(json, 'recognizedText'),
        overallScore: _readRequiredDouble(json, 'overallScore'),
        provider: _readRequiredString(json, 'provider'),
        modelVersion: _readRequiredString(json, 'modelVersion'),
        analyzedAt: _readUtcDateTime(json, 'analyzedAt'),
        phonemes: phonemes,
      );
    } on AppFailure {
      rethrow;
    } on ArgumentError catch (error) {
      throw AppFailure(
        AppFailureCode.storage,
        'PronunciationResult không hợp lệ: ${error.message}',
      );
    }
  }

  // ===================================================================
  // REQUIRED VALUE HELPERS
  // ===================================================================

  static String _readRequiredString(Map<String, Object?> json, String key) {
    final Object? value = json[key];

    if (value is! String || value.trim().isEmpty) {
      throw AppFailure(
        AppFailureCode.storage,
        'Trường "$key" phải là chuỗi không rỗng.',
      );
    }

    return value;
  }

  static int _readRequiredInt(Map<String, Object?> json, String key) {
    final Object? value = json[key];

    if (value is! int) {
      throw AppFailure(
        AppFailureCode.storage,
        'Trường "$key" phải là số nguyên.',
      );
    }

    return value;
  }

  static bool _readRequiredBool(Map<String, Object?> json, String key) {
    final Object? value = json[key];

    if (value is! bool) {
      throw AppFailure(
        AppFailureCode.storage,
        'Trường "$key" phải là boolean.',
      );
    }

    return value;
  }

  static double _readRequiredDouble(Map<String, Object?> json, String key) {
    final Object? value = json[key];

    if (value is! num) {
      throw AppFailure(AppFailureCode.storage, 'Trường "$key" phải là số.');
    }

    final double convertedValue = value.toDouble();

    if (!convertedValue.isFinite) {
      throw AppFailure(
        AppFailureCode.storage,
        'Trường "$key" phải là số hữu hạn.',
      );
    }

    return convertedValue;
  }

  // ===================================================================
  // OPTIONAL VALUE HELPERS
  // ===================================================================

  static String? _readOptionalString(Map<String, Object?> json, String key) {
    final Object? value = json[key];

    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw AppFailure(
        AppFailureCode.storage,
        'Trường "$key" phải là chuỗi hoặc null.',
      );
    }

    return value;
  }

  static int? _readOptionalInt(Map<String, Object?> json, String key) {
    final Object? value = json[key];

    if (value == null) {
      return null;
    }

    if (value is! int) {
      throw AppFailure(
        AppFailureCode.storage,
        'Trường "$key" phải là số nguyên hoặc null.',
      );
    }

    return value;
  }

  static double? _readOptionalDouble(Map<String, Object?> json, String key) {
    final Object? value = json[key];

    if (value == null) {
      return null;
    }

    if (value is! num) {
      throw AppFailure(
        AppFailureCode.storage,
        'Trường "$key" phải là số hoặc null.',
      );
    }

    final double convertedValue = value.toDouble();

    if (!convertedValue.isFinite) {
      throw AppFailure(
        AppFailureCode.storage,
        'Trường "$key" phải là số hữu hạn hoặc null.',
      );
    }

    return convertedValue;
  }

  // ===================================================================
  // DATE TIME HELPER
  // ===================================================================

  static DateTime _readUtcDateTime(Map<String, Object?> json, String key) {
    final String value = _readRequiredString(json, key);

    try {
      return DateTime.parse(value).toUtc();
    } catch (_) {
      throw AppFailure(
        AppFailureCode.storage,
        'Trường "$key" không phải thời gian hợp lệ.',
      );
    }
  }

  // ===================================================================
  // ENUM HELPERS
  // ===================================================================

  static PracticeStatus _readPracticeStatus(
    Map<String, Object?> json,
    String key,
  ) {
    final String value = _readRequiredString(json, key);

    for (final PracticeStatus status in PracticeStatus.values) {
      if (status.name == value) {
        return status;
      }
    }

    throw AppFailure(
      AppFailureCode.storage,
      'PracticeStatus không hợp lệ: $value.',
    );
  }

  static PhonemeStatus _readPhonemeStatus(
    Map<String, Object?> json,
    String key,
  ) {
    final String value = _readRequiredString(json, key);

    for (final PhonemeStatus status in PhonemeStatus.values) {
      if (status.name == value) {
        return status;
      }
    }

    throw AppFailure(
      AppFailureCode.storage,
      'PhonemeStatus không hợp lệ: $value.',
    );
  }
}
