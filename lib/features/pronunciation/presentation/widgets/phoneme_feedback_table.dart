// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:th3_english_ai/core/contracts/models.dart';

/// Interactive table displaying phoneme-by-phoneme diagnostic details,
/// target vs recognized IPA, timestamps, scores, and articulatory suggestions.
class PhonemeFeedbackTable extends StatelessWidget {
  const PhonemeFeedbackTable({
    super.key,
    required this.phonemes,
  });

  final List<PhonemeFeedback> phonemes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (phonemes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Không có dữ liệu âm vị để hiển thị.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Chi tiết phân tích âm vị',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${phonemes.length} âm vị phân tích',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < phonemes.length; i++)
          _PhonemeCard(feedback: phonemes[i], index: i + 1),
      ],
    );
  }
}

class _PhonemeCard extends StatelessWidget {
  const _PhonemeCard({required this.feedback, required this.index});

  final PhonemeFeedback feedback;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color statusColor;
    final IconData statusIcon;
    final String statusLabel;

    switch (feedback.status) {
      case PhonemeStatus.correct:
        statusColor = const Color(0xFF1B873F);
        statusIcon = Icons.check_circle_outline_rounded;
        statusLabel = 'Chuẩn';
        break;
      case PhonemeStatus.needsPractice:
        statusColor = const Color(0xFFD97706);
        statusIcon = Icons.warning_amber_rounded;
        statusLabel = 'Cần luyện';
        break;
      case PhonemeStatus.notAssessed:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline_rounded;
        statusLabel = 'Chưa xác định';
        break;
    }

    final hasTimestamps = feedback.startMilliseconds != null &&
        feedback.endMilliseconds != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.04),
        border: Border.all(color: statusColor.withOpacity(0.25), width: 1.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Word tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  feedback.word,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Expected IPA
              Text(
                '/${feedback.expectedIpa}/',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                  color: theme.colorScheme.primary,
                ),
              ),
              if (feedback.recognizedIpa != null &&
                  feedback.recognizedIpa != feedback.expectedIpa) ...[
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '[${feedback.recognizedIpa}]',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
              const Spacer(),
              // Status Badge with icon + text
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Articulatory suggestion
          if (feedback.suggestion.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    feedback.suggestion,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (hasTimestamps || feedback.score != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (hasTimestamps)
                  Text(
                    'Đoạn âm: ${feedback.startMilliseconds}ms – ${feedback.endMilliseconds}ms',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                const Spacer(),
                if (feedback.score != null)
                  Text(
                    'Điểm: ${feedback.score!.toStringAsFixed(0)}/100',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
