import 'package:flutter/material.dart';
import '../../models/discipline_stats.dart';

/// Interactive circular progress card showing today's practice minutes vs daily goal with a 3-metric breakdown.
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

    final stageInfo = _getStageInfo(today.minutes, today.goalMinutes);
    final overMinutes = today.minutes > today.goalMinutes ? today.minutes - today.goalMinutes : 0;
    final remainingMinutes = today.goalMinutes > today.minutes ? today.goalMinutes - today.minutes : 0;

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
            // Card Title + Goal Label
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
                // Keep 'Mục tiêu: Xp' for test finders
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
                        backgroundColor: const Color(0xFFE8E5F7),
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

                // Details Text + Stage Pill
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
                      const SizedBox(height: 6),
                      // Stage Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: stageInfo.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: stageInfo.color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          stageInfo.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: stageInfo.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // 3-Metric Breakdown Row
            Row(
              children: [
                _buildSubMetric(
                  label: 'Đã luyện',
                  value: '${today.minutes}p',
                  icon: Icons.timer_outlined,
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                _buildSubMetric(
                  label: 'Còn lại',
                  value: isMet ? '0p' : '${remainingMinutes}p',
                  icon: Icons.hourglass_empty_rounded,
                  color: isMet ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                ),
                const SizedBox(width: 8),
                _buildSubMetric(
                  label: 'Vượt mốc',
                  value: overMinutes > 0 ? '+$overMinutes p' : '—',
                  icon: Icons.auto_awesome_rounded,
                  color: overMinutes > 0 ? const Color(0xFF1B8A5A) : Colors.black38,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Achievement Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMet ? const Color(0xFFE8F5E9) : const Color(0xFFF4F3FC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    isMet ? Icons.verified_rounded : Icons.bolt_rounded,
                    size: 16,
                    color: isMet ? const Color(0xFF2E7D32) : primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isMet
                          ? 'Đã hoàn thành mục tiêu ngày! (${today.minutes}/${today.goalMinutes}p)'
                          : 'Còn ${today.goalMinutes - today.minutes}p nữa để đạt chỉ tiêu hôm nay.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isMet ? const Color(0xFF2E7D32) : Colors.black87,
                      ),
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

  Widget _buildSubMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8FD),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE6E4F2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StageInfo _getStageInfo(int minutes, int goal) {
    if (goal <= 0) {
      return const _StageInfo(label: 'Tự do', color: Colors.blueGrey);
    }
    final ratio = minutes / goal;
    if (ratio >= 1.0) {
      return const _StageInfo(
        label: 'Đạt mục tiêu',
        color: Color(0xFF1B8A5A),
      );
    }
    if (ratio >= 0.75) {
      return const _StageInfo(
        label: 'Về đích',
        color: Color(0xFF00897B),
      );
    }
    if (ratio >= 0.4) {
      return const _StageInfo(
        label: 'Tăng tốc',
        color: Color(0xFFF57C00),
      );
    }
    return const _StageInfo(
      label: 'Khởi động',
      color: Color(0xFF757575),
    );
  }
}

class _StageInfo {
  const _StageInfo({required this.label, required this.color});
  final String label;
  final Color color;
}
