import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/discipline_stats.dart';

/// 7-day rolling practice time bar chart with interactive day selection and smart analytics.
class WeeklyBarChart extends StatefulWidget {
  const WeeklyBarChart({super.key, required this.stats});

  final DisciplineStats stats;

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart> {
  // Default selected day is today (last item)
  late int _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = widget.stats.weeklyRecords.length - 1;
  }

  @override
  void didUpdateWidget(covariant WeeklyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedDayIndex >= widget.stats.weeklyRecords.length) {
      _selectedDayIndex = widget.stats.weeklyRecords.length - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final records = widget.stats.weeklyRecords;

    // Determine max value for vertical scaling
    final maxMinutesInWeek = records.fold<int>(
      widget.stats.todayRecord.goalMinutes,
      (prev, r) => math.max(prev, r.minutes),
    );
    final chartScaleMax = math.max(maxMinutesInWeek, 25);

    // Compute average minutes per day and best day
    final totalMins = widget.stats.totalWeeklyMinutes;
    final avgMins = (totalMins / 7).toStringAsFixed(1);

    var bestRecord = records.first;
    for (final r in records) {
      if (r.minutes > bestRecord.minutes) {
        bestRecord = r;
      }
    }

    final selectedRecord = (records.isNotEmpty && _selectedDayIndex >= 0 && _selectedDayIndex < records.length)
        ? records[_selectedDayIndex]
        : widget.stats.todayRecord;

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
                  title: 'Chuỗi ngày',
                  value: '${widget.stats.currentStreak} ngày',
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFFF5722),
                  bgColor: const Color(0xFFFFF3E0),
                ),
                const SizedBox(width: 8),
                _buildMetricTile(
                  title: 'Tổng tuần',
                  value: '${widget.stats.totalWeeklyMinutes} phút',
                  icon: Icons.timer_outlined,
                  iconColor: primaryColor,
                  bgColor: const Color(0xFFE0F2F1),
                ),
                const SizedBox(width: 8),
                _buildMetricTile(
                  title: 'Đạt mục tiêu',
                  value: '${widget.stats.daysGoalMetThisWeek}/7 ngày',
                  icon: Icons.verified_outlined,
                  iconColor: const Color(0xFF2E7D32),
                  bgColor: const Color(0xFFE8F5E9),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 2 Smart Analytical Badges (Average & Best day)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8F7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2EBE8)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.analytics_outlined, size: 14, color: Colors.black54),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'TB: $avgMins phút/ngày',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8F7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2EBE8)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_outline_rounded, size: 14, color: Color(0xFFF57F17)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Cao nhất: ${_formatDayOfWeek(bestRecord.date, false)} (${bestRecord.minutes}p)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 7-day Bars with Target Line
            SizedBox(
              height: 140,
              child: Stack(
                children: [
                  // Dashed Target Line for Goal
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 22 + (widget.stats.todayRecord.goalMinutes / chartScaleMax).clamp(0.0, 1.0) * 80.0,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: primaryColor.withValues(alpha: 0.35),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Mốc: ${widget.stats.todayRecord.goalMinutes}p',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // The 7 Bars
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(records.length, (index) {
                      final record = records[index];
                      final isToday = index == records.length - 1;
                      final isSelected = index == _selectedDayIndex;

                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _selectedDayIndex = index;
                            });
                          },
                          child: _buildDayBar(
                            record: record,
                            isToday: isToday,
                            isSelected: isSelected,
                            chartMax: chartScaleMax,
                            primaryColor: primaryColor,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Interactive Day Detail Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FBFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedRecord.isGoalMet
                      ? const Color(0xFF81C784)
                      : const Color(0xFFCFDCD8),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selectedRecord.isGoalMet
                        ? Icons.check_circle_rounded
                        : (selectedRecord.hasPracticed ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                    size: 18,
                    color: selectedRecord.isGoalMet
                        ? const Color(0xFF2E7D32)
                        : (selectedRecord.hasPracticed ? primaryColor : Colors.black38),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_formatFullDate(selectedRecord.date)}: ${selectedRecord.minutes} phút luyện tập',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          selectedRecord.isGoalMet
                              ? 'Đạt mục tiêu ngày (Chỉ tiêu ${selectedRecord.goalMinutes}p)'
                              : (selectedRecord.hasPracticed
                                  ? 'Chưa đạt mục tiêu (${selectedRecord.minutes}/${selectedRecord.goalMinutes}p)'
                                  : 'Chưa có phiên học nào'),
                          style: TextStyle(
                            fontSize: 11,
                            color: selectedRecord.isGoalMet
                                ? const Color(0xFF2E7D32)
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${selectedRecord.minutes}p',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: selectedRecord.isGoalMet
                          ? const Color(0xFF2E7D32)
                          : primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
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

  Widget _buildDayBar({
    required DailyPracticeRecord record,
    required bool isToday,
    required bool isSelected,
    required int chartMax,
    required Color primaryColor,
  }) {
    const maxBarHeight = 80.0;
    final ratio = (record.minutes / chartMax).clamp(0.0, 1.0);
    final barHeight = math.max(6.0, ratio * maxBarHeight);

    LinearGradient gradient;
    if (record.isGoalMet) {
      gradient = const LinearGradient(
        colors: [Color(0xFF1B8A5A), Color(0xFF43A047)],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );
    } else if (record.hasPracticed) {
      gradient = LinearGradient(
        colors: [primaryColor, const Color(0xFF4DB6AC)],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );
    } else {
      gradient = const LinearGradient(
        colors: [Color(0xFFE0E5E3), Color(0xFFECEFF1)],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );
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
              fontWeight: (isToday || isSelected) ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF1B8A5A) : (isToday ? primaryColor : Colors.black54),
            ),
          ),
          const SizedBox(height: 4),

          // The Bar Pill
          Tooltip(
            message:
                '${record.date.day}/${record.date.month}: ${record.minutes} phút'
                '${record.isGoalMet ? ' (Đạt mục tiêu)' : ''}',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: barHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(6),
                border: isSelected
                    ? Border.all(color: Colors.black87, width: 2)
                    : (isToday ? Border.all(color: primaryColor, width: 1.5) : null),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
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
              fontWeight: (isToday || isSelected) ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF1B8A5A) : (isToday ? primaryColor : Colors.black54),
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

  String _formatFullDate(DateTime date) {
    const days = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    final dayOfWeek = days[date.weekday - 1];
    return '$dayOfWeek, ${date.day}/${date.month}';
  }
}
