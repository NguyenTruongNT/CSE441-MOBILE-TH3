import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:th3_english_ai/core/contracts/contracts.dart';
import 'package:th3_english_ai/features/discipline/data/fake_discipline_data.dart';
import 'package:th3_english_ai/features/discipline/presentation/progress_page.dart';
import 'package:th3_english_ai/features/discipline/presentation/widgets/streak_hero_card.dart';

class TrackingReminders extends FakeReminderService {
  final cancelled = <String>[];
  @override
  Future<void> cancel(String userId) async {
    cancelled.add(userId);
    await super.cancel(userId);
  }
}

class SlowRepository extends FakeLearningRepository {
  final completer = Completer<LearningSettings>();
  @override
  Future<LearningSettings> getSettings(String userId) => completer.future;
}

class FailingReminders extends TrackingReminders {
  @override
  Future<void> scheduleDaily(LearningSettings settings) async {
    if (settings.reminderEnabled) throw StateError('Không đặt được lịch');
    await super.scheduleDaily(settings);
  }
}

void main() {
  var now = DateTime.utc(2026, 11, 2, 12);
  late FakeUserRepository users;
  late TrackingReminders reminders;
  setUp(() {
    now = DateTime.utc(2026, 11, 2, 12);
    users = FakeUserRepository();
    reminders = TrackingReminders();
  });
  tearDown(() => users.dispose());

  Widget app(FakeLearningRepository learning) => MaterialApp(
    home: Scaffold(
      body: ProgressPage(
        userRepository: users,
        learningRepository: learning,
        reminderService: reminders,
        clock: () => now,
      ),
    ),
  );

  PracticeSession session(int day) {
    final start = DateTime.utc(2026, 11, 2, 10).subtract(Duration(days: day));
    return PracticeSession(
      id: 's-$day',
      userId: 'default-user-01',
      exerciseId: 'demo',
      startedAt: start,
      endedAt: start.add(const Duration(minutes: 1)),
      durationSeconds: 60,
      status: PracticeStatus.completed,
    );
  }

  testWidgets('Dashboard retains all 45 days of streak', (tester) async {
    final learning = FakeLearningRepository(
      initialSessions: List.generate(45, session),
    );
    await tester.pumpWidget(app(learning));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<StreakHeroCard>(find.byType(StreakHeroCard))
          .stats
          .currentStreak,
      45,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Changing profile cancels old reminder and isolates settings/history',
    (tester) async {
      final learning = FakeLearningRepository(
        initialSessions: [session(0)],
        initialSettings: {
          'default-user-01': LearningSettings(
            userId: 'default-user-01',
            reminderEnabled: true,
          ),
          'demo-user-02': LearningSettings(
            userId: 'demo-user-02',
            reminderEnabled: true,
            dailyGoalMinutes: 30,
            timeZone: 'UTC',
          ),
        },
      );
      await tester.pumpWidget(app(learning));
      await tester.pumpAndSettle();
      expect(reminders.scheduled.keys, ['default-user-01']);
      await users.selectProfile('demo-user-02');
      await tester.pump();
      await tester.pumpAndSettle();
      expect(reminders.cancelled, contains('default-user-01'));
      expect(reminders.scheduled.keys, ['demo-user-02']);
      final stats = tester
          .widget<StreakHeroCard>(find.byType(StreakHeroCard))
          .stats;
      expect(stats.currentStreak, 0);
      expect(stats.todayRecord.goalMinutes, 30);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Open dashboard refreshes when a local calendar day changes', (
    tester,
  ) async {
    final learning = FakeLearningRepository(initialSessions: [session(0)]);
    await tester.pumpWidget(app(learning));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<StreakHeroCard>(find.byType(StreakHeroCard))
          .stats
          .hasPracticedToday,
      isTrue,
    );
    now = DateTime.utc(2026, 11, 2, 17, 0, 1);
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
    final stats = tester
        .widget<StreakHeroCard>(find.byType(StreakHeroCard))
        .stats;
    expect(stats.hasPracticedToday, isFalse);
    expect(stats.currentStreak, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Late storage response after disposal does not setState', (
    tester,
  ) async {
    final learning = SlowRepository();
    await tester.pumpWidget(app(learning));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    learning.completer.complete(LearningSettings(userId: 'default-user-01'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final permission in [
    ReminderPermission.denied,
    ReminderPermission.unsupported,
  ]) {
    testWidgets('Permission $permission does not enable reminder', (
      tester,
    ) async {
      reminders.permissionStatus = permission;
      final learning = FakeLearningRepository(initialSessions: []);
      await tester.pumpWidget(app(learning));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(Switch));
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(
        (await learning.getSettings('default-user-01')).reminderEnabled,
        isFalse,
      );
      expect(reminders.scheduled, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Schedule failure is shown without saving enabled settings', (
    tester,
  ) async {
    reminders = FailingReminders();
    final learning = FakeLearningRepository(initialSessions: []);
    await tester.pumpWidget(app(learning));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(
      (await learning.getSettings('default-user-01')).reminderEnabled,
      isFalse,
    );
    expect(find.textContaining('Không lưu được cài đặt'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
