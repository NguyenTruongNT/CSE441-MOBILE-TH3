import 'models.dart';

enum AppFailureCode {
  permissionDenied,
  network,
  timeout,
  invalidAudio,
  insufficientEvidence,
  storage,
  unsupported,
  unknown,
}

/// Adapters translate provider/storage errors into this shared exception.
class AppFailure implements Exception {
  const AppFailure(this.code, this.message);

  final AppFailureCode code;
  final String message;

  @override
  String toString() => 'AppFailure(${code.name}): $message';
}

abstract interface class UserRepository {
  Future<List<UserProfile>> listProfiles();
  Future<UserProfile?> getSelectedProfile();
  Future<void> saveProfile(UserProfile profile);
  // Must reject an ID that does not exist.
  Future<void> selectProfile(String userId);
}

abstract interface class LearningRepository {
  /// Atomic, idempotent write by session.id; reject a mismatched result ID.
  /// Completed sessions require a result; failed/cancelled sessions have none.
  Future<void> savePractice({
    required PracticeSession session,
    PronunciationResult? result,
  });

  /// Filter by startedAt: fromUtc inclusive, toUtc exclusive; newest first.
  Future<List<PracticeSession>> listSessions({
    required String userId,
    required DateTime fromUtc,
    required DateTime toUtc,
  });

  /// Enforce user ownership before returning a result.
  Future<PronunciationResult?> getResult({
    required String userId,
    required String sessionId,
  });

  /// Return documented defaults when the user has no saved settings yet.
  Future<LearningSettings> getSettings(String userId);
  Future<void> saveSettings(LearningSettings settings);
}

abstract interface class PronunciationService {
  /// Only return a result when audio provides enough assessment evidence.
  Future<PronunciationResult> analyze({
    required String sessionId,
    required AudioSample audio,
    required Exercise exercise,
  });
}

enum ReminderPermission { granted, denied, unsupported }

abstract interface class ReminderService {
  Future<ReminderPermission> requestPermission();

  /// Replace the user's previous schedule, or cancel when disabled.
  /// The app schedules only the selected profile; cancel the old profile first.
  Future<void> scheduleDaily(LearningSettings settings);
  Future<void> cancel(String userId);
}
