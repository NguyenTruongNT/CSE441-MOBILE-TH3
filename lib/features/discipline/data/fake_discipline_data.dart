import '../../../core/contracts/contracts.dart';

import 'package:flutter/foundation.dart';

import '../services/discipline_time.dart';

/// In-memory mock of [LearningRepository] for independent development and testing.
class FakeLearningRepository implements LearningRepository {
  FakeLearningRepository({
    Map<String, LearningSettings>? initialSettings,
    List<PracticeSession>? initialSessions,
  }) {
    if (initialSessions != null) {
      _sessions.addAll(initialSessions);
    } else {
      _seedDefaultPracticeData();
    }
    if (initialSettings != null) _settings.addAll(initialSettings);
  }

  final Map<String, LearningSettings> _settings = {};
  final List<PracticeSession> _sessions = [];
  final Map<String, PronunciationResult> _results = {};

  /// Populates a realistic 5-day streak and weekly practice records.
  void _seedDefaultPracticeData() {
    final now = DateTime.now().toUtc();
    final local = profileTime(now, 'Asia/Ho_Chi_Minh');
    final midnight = DateTime.utc(
      local.year,
      local.month,
      local.day,
    ).subtract(const Duration(hours: 7));
    const defaultUserId = 'default-user-01';

    _settings[defaultUserId] = LearningSettings(
      userId: defaultUserId,
      dailyGoalMinutes: 15,
      reminderEnabled: false,
      reminderHour: 20,
      reminderMinute: 0,
      timeZone: 'Asia/Ho_Chi_Minh',
    );

    // Day 0 (Today): 10 minutes (600s) - in progress towards 15m goal
    _sessions.add(
      PracticeSession(
        id: 'seed-session-0',
        userId: defaultUserId,
        exerciseId: 'ex-vowel-01',
        startedAt: now.subtract(const Duration(minutes: 10)).isBefore(midnight)
            ? midnight
            : now.subtract(const Duration(minutes: 10)),
        endedAt: now,
        durationSeconds: 600,
        status: PracticeStatus.completed,
      ),
    );

    // Day -1 (Yesterday): 18 minutes (1080s) - Goal Met
    _sessions.add(
      PracticeSession(
        id: 'seed-session-1',
        userId: defaultUserId,
        exerciseId: 'ex-consonant-01',
        startedAt: midnight
            .subtract(const Duration(days: 1))
            .add(const Duration(hours: 10)),
        endedAt: midnight
            .subtract(const Duration(days: 1))
            .add(const Duration(hours: 10, minutes: 18)),
        durationSeconds: 1080,
        status: PracticeStatus.completed,
      ),
    );

    // Day -2 (2 days ago): 2 sessions totaling 22 minutes (1320s) - Goal Met
    _sessions.add(
      PracticeSession(
        id: 'seed-session-2a',
        userId: defaultUserId,
        exerciseId: 'ex-diphthong-01',
        startedAt: midnight
            .subtract(const Duration(days: 2))
            .add(const Duration(hours: 10)),
        endedAt: midnight
            .subtract(const Duration(days: 2))
            .add(const Duration(hours: 10, minutes: 12)),
        durationSeconds: 720,
        status: PracticeStatus.completed,
      ),
    );
    _sessions.add(
      PracticeSession(
        id: 'seed-session-2b',
        userId: defaultUserId,
        exerciseId: 'ex-stress-01',
        startedAt: midnight
            .subtract(const Duration(days: 2))
            .add(const Duration(hours: 11)),
        endedAt: midnight
            .subtract(const Duration(days: 2))
            .add(const Duration(hours: 11, minutes: 10)),
        durationSeconds: 600,
        status: PracticeStatus.completed,
      ),
    );

    // Day -3 (3 days ago): 15 minutes (900s) - Goal Met exactly
    _sessions.add(
      PracticeSession(
        id: 'seed-session-3',
        userId: defaultUserId,
        exerciseId: 'ex-intonation-01',
        startedAt: midnight
            .subtract(const Duration(days: 3))
            .add(const Duration(hours: 10)),
        endedAt: midnight
            .subtract(const Duration(days: 3))
            .add(const Duration(hours: 10, minutes: 15)),
        durationSeconds: 900,
        status: PracticeStatus.completed,
      ),
    );

    // Day -4 (4 days ago): 20 minutes (1200s) - Goal Met
    _sessions.add(
      PracticeSession(
        id: 'seed-session-4',
        userId: defaultUserId,
        exerciseId: 'ex-linking-01',
        startedAt: midnight
            .subtract(const Duration(days: 4))
            .add(const Duration(hours: 10)),
        endedAt: midnight
            .subtract(const Duration(days: 4))
            .add(const Duration(hours: 10, minutes: 20)),
        durationSeconds: 1200,
        status: PracticeStatus.completed,
      ),
    );
  }

  @override
  Future<void> savePractice({
    required PracticeSession session,
    PronunciationResult? result,
  }) async {
    // Atomic idempotent write: replace or add by ID
    final existingIndex = _sessions.indexWhere((s) => s.id == session.id);
    if (existingIndex >= 0) {
      _sessions[existingIndex] = session;
    } else {
      _sessions.add(session);
    }

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
    return _sessions.where((session) {
      return session.userId == userId &&
          !session.startedAt.isBefore(fromUtc) &&
          session.startedAt.isBefore(toUtc);
    }).toList()..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  @override
  Future<PronunciationResult?> getResult({
    required String userId,
    required String sessionId,
  }) async {
    if (!_sessions.any((s) => s.id == sessionId && s.userId == userId)) {
      return null;
    }
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
          timeZone: 'Asia/Ho_Chi_Minh',
        );
  }

  @override
  Future<void> saveSettings(LearningSettings settings) async {
    _settings[settings.userId] = settings;
  }

  /// Helper for live demo: simulates completing a practice session immediately.
  Future<void> addQuickSession({
    required String userId,
    int minutes = 5,
  }) async {
    final now = DateTime.now().toUtc();
    final newSession = PracticeSession(
      id: 'demo-session-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      exerciseId: 'demo-quick-practice',
      startedAt: now.subtract(Duration(minutes: minutes)),
      endedAt: now,
      durationSeconds: minutes * 60,
      status: PracticeStatus.completed,
    );
    await savePractice(session: newSession);
  }
}

/// In-memory mock of [ReminderService] for tests and standalone previews.
class FakeReminderService implements ReminderService {
  ReminderPermission permissionStatus = ReminderPermission.granted;
  final Map<String, LearningSettings> scheduled = {};
  final List<String> testNotifications = [];

  @override
  Future<ReminderPermission> requestPermission() async {
    return permissionStatus;
  }

  @override
  Future<void> scheduleDaily(LearningSettings settings) async {
    if (!settings.reminderEnabled) {
      await cancel(settings.userId);
    } else {
      scheduled.clear();
      scheduled[settings.userId] = settings;
    }
  }

  @override
  Future<void> cancel(String userId) async {
    scheduled.remove(userId);
  }

  Future<bool> sendImmediateTestNotification({
    required String title,
    required String body,
  }) async {
    testNotifications.add('$title: $body');
    return true;
  }
}

/// Two isolated demo profiles; no authentication or durable storage is implied.
class FakeUserRepository extends ChangeNotifier implements UserRepository {
  final List<UserProfile> _profiles = [
    UserProfile(
      id: 'default-user-01',
      displayName: 'Học viên mẫu',
      createdAt: DateTime.utc(2026, 10, 1),
    ),
    UserProfile(
      id: 'demo-user-02',
      displayName: 'Học viên thứ hai',
      timeZone: 'UTC',
      createdAt: DateTime.utc(2026, 10, 1),
    ),
  ];
  String _selected = 'default-user-01';
  @override
  Future<List<UserProfile>> listProfiles() async =>
      List.unmodifiable(_profiles);
  @override
  Future<UserProfile?> getSelectedProfile() async =>
      _profiles.firstWhere((p) => p.id == _selected);
  @override
  Future<void> selectProfile(String userId) async {
    if (!_profiles.any((p) => p.id == userId)) {
      throw ArgumentError('Hồ sơ không tồn tại.');
    }
    _selected = userId;
    notifyListeners();
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    final index = _profiles.indexWhere((p) => p.id == profile.id);
    if (index < 0) {
      _profiles.add(profile);
    } else {
      _profiles[index] = profile;
    }
    notifyListeners();
  }
}
