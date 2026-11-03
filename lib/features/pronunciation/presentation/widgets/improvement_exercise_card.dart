// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../domain/exercise_models.dart';

/// Card presenting a follow-up recommendation tailored to a weak phoneme.
class ImprovementExerciseCard extends StatelessWidget {
  const ImprovementExerciseCard({
    super.key,
    required this.recommendation,
    required this.onStartPractice,
  });

  final ImprovementRecommendation recommendation;
  final VoidCallback onStartPractice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetEx = recommendation.suggestedExercise;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.35),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Âm cần khắc phục: /${recommendation.problemPhoneme}/',
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              if (recommendation.targetWord.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Từ: "${recommendation.targetWord}"',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  targetEx.difficulty,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Articulatory tip for the weak phoneme
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.6),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 18,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chỉnh khẩu hình âm /${recommendation.problemPhoneme}/:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        recommendation.articulatoryTip,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Suggested Drill Exercise
          Text(
            'Bài luyện đề xuất: ${targetEx.referenceText}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            targetEx.referenceIpa,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.primary,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            targetEx.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: onStartPractice,
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Luyện ngay bài tập này'),
            ),
          ),
        ],
      ),
    );
  }
}
