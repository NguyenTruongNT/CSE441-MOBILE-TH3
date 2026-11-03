// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

import '../../domain/exercise_models.dart';

/// Card showing pronunciation exercise summary, phonetic IPA text,
/// target phonemes, and difficulty indicator.
class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    super.key,
    required this.exerciseDetail,
    required this.isSelected,
    required this.onTap,
  });

  final ExerciseDetail exerciseDetail;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    Color difficultyColor;
    switch (exerciseDetail.difficulty) {
      case 'Cơ bản':
        difficultyColor = Colors.green;
        break;
      case 'Nâng cao':
        difficultyColor = Colors.deepOrange;
        break;
      case 'Trung bình':
      default:
        difficultyColor = Colors.blue;
        break;
    }

    return Card(
      elevation: isSelected ? 2 : 0,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? primary : theme.colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      color: isSelected ? primary.withOpacity(0.06) : theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            exerciseDetail.category,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: difficultyColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.stairs_rounded,
                                size: 14,
                                color: difficultyColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                exerciseDetail.difficulty,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: difficultyColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check_circle_rounded, color: primary, size: 20),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                exerciseDetail.referenceText,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                exerciseDetail.referenceIpa,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: primary,
                  fontFamily: 'NotoSans',
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: exerciseDetail.targetPhonemes.map((p) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '/$p/',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
