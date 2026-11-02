import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:th3_english_ai/core/contracts/contracts.dart';
import 'package:th3_english_ai/features/user_data/data/persistent_learning_repository.dart';
import 'package:th3_english_ai/features/user_data/data/persistent_user_repository.dart';
import 'package:th3_english_ai/features/user_data/data/user_data_store.dart';
import 'package:th3_english_ai/features/user_data/presentation/history_page.dart';

void main() {
  late MemoryUserDataStore store;
  late PersistentUserRepository userRepository;
  late PersistentLearningRepository learningRepository;

  setUp(() {
    store = MemoryUserDataStore();

    userRepository = PersistentUserRepository(store: store);

    learningRepository = PersistentLearningRepository(store: store);
  });

  Future<void> createProfile({
    required String id,
    required String displayName,
    bool selected = false,
  }) async {
    await userRepository.saveProfile(
      UserProfile(
        id: id,
        displayName: displayName,
        createdAt: DateTime.utc(2026, 11, 1),
      ),
    );

    if (selected) {
      await userRepository.selectProfile(id);
    }
  }

  Future<void> saveCompletedPractice({
    required String sessionId,
    required String resultId,
    required String userId,
    required String exerciseId,
    required DateTime startedAt,
    required double score,
  }) async {
    final PracticeSession session = PracticeSession(
      id: sessionId,
      userId: userId,
      exerciseId: exerciseId,
      startedAt: startedAt,
      endedAt: startedAt.add(const Duration(minutes: 3)),
      durationSeconds: 180,
      status: PracticeStatus.completed,
    );

    final PronunciationResult result = PronunciationResult(
      id: resultId,
      sessionId: sessionId,
      referenceText: 'Hello world',
      recognizedText: 'Hello world',
      overallScore: score,
      provider: 'fake-provider',
      modelVersion: 'fake-v1',
      analyzedAt: startedAt.add(const Duration(minutes: 4)),
      phonemes: <PhonemeFeedback>[
        PhonemeFeedback(
          word: 'Hello',
          expectedIpa: 'həˈloʊ',
          recognizedIpa: 'həˈloʊ',
          score: score,
          status: PhonemeStatus.correct,
          suggestion: 'Phát âm tốt.',
        ),
      ],
    );

    await learningRepository.savePractice(session: session, result: result);
  }

  Future<void> pumpHistoryPage(
    WidgetTester tester, {
    Size size = const Size(400, 800),
  }) async {
    await tester.binding.setSurfaceSize(size);

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryPage(
            userRepository: userRepository,
            learningRepository: learningRepository,
            clock: () => DateTime.utc(2026, 11, 3),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('yêu cầu chọn hồ sơ khi chưa chọn', (WidgetTester tester) async {
    await pumpHistoryPage(tester);

    expect(find.text('Chưa chọn hồ sơ'), findsOneWidget);

    expect(find.textContaining('Hãy tạo hoặc chọn một hồ sơ'), findsOneWidget);
  });

  testWidgets('hiển thị trạng thái lịch sử rỗng', (WidgetTester tester) async {
    await createProfile(
      id: 'user-a',
      displayName: 'Người dùng A',
      selected: true,
    );

    await pumpHistoryPage(tester);

    expect(find.text('Lịch sử luyện tập'), findsOneWidget);

    expect(find.text('Chưa có phiên luyện tập'), findsOneWidget);

    expect(find.textContaining('Người dùng A'), findsOneWidget);
  });

  testWidgets('chỉ hiển thị lịch sử của hồ sơ đang chọn', (
    WidgetTester tester,
  ) async {
    await createProfile(
      id: 'user-a',
      displayName: 'Người dùng A',
      selected: true,
    );

    await createProfile(id: 'user-b', displayName: 'Người dùng B');

    await saveCompletedPractice(
      sessionId: 'session-a',
      resultId: 'result-a',
      userId: 'user-a',
      exerciseId: 'exercise-user-a',
      startedAt: DateTime.utc(2026, 11, 1, 8),
      score: 91,
    );

    await saveCompletedPractice(
      sessionId: 'session-b',
      resultId: 'result-b',
      userId: 'user-b',
      exerciseId: 'exercise-user-b',
      startedAt: DateTime.utc(2026, 11, 2, 8),
      score: 82,
    );

    await pumpHistoryPage(tester);

    expect(find.text('exercise-user-a'), findsOneWidget);

    expect(find.text('exercise-user-b'), findsNothing);

    // Kiểm tra chính xác điểm của phiên,
    // tránh bắt cả thẻ điểm trung bình.
    expect(find.text('Điểm: 91.0'), findsOneWidget);
  });

  testWidgets('hiển thị phiên mới nhất trước', (WidgetTester tester) async {
    await createProfile(
      id: 'user-a',
      displayName: 'Người dùng A',
      selected: true,
    );

    await saveCompletedPractice(
      sessionId: 'session-old',
      resultId: 'result-old',
      userId: 'user-a',
      exerciseId: 'exercise-old',
      startedAt: DateTime.utc(2026, 11, 1, 8),
      score: 80,
    );

    await saveCompletedPractice(
      sessionId: 'session-new',
      resultId: 'result-new',
      userId: 'user-a',
      exerciseId: 'exercise-new',
      startedAt: DateTime.utc(2026, 11, 2, 8),
      score: 90,
    );

    await pumpHistoryPage(tester);

    final Finder newSessionFinder = find.text('exercise-new');

    final Finder oldSessionFinder = find.text('exercise-old');

    expect(newSessionFinder, findsOneWidget);

    expect(oldSessionFinder, findsOneWidget);

    final Offset newPosition = tester.getTopLeft(newSessionFinder);

    final Offset oldPosition = tester.getTopLeft(oldSessionFinder);

    expect(newPosition.dy, lessThan(oldPosition.dy));
  });

  testWidgets('mở trang chi tiết kết quả', (WidgetTester tester) async {
    await createProfile(
      id: 'user-a',
      displayName: 'Người dùng A',
      selected: true,
    );

    await saveCompletedPractice(
      sessionId: 'session-a',
      resultId: 'result-a',
      userId: 'user-a',
      exerciseId: 'exercise-hello',
      startedAt: DateTime.utc(2026, 11, 2, 8),
      score: 92,
    );

    await pumpHistoryPage(tester);

    final Finder detailButton = find.byKey(
      const ValueKey('open-result-session-a'),
    );

    expect(detailButton, findsOneWidget);

    // Nút nằm phía dưới vùng nhìn ban đầu.
    // Cuộn đến nút trước khi thực hiện thao tác.
    await tester.ensureVisible(detailButton);
    await tester.pumpAndSettle();

    await tester.tap(detailButton);
    await tester.pumpAndSettle();

    expect(find.text('Chi tiết kết quả'), findsOneWidget);

    expect(find.text('Điểm phát âm'), findsOneWidget);

    expect(find.text('92'), findsOneWidget);
  });

  testWidgets('không tràn ở kích thước mobile', (WidgetTester tester) async {
    await createProfile(
      id: 'user-a',
      displayName: 'Người dùng A',
      selected: true,
    );

    await saveCompletedPractice(
      sessionId: 'session-a',
      resultId: 'result-a',
      userId: 'user-a',
      exerciseId: 'exercise-hello',
      startedAt: DateTime.utc(2026, 11, 2, 8),
      score: 92,
    );

    await pumpHistoryPage(tester, size: const Size(360, 800));

    expect(tester.takeException(), isNull);

    expect(find.text('Lịch sử luyện tập'), findsOneWidget);
  });

  testWidgets('không tràn ở kích thước desktop', (WidgetTester tester) async {
    await createProfile(
      id: 'user-a',
      displayName: 'Người dùng A',
      selected: true,
    );

    await saveCompletedPractice(
      sessionId: 'session-a',
      resultId: 'result-a',
      userId: 'user-a',
      exerciseId: 'exercise-hello',
      startedAt: DateTime.utc(2026, 11, 2, 8),
      score: 92,
    );

    await pumpHistoryPage(tester, size: const Size(1366, 768));

    expect(tester.takeException(), isNull);

    expect(find.text('Lịch sử luyện tập'), findsOneWidget);
  });
}
