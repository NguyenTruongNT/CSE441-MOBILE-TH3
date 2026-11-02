// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

/// Accessible score display with both color and clear non-color semantic cues
/// (distinct icons, descriptive text ratings, and progress metrics).
class OverallScoreBadge extends StatelessWidget {
  const OverallScoreBadge({
    super.key,
    required this.score,
    this.size = 130,
  });

  final double score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color ringColor;
    final Color backgroundColor;
    final IconData statusIcon;
    final String statusLabel;
    final String description;

    if (score >= 80.0) {
      ringColor = const Color(0xFF1B873F);
      backgroundColor = const Color(0xFFE8F5E9);
      statusIcon = Icons.check_circle_rounded;
      statusLabel = 'Rất tốt';
      description = 'Phát âm tự nhiên và chuẩn xác';
    } else if (score >= 60.0) {
      ringColor = const Color(0xFFD97706);
      backgroundColor = const Color(0xFFFEF3C7);
      statusIcon = Icons.warning_amber_rounded;
      statusLabel = 'Khá';
      description = 'Dễ hiểu, cần hoàn thiện một số âm vị';
    } else {
      ringColor = const Color(0xFFDC2626);
      backgroundColor = const Color(0xFFFEE2E2);
      statusIcon = Icons.error_outline_rounded;
      statusLabel = 'Cần luyện thêm';
      description = 'Cần tập trung chỉnh khẩu hình và luồng hơi';
    }

    return Semantics(
      label: 'Điểm tổng thể: ${score.toInt()} trên 100. Đánh giá: $statusLabel.',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ringColor.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular progress indicator with score inside
            SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: (score / 100.0).clamp(0.0, 1.0),
                      strokeWidth: 8,
                      backgroundColor: ringColor.withOpacity(0.18),
                      valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        score.toStringAsFixed(0),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: ringColor,
                          fontSize: 34,
                        ),
                      ),
                      Text(
                        '/ 100',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Textual & icon cues ensuring non-color accessibility
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(statusIcon, color: ringColor, size: 22),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ringColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _CueChip(
                        icon: Icons.speed_rounded,
                        label: 'GOP: ${(score * 0.95).toStringAsFixed(0)}%',
                      ),
                      const _CueChip(
                        icon: Icons.graphic_eq_rounded,
                        label: 'Độ khớp âm vị',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CueChip extends StatelessWidget {
  const _CueChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
