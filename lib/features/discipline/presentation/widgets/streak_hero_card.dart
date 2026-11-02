import 'package:flutter/material.dart';
import '../../models/discipline_stats.dart';

/// Modern card showcasing the user's active streak with motivational status.
class StreakHeroCard extends StatelessWidget {
  const StreakHeroCard({super.key, required this.stats});

  final DisciplineStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isStreakActive = stats.currentStreak > 0;
    final hasPracticed = stats.hasPracticedToday;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Glowing Fire / Streak Badge
            Container(
              width: 60,
              height: 60,
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
            const SizedBox(width: 16),
            // Streak details & motivation
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
                  const SizedBox(height: 6),
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
}
