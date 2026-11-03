import 'package:flutter/material.dart';

import '../../models/discipline_stats.dart';
import '../../services/discipline_time.dart';

/// Professional greeting banner displaying learner profile, date, and motivational status.
class ProgressHeaderCard extends StatelessWidget {
  const ProgressHeaderCard({
    super.key,
    required this.displayName,
    required this.stats,
  });

  final String displayName;
  final DisciplineStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final greeting = _getGreetingMessage();
    final formattedDate = _formatVietnameseDate(stats.todayRecord.date);
    final badgeLabel = _getDisciplineBadge(stats.currentStreak);

    final initials = displayName.trim().isNotEmpty
        ? displayName
              .trim()
              .split(' ')
              .map((w) => w.isNotEmpty ? w[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : 'HV';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withValues(alpha: 0.08),
            primaryColor.withValues(alpha: 0.02),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar circle with subtle glow
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, const Color(0xFF7954DF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // User details & Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$greeting, $displayName!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Discipline Tier Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFD54F)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.military_tech_rounded,
                            size: 13,
                            color: Color(0xFFF57F17),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            badgeLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: Colors.black45,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      stats.hasPracticedToday
                          ? '• Đã học hôm nay ✨'
                          : '• Chưa học hôm nay',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: stats.hasPracticedToday
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFE65100),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreetingMessage() {
    final hour = profileTime(DateTime.now(), stats.timeZone).hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  String _formatVietnameseDate(DateTime date) {
    final dayStr = date.day.toString().padLeft(2, '0');
    final monthStr = date.month.toString().padLeft(2, '0');
    return '$dayStr/$monthStr/${date.year}';
  }

  String _getDisciplineBadge(int streak) {
    if (streak >= 30) return 'Bậc Thầy';
    if (streak >= 14) return 'Vàng 🌟';
    if (streak >= 7) return 'Bạc 🥈';
    if (streak >= 3) return 'Đồng 🥉';
    return 'Tân Binh 🌱';
  }
}
