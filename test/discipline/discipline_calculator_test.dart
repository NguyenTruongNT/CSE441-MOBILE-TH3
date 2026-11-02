import 'package:flutter_test/flutter_test.dart';
import 'package:th3_english_ai/core/contracts/contracts.dart';
import 'package:th3_english_ai/features/discipline/services/discipline_calculator.dart';

void main() {
  group('DisciplineCalculator', () {
    // Fixed reference time: 2026-11-02 10:00:00 UTC (17:00:00 in Asia/Ho_Chi_Minh)
    final fixedNowUtc = DateTime.utc(2026, 11, 2, 10, 0, 0);
    final calculator = DisciplineCalculator(clock: () => fixedNowUtc);
    final defaultSettings = LearningSettings(
      userId: 'test-user',
      dailyGoalMinutes: 15,
      timeZone: 'Asia/Ho_Chi_Minh',
    );

    test('Maps UTC start time to local calendar date in Asia/Ho_Chi_Minh', () {
      // 2026-11-01 23:30:00 UTC is 2026-11-02 06:30:00 in +07:00
      final utcTime = DateTime.utc(2026, 11, 1, 23, 30, 0);
      final localDate = calculator.toLocalDate(utcTime, 'Asia/Ho_Chi_Minh');
      expect(localDate, DateTime.utc(2026, 11, 2));
    });

    test('Ignores cancelled, analysisFailed and zero-duration sessions', () {
      final sessions = [
        PracticeSession(
          id: 's1',
          userId: 'test-user',
          exerciseId: 'ex1',
          startedAt: DateTime.utc(2026, 11, 2, 3, 0),
          endedAt: DateTime.utc(2026, 11, 2, 3, 5),
          durationSeconds: 300,
          status: PracticeStatus.cancelled,
        ),
        PracticeSession(
          id: 's2',
          userId: 'test-user',
          exerciseId: 'ex2',
          startedAt: DateTime.utc(2026, 11, 2, 4, 0),
          endedAt: DateTime.utc(2026, 11, 2, 4, 5),
          durationSeconds: 300,
          status: PracticeStatus.analysisFailed,
        ),
        PracticeSession(
          id: 's3',
          userId: 'test-user',
          exerciseId: 'ex3',
          startedAt: DateTime.utc(2026, 11, 2, 5, 0),
          endedAt: DateTime.utc(2026, 11, 2, 5, 5),
          durationSeconds: 0,
          status: PracticeStatus.completed,
        ),
      ];

      final stats = calculator.computeStats(
        sessions: sessions,
        settings: defaultSettings,
      );

      expect(stats.todayRecord.totalSeconds, 0);
      expect(stats.currentStreak, 0);
      expect(stats.hasPracticedToday, isFalse);
    });

    test('Combines multiple completed sessions on the same day for time and counts as 1 day for streak', () {
      final sessions = [
        PracticeSession(
          id: 's1',
          userId: 'test-user',
          exerciseId: 'ex1',
          startedAt: DateTime.utc(2026, 11, 2, 1, 0),
          endedAt: DateTime.utc(2026, 11, 2, 1, 10),
          durationSeconds: 600, // 10 minutes
          status: PracticeStatus.completed,
        ),
        PracticeSession(
          id: 's2',
          userId: 'test-user',
          exerciseId: 'ex2',
          startedAt: DateTime.utc(2026, 11, 2, 5, 0),
          endedAt: DateTime.utc(2026, 11, 2, 5, 10),
          durationSeconds: 600, // 10 minutes
          status: PracticeStatus.completed,
        ),
      ];

      final stats = calculator.computeStats(
        sessions: sessions,
        settings: defaultSettings,
      );

      expect(stats.todayRecord.totalSeconds, 1200); // 20 minutes
      expect(stats.todayRecord.minutes, 20);
      expect(stats.isTodayGoalMet, isTrue); // goal is 15 minutes
      expect(stats.currentStreak, 1);
    });

    test('Streak stays active if practiced yesterday even if not yet practiced today', () {
      // Practiced on Nov 1 (yesterday), none on Nov 2 (today)
      final sessions = [
        PracticeSession(
          id: 's1',
          userId: 'test-user',
          exerciseId: 'ex1',
          startedAt: DateTime.utc(2026, 11, 1, 2, 0),
          endedAt: DateTime.utc(2026, 11, 1, 2, 15),
          durationSeconds: 900,
          status: PracticeStatus.completed,
        ),
      ];

      final stats = calculator.computeStats(
        sessions: sessions,
        settings: defaultSettings,
      );

      expect(stats.hasPracticedToday, isFalse);
      expect(stats.currentStreak, 1);
    });

    test('Streak is 0 if last practice was 2 or more days ago', () {
      // Practiced on Oct 31, none on Nov 1 or Nov 2
      final sessions = [
        PracticeSession(
          id: 's1',
          userId: 'test-user',
          exerciseId: 'ex1',
          startedAt: DateTime.utc(2026, 10, 31, 2, 0),
          endedAt: DateTime.utc(2026, 10, 31, 2, 15),
          durationSeconds: 900,
          status: PracticeStatus.completed,
        ),
      ];

      final stats = calculator.computeStats(
        sessions: sessions,
        settings: defaultSettings,
      );

      expect(stats.currentStreak, 0);
    });

    test('Correctly computes multi-day consecutive streak across 5 days', () {
      // Practice every day from Oct 29 to Nov 2 (5 consecutive days)
      final sessions = <PracticeSession>[];
      for (var day = 29; day <= 31; day++) {
        sessions.add(
          PracticeSession(
            id: 's_oct_$day',
            userId: 'test-user',
            exerciseId: 'ex',
            startedAt: DateTime.utc(2026, 10, day, 3, 0),
            endedAt: DateTime.utc(2026, 10, day, 3, 15),
            durationSeconds: 900,
            status: PracticeStatus.completed,
          ),
        );
      }
      for (var day = 1; day <= 2; day++) {
        sessions.add(
          PracticeSession(
            id: 's_nov_$day',
            userId: 'test-user',
            exerciseId: 'ex',
            startedAt: DateTime.utc(2026, 11, day, 3, 0),
            endedAt: DateTime.utc(2026, 11, day, 3, 15),
            durationSeconds: 900,
            status: PracticeStatus.completed,
          ),
        );
      }

      final stats = calculator.computeStats(
        sessions: sessions,
        settings: defaultSettings,
      );

      expect(stats.currentStreak, 5);
      expect(stats.weeklyRecords.length, 7);
      expect(stats.daysGoalMetThisWeek, 5);
    });

    test('Midnight rollover: session starting before midnight belongs to start date', () {
      // Local time in +07:00: started at 23:55 on Nov 1, ended at 00:15 on Nov 2
      // UTC: started at 16:55 on Nov 1, ended at 17:15 on Nov 1
      final sessions = [
        PracticeSession(
          id: 's_midnight',
          userId: 'test-user',
          exerciseId: 'ex',
          startedAt: DateTime.utc(2026, 11, 1, 16, 55),
          endedAt: DateTime.utc(2026, 11, 1, 17, 15),
          durationSeconds: 1200,
          status: PracticeStatus.completed,
        ),
      ];

      final stats = calculator.computeStats(
        sessions: sessions,
        settings: defaultSettings,
      );

      // In local time, Nov 1 received 20 minutes; Nov 2 has 0 minutes.
      final yesterdayRecord = stats.weeklyRecords[stats.weeklyRecords.length - 2];
      expect(yesterdayRecord.minutes, 20);
      expect(stats.todayRecord.minutes, 0);
      // Streak is 1 because practiced yesterday
      expect(stats.currentStreak, 1);
    });
  });
}

