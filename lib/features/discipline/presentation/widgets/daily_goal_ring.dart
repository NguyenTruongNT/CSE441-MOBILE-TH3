import 'package:flutter/material.dart';
import '../../models/discipline_stats.dart';

/// Interactive circular progress card showing today's practice minutes vs daily goal.
class DailyGoalRing extends StatelessWidget {
  const DailyGoalRing({super.key, required this.stats});

  final DisciplineStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = stats.todayRecord;
    final isMet = today.isGoalMet;
    final primaryColor = theme.colorScheme.primary;
    final percent = stats.todayProgressPercent;

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
            // Card Title
            Row(
              children: [
                Icon(
                  Icons.track_changes_rounded,
                  color: primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tiến độ hôm nay',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'Mục tiêu: ${today.goalMinutes}p',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Center Ring & Metrics
            Row(
              children: [
                // Circular Progress Indicator Stack
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: today.progressRatio,
                        strokeWidth: 9,
                        backgroundColor: const Color(0xFFE2EBE8),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isMet ? const Color(0xFF2E7D32) : primaryColor,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$percent%',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isMet
                                    ? const Color(0xFF2E7D32)
                                    : primaryColor,
                              ),
                            ),
                            Text(
                              isMet ? 'Đạt' : 'Tiến độ',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Details Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            today.minutes.toString(),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isMet
                                  ? const Color(0xFF2E7D32)
                                  : primaryColor,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              ' / ${today.goalMinutes} phút',
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Achievement Status Banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isMet
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFF1F5F4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isMet
                              ? '🎉 Đã hoàn thành mục tiêu ngày!'
                              : '⚡ Còn ${today.goalMinutes - today.minutes}p nữa để đạt chỉ tiêu.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isMet
                                ? const Color(0xFF2E7D32)
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
