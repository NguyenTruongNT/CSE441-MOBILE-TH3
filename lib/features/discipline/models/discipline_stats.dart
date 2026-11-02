import 'package:flutter/foundation.dart';

/// Represents daily practice metrics for a single date.
@immutable
class DailyPracticeRecord {
  const DailyPracticeRecord({
    required this.date,
    required this.totalSeconds,
    required this.goalMinutes,
  });

  /// Local date (normalized to year-month-day 00:00:00).
  final DateTime date;

  /// Total active practice time in seconds for this day.
  final int totalSeconds;

  /// Daily goal in minutes configured for the user.
  final int goalMinutes;

  /// Practice duration in whole minutes.
  int get minutes => totalSeconds ~/ 60;

  /// Additional remaining seconds after whole minutes.
  int get remainingSeconds => totalSeconds % 60;

  /// Whether the user practiced on this day (duration > 0).
  bool get hasPracticed => totalSeconds > 0;

  /// Whether the user reached or exceeded their daily goal.
  bool get isGoalMet => minutes >= goalMinutes;

  /// Progress ratio towards daily goal (clamped 0.0 to 1.0+).
  double get progressRatio =>
      goalMinutes > 0 ? (totalSeconds / (goalMinutes * 60)).clamp(0.0, 1.0) : 0.0;
}

/// Aggregated discipline and progress statistics for the dashboard.
@immutable
class DisciplineStats {
  const DisciplineStats({
    required this.currentStreak,
    required this.todayRecord,
    required this.weeklyRecords,
    required this.totalWeeklySeconds,
    required this.daysGoalMetThisWeek,
    required this.timeZone,
  });

  /// Current active streak in consecutive days.
  final int currentStreak;

  /// Today's practice record.
  final DailyPracticeRecord todayRecord;

  /// 7-day rolling records (from 6 days ago up to today, in chronological order).
  final List<DailyPracticeRecord> weeklyRecords;

  /// Total seconds practiced in the 7-day period.
  final int totalWeeklySeconds;

  /// Number of days where the daily goal was reached in the 7-day period.
  final int daysGoalMetThisWeek;

  /// Timezone used for date calculations.
  final String timeZone;

  /// Total practice minutes this week.
  int get totalWeeklyMinutes => totalWeeklySeconds ~/ 60;

  /// Percentage of daily goal completed today (0 to 100+).
  int get todayProgressPercent => (todayRecord.progressRatio * 100).round();

  /// Whether today's practice has already been completed.
  bool get isTodayGoalMet => todayRecord.isGoalMet;

  /// Whether user has practiced at all today.
  bool get hasPracticedToday => todayRecord.hasPracticed;
}

