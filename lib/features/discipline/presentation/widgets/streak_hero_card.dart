import 'package:flutter/material.dart';
import '../../models/discipline_stats.dart';

/// Modern gamified card showcasing streak, milestones, and 7-day continuity chips.
class StreakHeroCard extends StatelessWidget {
  const StreakHeroCard({super.key, required this.stats});

  final DisciplineStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isStreakActive = stats.currentStreak > 0;
    final hasPracticed = stats.hasPracticedToday;

    // Calculate next milestone progress
    final milestoneInfo = _getMilestoneInfo(stats.currentStreak);

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
            // Top Row: Glowing Flame + Streak Count + Status Pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Glowing Fire Badge
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isStreakActive
                          ? [const Color(0xFFFF9800), const Color(0xFFFF5722)]
                          : [Colors.grey.shade300, Colors.grey.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: isStreakActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF5722).withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      isStreakActive ? '🔥' : '❄️',
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Streak Title & Status Pill
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            '${stats.currentStreak} ngày liên tiếp',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: isStreakActive
                                  ? const Color(0xFFD35400)
                                  : Colors.black87,
                            ),
                          ),
                          // Status Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: hasPracticed
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: hasPracticed
                                    ? const Color(0xFF81C784)
                                    : const Color(0xFFFFB74D),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  hasPracticed
                                      ? Icons.check_circle_rounded
                                      : Icons.hourglass_top_rounded,
                                  size: 13,
                                  color: hasPracticed
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFE65100),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  hasPracticed ? 'Đã học' : 'Cần học',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: hasPracticed
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFE65100),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getMotivationMessage(stats),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Milestone Progress Section
            Row(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 16,
                  color: const Color(0xFFE65100),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    milestoneInfo.description,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
                Text(
                  '${(milestoneInfo.progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE65100),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: milestoneInfo.progress,
                minHeight: 7,
                backgroundColor: const Color(0xFFF1F5F4),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFFF9800),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 7-day Mini Continuity Track
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAF9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE4EDE9)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(stats.weeklyRecords.length, (index) {
                  final record = stats.weeklyRecords[index];
                  final isToday = index == stats.weeklyRecords.length - 1;
                  final dayLabel = _formatDayLabel(record.date, isToday);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: record.hasPracticed
                              ? const Color(0xFFFFE0B2)
                              : const Color(0xFFE0E0E0),
                          border: isToday
                              ? Border.all(
                                  color: const Color(0xFFFF5722),
                                  width: 1.5,
                                )
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            record.hasPracticed ? '🔥' : '·',
                            style: TextStyle(
                              fontSize: record.hasPracticed ? 13 : 16,
                              color: record.hasPracticed
                                  ? const Color(0xFFE65100)
                                  : Colors.black38,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dayLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.w500,
                          color: isToday
                              ? const Color(0xFFFF5722)
                              : Colors.black54,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMotivationMessage(DisciplineStats stats) {
    if (stats.currentStreak == 0) {
      return 'Bắt đầu bài luyện hôm nay để kích hoạt chuỗi ngày học tập!';
    }
    if (stats.hasPracticedToday) {
      return 'Tuyệt vời! Bạn đã duy trì ngọn lửa kỷ luật hôm nay. Cứ tiếp tục nhé!';
    }
    return 'Bạn đã có chuỗi ${stats.currentStreak} ngày từ hôm qua. Hãy luyện một bài trước nửa đêm để giữ chuỗi nhé!';
  }

  _MilestoneInfo _getMilestoneInfo(int streak) {
    if (streak < 3) {
      final rem = 3 - streak;
      return _MilestoneInfo(
        description: 'Còn $rem ngày nữa để đạt mốc Đồng 🥉 (3 ngày)',
        progress: (streak / 3).clamp(0.0, 1.0),
      );
    } else if (streak < 7) {
      final rem = 7 - streak;
      return _MilestoneInfo(
        description: 'Còn $rem ngày nữa để đạt mốc Bạc 🥈 (7 ngày)',
        progress: ((streak - 3) / (7 - 3)).clamp(0.0, 1.0),
      );
    } else if (streak < 14) {
      final rem = 14 - streak;
      return _MilestoneInfo(
        description: 'Còn $rem ngày nữa để đạt mốc Vàng 🌟 (14 ngày)',
        progress: ((streak - 7) / (14 - 7)).clamp(0.0, 1.0),
      );
    } else if (streak < 30) {
      final rem = 30 - streak;
      return _MilestoneInfo(
        description: 'Còn $rem ngày nữa để đạt Kim Cương 💎 (30 ngày)',
        progress: ((streak - 14) / (30 - 14)).clamp(0.0, 1.0),
      );
    } else {
      return const _MilestoneInfo(
        description: 'Đã mở khóa mốc Huyền Thoại 👑 (30+ ngày)',
        progress: 1.0,
      );
    }
  }

  String _formatDayLabel(DateTime date, bool isToday) {
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

class _MilestoneInfo {
  const _MilestoneInfo({required this.description, required this.progress});
  final String description;
  final double progress;
}
