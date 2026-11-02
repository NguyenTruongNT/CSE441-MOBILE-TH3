import '../../../core/contracts/contracts.dart';
import '../models/discipline_stats.dart';

/// Clock typedef for deterministic time testing.
typedef Clock = DateTime Function();

/// Core calculation logic for user discipline, streak, and weekly practice metrics.
class DisciplineCalculator {
  const DisciplineCalculator({Clock? clock}) : _clock = clock ?? DateTime.now;

  final Clock _clock;

  /// Returns the timezone offset for the given timezone identifier.
  /// Defaults to +07:00 (Asia/Ho_Chi_Minh).
  Duration getTimeZoneOffset(String timeZone) {
    switch (timeZone) {
      case 'Asia/Ho_Chi_Minh':
      case 'Asia/Bangkok':
      case 'Asia/Jakarta':
        return const Duration(hours: 7);
      case 'UTC':
        return Duration.zero;
      default:
        return const Duration(hours: 7);
    }
  }

  /// Converts a UTC DateTime to a local calendar date (midnight 00:00:00).
  DateTime toLocalDate(DateTime utcDateTime, String timeZone) {
    final offset = getTimeZoneOffset(timeZone);
    final local = utcDateTime.toUtc().add(offset);
    return DateTime.utc(local.year, local.month, local.day);
  }

  /// Calculates complete discipline statistics from sessions and user settings.
  DisciplineStats computeStats({
    required List<PracticeSession> sessions,
    required LearningSettings settings,
  }) {
    final nowUtc = _clock().toUtc();
    final today = toLocalDate(nowUtc, settings.timeZone);

    // Group active practice seconds by local calendar date.
    final Map<DateTime, int> secondsByDate = {};

    for (final session in sessions) {
      // Rule: Only completed sessions with duration > 0 are valid practice.
      if (session.status != PracticeStatus.completed ||
          session.durationSeconds <= 0) {
        continue;
      }

      // Rule: Attributed to start date in user's profile timezone.
      final sessionLocalDate = toLocalDate(session.startedAt, settings.timeZone);
      secondsByDate[sessionLocalDate] =
          (secondsByDate[sessionLocalDate] ?? 0) + session.durationSeconds;
    }

    // 1. Calculate Streak
    final streak = _calculateStreak(today, secondsByDate);

    // 2. Build 7-day rolling records (from today - 6 days up to today)
    final List<DailyPracticeRecord> weeklyRecords = [];
    int totalWeeklySeconds = 0;
    int daysGoalMet = 0;

    for (var i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final seconds = secondsByDate[date] ?? 0;
      final record = DailyPracticeRecord(
        date: date,
        totalSeconds: seconds,
        goalMinutes: settings.dailyGoalMinutes,
      );
      weeklyRecords.add(record);
      totalWeeklySeconds += seconds;
      if (record.isGoalMet) {
        daysGoalMet++;
      }
    }

    final todayRecord = weeklyRecords.last;

    return DisciplineStats(
      currentStreak: streak,
      todayRecord: todayRecord,
      weeklyRecords: weeklyRecords,
      totalWeeklySeconds: totalWeeklySeconds,
      daysGoalMetThisWeek: daysGoalMet,
      timeZone: settings.timeZone,
    );
  }

  /// Calculates streak in consecutive days based on contracts:
  /// - Only days with practice duration > 0 count.
  /// - Multiple sessions in the same day count as 1 day.
  /// - Streak ends today (if practiced today) or yesterday (if practiced yesterday).
  /// - If last practice was before yesterday, streak resets to 0.
  int _calculateStreak(DateTime today, Map<DateTime, int> secondsByDate) {
    final yesterday = today.subtract(const Duration(days: 1));

    final bool practicedToday = (secondsByDate[today] ?? 0) > 0;
    final bool practicedYesterday = (secondsByDate[yesterday] ?? 0) > 0;

    if (!practicedToday && !practicedYesterday) {
      // Streak broken (last practice was 2+ days ago or never)
      return 0;
    }

    // Start counting backwards from the most recent active day.
    int streakCount = 0;
    DateTime checkDate = practicedToday ? today : yesterday;

    while ((secondsByDate[checkDate] ?? 0) > 0) {
      streakCount++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streakCount;
  }
}

