import 'package:th3_english_ai/core/contracts/models.dart';
import 'package:th3_english_ai/core/contracts/ports.dart';

/// In-memory fake repository for standalone pronunciation feature testing and development.
class FakeInternalUserRepository implements UserRepository {
  FakeInternalUserRepository({UserProfile? initialProfile}) {
    final defaultUser = initialProfile ??
        UserProfile(
          id: 'user-dang-001',
          displayName: 'Học viên Đăng',
          createdAt: DateTime.now().toUtc(),
        );
    _profiles[defaultUser.id] = defaultUser;
    _selectedId = defaultUser.id;
  }

  final Map<String, UserProfile> _profiles = {};
  String? _selectedId;

  @override
  Future<List<UserProfile>> listProfiles() async => _profiles.values.toList();

  @override
  Future<UserProfile?> getSelectedProfile() async {
    if (_selectedId == null) return null;
    return _profiles[_selectedId];
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    _profiles[profile.id] = profile;
    _selectedId ??= profile.id;
  }

  @override
  Future<void> selectProfile(String userId) async {
    if (!_profiles.containsKey(userId)) {
      throw ArgumentError('User id $userId does not exist');
    }
    _selectedId = userId;
  }
}

class FakeInternalLearningRepository implements LearningRepository {
  final Map<String, PracticeSession> _sessions = {};
  final Map<String, PronunciationResult> _results = {};
  final Map<String, LearningSettings> _settings = {};

  List<PracticeSession> get savedSessions => _sessions.values.toList();
  List<PronunciationResult> get savedResults => _results.values.toList();

  @override
  Future<void> savePractice({
    required PracticeSession session,
    PronunciationResult? result,
  }) async {
    if (session.status == PracticeStatus.completed && result == null) {
      throw ArgumentError('Completed session must provide a PronunciationResult');
    }
    if (result != null && result.sessionId != session.id) {
      throw ArgumentError('Result sessionId must match session.id');
    }

    _sessions[session.id] = session;
    if (result != null) {
      _results[session.id] = result;
    }
  }

  @override
  Future<List<PracticeSession>> listSessions({
    required String userId,
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    final list = _sessions.values
        .where((s) =>
            s.userId == userId &&
            !s.startedAt.isBefore(fromUtc) &&
            s.startedAt.isBefore(toUtc))
        .toList();
    list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return list;
  }

  @override
  Future<PronunciationResult?> getResult({
    required String userId,
    required String sessionId,
  }) async {
    final session = _sessions[sessionId];
    if (session == null || session.userId != userId) return null;
    return _results[sessionId];
  }

  @override
  Future<LearningSettings> getSettings(String userId) async {
    return _settings[userId] ??
        LearningSettings(
          userId: userId,
          dailyGoalMinutes: 15,
          reminderEnabled: false,
          reminderHour: 20,
          reminderMinute: 0,
        );
  }

  @override
  Future<void> saveSettings(LearningSettings settings) async {
    _settings[settings.userId] = settings;
  }
}

