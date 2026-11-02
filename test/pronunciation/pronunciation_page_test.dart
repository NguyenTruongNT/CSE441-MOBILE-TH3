import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:th3_english_ai/core/contracts/models.dart';
import 'package:th3_english_ai/features/pronunciation/data/audio_sample_fixtures.dart';
import 'package:th3_english_ai/features/pronunciation/data/fake_pronunciation_repository.dart';
import 'package:th3_english_ai/features/pronunciation/presentation/pronunciation_page.dart';
import 'package:th3_english_ai/features/pronunciation/presentation/widgets/overall_score_badge.dart';
import 'package:th3_english_ai/features/pronunciation/presentation/widgets/phoneme_feedback_table.dart';
import 'package:th3_english_ai/features/pronunciation/services/audio_recorder_service.dart';
import 'package:th3_english_ai/features/pronunciation/services/fake_pronunciation_service.dart';

void main() {
  Widget buildTestableWidget({
    FakeInternalUserRepository? userRepo,
    FakeInternalLearningRepository? learningRepo,
    FakePronunciationService? pronunciationService,
    SimulatedAudioRecorder? recorder,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PronunciationPage(
          userRepository: userRepo ?? FakeInternalUserRepository(),
          learningRepository: learningRepo ?? FakeInternalLearningRepository(),
          pronunciationService: pronunciationService ??
              FakePronunciationService(simulatedLatency: Duration.zero),
          audioRecorder: recorder ??
              SimulatedAudioRecorder(
                simulatedAudioSample: AudioSampleFixtures.createWavSample(
                  durationSeconds: 1.5,
                  volume: 0.5,
                ),
              ),
        ),
      ),
    );
  }

  testWidgets('PronunciationPage renders exercise catalog and focus card', (tester) async {
    tester.view.physicalSize = const Size(1280, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(find.textContaining('Luyện phát âm với AI'), findsOneWidget);
    expect(find.text('I think this method is great'), findsWidgets);
    expect(find.text('/aɪ θɪŋk ðɪs ˈmeθəd ɪz ɡreɪt/'), findsWidgets);
    expect(find.text('Bắt đầu ghi âm'), findsOneWidget);
  });

  testWidgets('Full practice flow: records, analyzes, shows non-color score and saves session',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final learningRepo = FakeInternalLearningRepository();
    final recorder = SimulatedAudioRecorder(
      simulatedAudioSample: AudioSampleFixtures.createWavSample(
        durationSeconds: 1.5,
        volume: 0.5,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(learningRepo: learningRepo, recorder: recorder),
    );
    await tester.pumpAndSettle();

    // 1. Start recording
    await tester.tap(find.text('Bắt đầu ghi âm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Dừng & Phân tích'), findsOneWidget);

    // 2. Stop and analyze
    await tester.tap(find.text('Dừng & Phân tích'));
    await tester.pumpAndSettle();

    // 3. Verify results displayed
    expect(find.byType(OverallScoreBadge), findsOneWidget);
    expect(find.byType(PhonemeFeedbackTable), findsOneWidget);

    // 4. Verify non-color cues (Rating label and icons)
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data == 'Rất tốt' || w.data == 'Khá' || w.data == 'Cần luyện thêm'),
      ),
      findsAtLeastNWidgets(1),
    );

    // 5. Verify practice was persisted to LearningRepository
    expect(learningRepo.savedSessions.length, 1);
    expect(learningRepo.savedSessions.first.status, PracticeStatus.completed);
    expect(learningRepo.savedResults.length, 1);
    expect(learningRepo.savedResults.first.overallScore, greaterThan(0.0));
  });

  testWidgets('Selecting a different exercise updates studio view', (tester) async {
    tester.view.physicalSize = const Size(1280, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    final secondExerciseText = find.text('They breathe together in the weather');
    expect(secondExerciseText, findsOneWidget);

    await tester.ensureVisible(secondExerciseText);
    await tester.tap(secondExerciseText);
    await tester.pumpAndSettle();

    expect(find.text('/ðeɪ briːð təˈɡeðər ɪn ðə ˈweðər/'), findsWidgets);
  });
}
