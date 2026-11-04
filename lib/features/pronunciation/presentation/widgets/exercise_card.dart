import 'package:flutter/material.dart';

import '../../domain/exercise_models.dart';

/// A lesson preview that opens the dedicated practice screen.
class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    super.key,
    required this.exerciseDetail,
    required this.onTap,
  });

  final ExerciseDetail exerciseDetail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Semantics(
      button: true,
      label: 'Mở bài luyện: ${exerciseDetail.referenceText}',
      onTap: onTap,
      excludeSemantics: true,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          excludeFromSemantics: true,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        exerciseDetail.category,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: primary,
                        ),
                      ),
                    ),
                    Text(
                      exerciseDetail.difficulty,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  exerciseDetail.referenceText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  exerciseDetail.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final phone in exerciseDetail.targetPhonemes)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F3FB),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          '/$phone/',
                          style: TextStyle(
                            fontFamily: 'NotoSans',
                            color: primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  children: [
                    Icon(Icons.mic_none_rounded, size: 19, color: primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bắt đầu luyện',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: primary,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, size: 20, color: primary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
