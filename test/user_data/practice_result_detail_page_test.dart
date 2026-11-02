import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:th3_english_ai/core/contracts/contracts.dart';
import 'package:th3_english_ai/features/user_data/presentation/practice_result_detail_page.dart';

void main() {
  PracticeSession createSession() {
    return PracticeSession(
      id: 'session-001',
      userId: 'user-khanh',
      exerciseId: 'exercise-hello',
      startedAt: DateTime.utc(2026, 11, 2, 8),
      endedAt: DateTime.utc(2026, 11, 2, 8, 3),
      durationSeconds: 180,
      status: PracticeStatus.completed,
    );
  }

  PronunciationResult createResult() {
    return PronunciationResult(
      id: 'result-001',
      sessionId: 'session-001',
      referenceText: 'Hello world',
      recognizedText: 'Hello word',
      overallScore: 82.5,
      provider: 'fake-provider',
      modelVersion: 'fake-v1',
      analyzedAt: DateTime.utc(2026, 11, 2, 8, 4),
      phonemes: <PhonemeFeedback>[
        PhonemeFeedback(
          word: 'Hello',
          expectedIpa: 'həˈloʊ',
          recognizedIpa: 'həˈloʊ',
          score: 95,
          status: PhonemeStatus.correct,
          startMilliseconds: 0,
          endMilliseconds: 600,
          suggestion: 'Phát âm rõ và ổn định.',
        ),
        PhonemeFeedback(
          word: 'world',
          expectedIpa: 'wɜːrld',
          recognizedIpa: 'wɜːd',
          score: 70,
          status: PhonemeStatus.needsPractice,
          startMilliseconds: 700,
          endMilliseconds: 1300,
          suggestion: 'Chú ý âm cuối /ld/.',
        ),
        PhonemeFeedback(
          word: 'sample',
          expectedIpa: 'ˈsæmpəl',
          status: PhonemeStatus.notAssessed,
          suggestion: 'Không đủ bằng chứng để đánh giá.',
        ),
      ],
    );
  }

  Future<void> pumpDetailPage(
    WidgetTester tester, {
    Size size = const Size(400, 800),
  }) async {
    await tester.binding.setSurfaceSize(size);

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: PracticeResultDetailPage(
          session: createSession(),
          result: createResult(),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('hiển thị điểm và transcript', (WidgetTester tester) async {
    await pumpDetailPage(tester);

    expect(find.text('Chi tiết kết quả'), findsOneWidget);

    expect(find.text('83'), findsOneWidget);

    expect(find.text('Hello world'), findsOneWidget);

    expect(find.text('Hello word'), findsOneWidget);

    expect(find.textContaining('fake-provider'), findsOneWidget);

    expect(find.textContaining('fake-v1'), findsOneWidget);
  });

  testWidgets('hiển thị đầy đủ phản hồi âm vị', (WidgetTester tester) async {
    await pumpDetailPage(tester);

    expect(find.text('Hello'), findsOneWidget);

    expect(find.text('world'), findsOneWidget);

    expect(find.text('sample'), findsOneWidget);

    expect(find.text('Đúng'), findsOneWidget);

    expect(find.text('Cần luyện thêm'), findsOneWidget);

    // Một dòng là trạng thái âm vị.
    // Một dòng là điểm chưa được đánh giá.
    expect(find.text('Chưa đánh giá'), findsNWidgets(2));

    expect(find.text('Chú ý âm cuối /ld/.'), findsOneWidget);

    expect(find.text('Không đủ bằng chứng để đánh giá.'), findsOneWidget);
  });

  testWidgets('trạng thái âm vị không chỉ thể hiện bằng màu', (
    WidgetTester tester,
  ) async {
    await pumpDetailPage(tester);

    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);

    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);

    expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);

    expect(find.text('Đúng'), findsOneWidget);

    expect(find.text('Cần luyện thêm'), findsOneWidget);

    // Trạng thái và giá trị điểm đều hiển thị
    // "Chưa đánh giá".
    expect(find.text('Chưa đánh giá'), findsNWidgets(2));
  });

  testWidgets('không tràn ở kích thước mobile', (WidgetTester tester) async {
    await pumpDetailPage(tester, size: const Size(360, 800));

    expect(tester.takeException(), isNull);

    expect(find.text('Điểm phát âm'), findsOneWidget);
  });

  testWidgets('không tràn ở kích thước desktop', (WidgetTester tester) async {
    await pumpDetailPage(tester, size: const Size(1366, 768));

    expect(tester.takeException(), isNull);

    expect(find.text('Điểm phát âm'), findsOneWidget);
  });
}
