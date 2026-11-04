import 'package:flutter/material.dart';

import '../../../../app/shared/page_activity.dart';
import '../../../../core/contracts/ports.dart';
import '../data/default_exercises.dart';
import '../domain/audio_recorder.dart';
import '../domain/exercise_models.dart';
import 'exercise_catalog_page.dart';
import 'pronunciation_practice_page.dart';

/// Keep the lesson browser mounted while a separate practice route is open.
class PronunciationPage extends StatefulWidget {
  const PronunciationPage({
    super.key,
    this.userRepository,
    this.learningRepository,
    this.pronunciationService,
    this.audioRecorder,
    this.exercises,
  });

  final UserRepository? userRepository;
  final LearningRepository? learningRepository;
  final PronunciationService? pronunciationService;
  final AudioRecorderController? audioRecorder;
  final List<ExerciseDetail>? exercises;

  @override
  State<PronunciationPage> createState() => _PronunciationPageState();
}

class _PronunciationPageState extends State<PronunciationPage> {
  final _navigator = GlobalKey<NavigatorState>();
  bool _active = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _active = PageActivity.isActive(context);
  }

  void _openExercise(ExerciseDetail exercise) {
    _navigator.currentState!.push<void>(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: '/practice/${exercise.id}'),
        builder: (_) => PronunciationPracticePage(
          exercise: exercise,
          userRepository: widget.userRepository,
          learningRepository: widget.learningRepository,
          pronunciationService: widget.pronunciationService,
          audioRecorder: widget.audioRecorder,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => NavigatorPopHandler<void>(
    enabled: _active,
    onPopWithResult: (_) {
      if (_active && _navigator.currentState!.canPop()) {
        _navigator.currentState!.pop();
      }
    },
    child: Semantics(
      container: true,
      explicitChildNodes: true,
      child: Navigator(
        key: _navigator,
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => ExerciseCatalogPage(
            exercises: widget.exercises ?? DefaultExercises.catalog,
            onSelect: _openExercise,
          ),
        ),
      ),
    ),
  );
}
