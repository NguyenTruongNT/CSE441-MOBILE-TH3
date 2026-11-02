import 'package:th3_english_ai/core/contracts/models.dart';

/// Detailed exercise metadata tailored for English pronunciation training.
class ExerciseDetail {
  const ExerciseDetail({
    required this.exercise,
    required this.category,
    required this.difficulty,
    required this.description,
    required this.vietnameseTip,
  });

  final Exercise exercise;
  final String category;
  final String difficulty;
  final String description;
  final String vietnameseTip;

  String get id => exercise.id;
  String get referenceText => exercise.referenceText;
  String get referenceIpa => exercise.referenceIpa;
  List<String> get targetPhonemes => exercise.targetPhonemes;
  Uri? get sampleAudioUri => exercise.sampleAudioUri;

  factory ExerciseDetail.fromJson(Map<String, dynamic> json) {
    final uriStr = json['sampleAudioUri'] as String?;
    final exercise = Exercise(
      id: json['id'] as String,
      referenceText: json['referenceText'] as String,
      referenceIpa: json['referenceIpa'] as String,
      targetPhonemes: List<String>.from(json['targetPhonemes'] as List),
      sampleAudioUri: uriStr != null ? Uri.tryParse(uriStr) : null,
    );
    return ExerciseDetail(
      exercise: exercise,
      category: json['category'] as String? ?? 'Chung',
      difficulty: json['difficulty'] as String? ?? 'Trung bình',
      description: json['description'] as String? ?? '',
      vietnameseTip: json['vietnameseTip'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'difficulty': difficulty,
    'referenceText': referenceText,
    'referenceIpa': referenceIpa,
    'targetPhonemes': targetPhonemes,
    'description': description,
    'sampleAudioUri': sampleAudioUri?.toString(),
    'vietnameseTip': vietnameseTip,
  };
}

/// Follow-up practice recommendation tailored to a specific weak phoneme.
class ImprovementRecommendation {
  const ImprovementRecommendation({
    required this.problemPhoneme,
    required this.targetWord,
    required this.articulatoryTip,
    required this.suggestedExercise,
  });

  final String problemPhoneme;
  final String targetWord;
  final String articulatoryTip;
  final ExerciseDetail suggestedExercise;
}
