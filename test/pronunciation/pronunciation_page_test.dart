import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:th3_english_ai/app/app_theme.dart';
import 'package:th3_english_ai/app/app_shell.dart';
import 'package:th3_english_ai/app/shared/page_activity.dart';
import 'package:th3_english_ai/core/contracts/models.dart';
import 'package:th3_english_ai/features/pronunciation/data/audio_sample_fixtures.dart';
import 'package:th3_english_ai/features/pronunciation/data/default_exercises.dart';
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
      theme: AppTheme.light,
      home: Scaffold(
        body: PronunciationPage(
          userRepository: userRepo ?? FakeInternalUserRepository(),
          learningRepository: learningRepo ?? FakeInternalLearningRepository(),
          pronunciationService:
              pronunciationService ??
              FakePronunciationService(simulatedLatency: Duration.zero),
          audioRecorder:
              recorder ??
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

  Future<void> openExercise(WidgetTester tester, {int index = 0}) async {
    final card = find.byKey(
      ValueKey('exercise-${DefaultExercises.catalog[index].id}'),
    );
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
  }

  for (final width in [360.0, 768.0, 1366.0]) {
    testWidgets('practice controls and results fit width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 960);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Bắt đầu ghi âm'), findsNothing);
      await openExercise(tester);
      await tester.ensureVisible(find.text('Bắt đầu ghi âm'));
      await tester.tap(find.text('Bắt đầu ghi âm'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Dừng & Phân tích'));
      await tester.tap(find.text('Dừng & Phân tích'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(OverallScoreBadge), findsOneWidget);
    });
  }

  testWidgets('opens only the catalog before a lesson is selected', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('Chọn bài luyện hôm nay'), findsOneWidget);
    expect(find.text('I think this method is great'), findsOneWidget);
    expect(find.text('/aɪ θɪŋk ðɪs ˈmeθəd ɪz ɡreɪt/'), findsNothing);
    expect(find.text('Bắt đầu ghi âm'), findsNothing);
    expect(find.byKey(const ValueKey('practice-detail')), findsNothing);
  });

  testWidgets(
    'Full practice flow: records, analyzes, shows non-color score and saves session',
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
      await openExercise(tester);

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
              (w.data == 'Rất tốt' ||
                  w.data == 'Khá' ||
                  w.data == 'Cần luyện thêm'),
        ),
        findsAtLeastNWidgets(1),
      );

      // 5. Verify practice was persisted to LearningRepository
      expect(learningRepo.savedSessions.length, 1);
      expect(learningRepo.savedSessions.first.status, PracticeStatus.completed);
      expect(learningRepo.savedResults.length, 1);
      expect(learningRepo.savedResults.first.overallScore, greaterThan(0.0));
    },
  );

  testWidgets('selecting a lesson opens its own studio with a back button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    final secondExerciseText = find.text(
      'They breathe together in the weather',
    );
    expect(secondExerciseText, findsOneWidget);

    await tester.ensureVisible(secondExerciseText);
    await tester.tap(secondExerciseText);
    await tester.pumpAndSettle();

    expect(find.text('/ðeɪ briːð təˈɡeðər ɪn ðə ˈweðər/'), findsOneWidget);
    expect(find.byKey(const ValueKey('exercise-catalog')), findsNothing);
    expect(find.byKey(const ValueKey('back-to-exercises')), findsOneWidget);
    expect(find.text('I think this method is great'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('back-to-exercises')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('exercise-catalog')), findsOneWidget);
    expect(find.text('Bắt đầu ghi âm'), findsNothing);
  });

  testWidgets(
    'DiagnosticLogView is removed from page UI and kept in terminal only',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Verify diagnostic log is not cluttering the user interface
      expect(
        find.textContaining('Nhật ký hệ thống & Chẩn đoán lỗi'),
        findsNothing,
      );
    },
  );

  testWidgets('leaving practice stops microphone and does not save a session', (
    tester,
  ) async {
    final active = ValueNotifier(true);
    final recorder = SimulatedAudioRecorder();
    final repo = FakeInternalLearningRepository();
    addTearDown(active.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: active,
            builder: (context, value, child) =>
                PageActivity(active: value, child: child!),
            child: PronunciationPage(
              audioRecorder: recorder,
              learningRepository: repo,
              pronunciationService: FakePronunciationService(
                simulatedLatency: Duration.zero,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await openExercise(tester);
    await tester.ensureVisible(find.text('Bắt đầu ghi âm'));
    await tester.tap(find.text('Bắt đầu ghi âm'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(recorder.isRecording, isTrue);
    active.value = false;
    await tester.pumpAndSettle();
    expect(recorder.isRecording, isFalse);
    expect(repo.savedSessions, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back preserves search filters and category', (tester) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('exercise-search')),
      'ship',
    );
    await tester.pumpAndSettle();
    expect(find.text('I think this method is great'), findsNothing);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nguyên âm ngắn và dài').last);
    await tester.pumpAndSettle();
    await openExercise(tester, index: 4);
    expect(
      find.text('The sheep on the ship looks big and neat'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('back-to-exercises')));
    await tester.pumpAndSettle();
    final search = tester.widget<TextField>(
      find.byKey(const ValueKey('exercise-search')),
    );
    expect(search.controller!.text, 'ship');
    expect(
      find.byKey(const ValueKey('exercise-category-Nguyên âm ngắn và dài')),
      findsOneWidget,
    );
    expect(find.text('I think this method is great'), findsNothing);
    expect(
      find.text('The sheep on the ship looks big and neat'),
      findsOneWidget,
    );
  });

  testWidgets('clear empty search resets the actual search field', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('exercise-search')),
      'zzzzzzzz',
    );
    await tester.pumpAndSettle();
    expect(find.text('Không có bài luyện phù hợp'), findsOneWidget);
    await tester.ensureVisible(find.text('Xem tất cả bài luyện'));
    await tester.tap(find.text('Xem tất cả bài luyện'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('exercise-search')))
          .controller!
          .text,
      isEmpty,
    );
    expect(find.text('I think this method is great'), findsOneWidget);
  });

  testWidgets('system back returns to catalog and stops an active recording', (
    tester,
  ) async {
    final recorder = SimulatedAudioRecorder();
    final repo = FakeInternalLearningRepository();
    addTearDown(recorder.dispose);
    await tester.pumpWidget(
      buildTestableWidget(recorder: recorder, learningRepo: repo),
    );
    await tester.pumpAndSettle();
    await openExercise(tester);
    await tester.ensureVisible(find.text('Bắt đầu ghi âm'));
    await tester.tap(find.text('Bắt đầu ghi âm'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(recorder.isRecording, isTrue);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(recorder.isRecording, isFalse);
    expect(find.byKey(const ValueKey('exercise-catalog')), findsOneWidget);
    expect(repo.savedSessions, isEmpty);
  });

  testWidgets('catalog scroll position survives opening and closing a lesson', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();
    final card = find.byKey(
      ValueKey('exercise-${DefaultExercises.catalog[8].id}'),
    );
    await tester.ensureVisible(card);
    final controller = tester
        .widget<SingleChildScrollView>(
          find.byKey(const PageStorageKey('exercise-catalog-scroll')),
        )
        .controller!;
    final before = controller.offset;
    expect(before, greaterThan(0));
    await tester.tap(card);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('back-to-exercises')));
    await tester.pumpAndSettle();
    expect(controller.offset, closeTo(before, 1));
  });

  testWidgets('back during analysis does not save a discarded result', (
    tester,
  ) async {
    final repo = FakeInternalLearningRepository();
    await tester.pumpWidget(
      buildTestableWidget(
        learningRepo: repo,
        pronunciationService: FakePronunciationService(
          simulatedLatency: const Duration(seconds: 2),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await openExercise(tester);
    await tester.ensureVisible(find.text('Bắt đầu ghi âm'));
    await tester.tap(find.text('Bắt đầu ghi âm'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(find.text('Dừng & Phân tích'));
    await tester.tap(find.text('Dừng & Phân tích'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('back-to-exercises')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    expect(find.byKey(const ValueKey('exercise-catalog')), findsOneWidget);
    expect(repo.savedSessions, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sidebar remains accessible while a lesson route is open', (
    tester,
  ) async {
    final recorder = SimulatedAudioRecorder();
    addTearDown(recorder.dispose);
    final semantics = tester.ensureSemantics();
    try {
      tester.view.physicalSize = const Size(1366, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AppShell(
            pages: AppPages(
              pronunciation: (_) => PronunciationPage(
                audioRecorder: recorder,
                userRepository: FakeInternalUserRepository(),
                learningRepository: FakeInternalLearningRepository(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-pronunciation')));
      await tester.pumpAndSettle();
      await openExercise(tester);
      final history = find.byKey(const ValueKey('nav-history'));
      expect(tester.getSemantics(history).label, contains('Lịch sử'));
      await tester.tap(history);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('practice-detail')), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}
