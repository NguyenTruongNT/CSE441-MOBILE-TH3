import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/discipline_stats.dart';

/// 7-day rolling practice time bar chart with summary metrics.
class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({super.key, required this.stats});

  final DisciplineStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    // Determine max value for vertical scaling (minimum 20 for aesthetics)
    final maxMinutesInWeek = stats.weeklyRecords.fold<int>(
      stats.todayRecord.goalMinutes,
      (prev, r) => math.max(prev, r.minutes),
    );
    final chartScaleMax = math.max(maxMinutesInWeek, 25);

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: primaryColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Thời lượng học 7 ngày qua',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3 Quick Metric Cards
            Row(
              children: [
                _buildMetricTile(
                  context,
                  title: 'Chuỗi ngày',
                  value: '${stats.currentStreak} ngày',
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFFF5722),
                  bgColor: const Color(0xFFFFF3E0),
                ),
                const SizedBox(width: 8),
                _buildMetricTile(
                  context,
                  title: 'Tổng tuần',
                  value: '${stats.totalWeeklyMinutes} phút',
                  icon: Icons.timer_outlined,
                  iconColor: primaryColor,
                  bgColor: const Color(0xFFE0F2F1),
                ),
                const SizedBox(width: 8),
                _buildMetricTile(
                  context,
                  title: 'Đạt mục tiêu',
                  value: '${stats.daysGoalMetThisWeek}/7 ngày',
                  icon: Icons.verified_outlined,
                  iconColor: const Color(0xFF2E7D32),
                  bgColor: const Color(0xFFE8F5E9),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 7-day Bars
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(stats.weeklyRecords.length, (index) {
                  final record = stats.weeklyRecords[index];
                  final isToday = index == stats.weeklyRecords.length - 1;
                  return Expanded(
                    child: _buildDayBar(
                      context,
                      record: record,
                      isToday: isToday,
                      chartMax: chartScaleMax,
                      primaryColor: primaryColor,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: iconColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayBar(
    BuildContext context, {
    required DailyPracticeRecord record,
    required bool isToday,
    required int chartMax,
    required Color primaryColor,
  }) {
    // Height calculation (available bar height = 80px)
    const maxBarHeight = 80.0;
    final ratio = (record.minutes / chartMax).clamp(0.0, 1.0);
    final barHeight = math.max(6.0, ratio * maxBarHeight);

    Color barColor;
    if (record.isGoalMet) {
      barColor = const Color(0xFF1B8A5A); // Deep vibrant green when goal reached
    } else if (record.hasPracticed) {
      barColor = primaryColor.withValues(alpha: 0.7); // Light teal
    } else {
      barColor = const Color(0xFFE0E5E3); // Muted gray
    }

    final dayLabel = _formatDayOfWeek(record.date, isToday);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Minutes value label
          Text(
            '${record.minutes}p',
            style: TextStyle(
              fontSize: 10,
              fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
              color: isToday ? primaryColor : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),

          // The Bar Pill
          Tooltip(
            message:
                '${record.date.day}/${record.date.month}: ${record.minutes} phút'
                '${record.isGoalMet ? ' (Đạt mục tiêu)' : ''}',
            child: Container(
              height: barHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(6),
                border: isToday
                    ? Border.all(color: primaryColor, width: 1.5)
                    : null,
              ),
              child: record.isGoalMet
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 6),

          // Day of week / date label
          Text(
            dayLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
              color: isToday ? primaryColor : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDayOfWeek(DateTime date, bool isToday) {
    if (isToday) return 'H.nay';
    switch (date.weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
        return 'CN';
      default:
        return '${date.day}';
    }
  }
}
