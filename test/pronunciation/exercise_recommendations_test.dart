import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:th3_english_ai/core/contracts/models.dart';
import 'package:th3_english_ai/features/pronunciation/data/default_exercises.dart';
import 'package:th3_english_ai/features/pronunciation/domain/ipa_symbols.dart';
import 'package:th3_english_ai/features/pronunciation/presentation/widgets/phoneme_feedback_table.dart';
import 'package:th3_english_ai/features/user_data/presentation/practice_result_detail_page.dart';

PhonemeFeedback weak(
  String target, {
  PhonemeStatus status = PhonemeStatus.needsPractice,
}) => PhonemeFeedback(
  word: 'sample',
  expectedIpa: target,
  recognizedIpa: 's',
  status: status,
  score: status == PhonemeStatus.notAssessed ? null : 0,
  suggestion: 'Nghe lại và luyện chậm từng âm.',
);

void main() {
  test(
    'missing dedicated h drill uses a sentence that actually contains h',
    () {
      final recommendations = DefaultExercises.getRecommendations([
        weak('h'),
      ], currentExerciseId: DefaultExercises.catalog.first.id);
      expect(recommendations, hasLength(1));
      expect(
        recommendations.single.suggestedExercise.referenceText,
        'He asked six questions in the test',
      );
    },
  );

  test(
    'extra sound and unsupported target never suggest an unrelated lesson',
    () {
      for (final target in ['∅', ' ∅ ', '?', '', ' ']) {
        expect(
          DefaultExercises.getRecommendations([weak(target)]),
          isEmpty,
          reason: 'No unrelated drill for $target',
        );
      }
    },
  );

  test(
    'IPA units distinguish short vowels and fricatives from larger units',
    () {
      expect(IpaSymbols.containsSequence('/ðeɪ/', 'ɪ'), isFalse);
      expect(IpaSymbols.containsSequence('/tʃuːz/', 'ʃ'), isFalse);
      expect(IpaSymbols.containsSequence('/iː/', 'i'), isFalse);
      expect(IpaSymbols.containsSequence('/ʃɪp/', 'ɪ'), isTrue);
    },
  );

  test('clusters cannot be assembled across word boundaries', () {
    expect(IpaSymbols.containsSequence('/æsk tiː/', 'skt'), isFalse);
    expect(IpaSymbols.containsSequence('/æskt/', 'skt'), isTrue);
  });

  test('notation aliases match without confusing different phonemes', () {
    expect(IpaSymbols.containsSequence('/ˈrəʊd/', 'ɹ'), isTrue);
    expect(IpaSymbols.containsSequence('/həʊm/', 'oʊ'), isTrue);
    expect(IpaSymbols.containsSequence('/met/', 'ɛ'), isTrue);
    expect(IpaSymbols.containsSequence('/bɜːrd/', 'ɝ'), isTrue);
    expect(IpaSymbols.containsSequence('/aɪ/', 'ɪ'), isFalse);
  });

  test(
    'a sole relevant lesson is repeated rather than replaced arbitrarily',
    () {
      const id = 'ex-06-ending-clusters';
      final recommendations = DefaultExercises.getRecommendations([
        weak('skt'),
      ], currentExerciseId: id);
      expect(recommendations.single.suggestedExercise.id, id);
    },
  );

  test(
    'correct or uncertain observations are not treated as pronunciation errors',
    () {
      final recommendations = DefaultExercises.getRecommendations([
        weak('θ', status: PhonemeStatus.correct),
        weak('s', status: PhonemeStatus.notAssessed),
      ]);
      expect(recommendations, isEmpty);
    },
  );

  test('recommendations deduplicate aliases and lessons, and cap the list at three', () {
    final recommendations = DefaultExercises.getRecommendations([
      weak('r'),
      weak('ɹ'),
      weak('θ'),
      weak('s'),
      weak('æ'),
    ]);
    expect(recommendations, hasLength(3));
    expect(
      recommendations.map((r) => r.suggestedExercise.id).toSet(),
      hasLength(3),
    );
    expect(recommendations.where((r) => r.problemPhoneme == 'ɹ'), isEmpty);
  });

  testWidgets(
    'practice feedback describes insertion instead of a phoneme named empty set',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PhonemeFeedbackTable(phonemes: [weak('∅')])),
        ),
      );
      expect(find.text('Âm thừa'), findsOneWidget);
      expect(find.text('Âm nhận thêm: /s/'), findsOneWidget);
      expect(find.text('/∅/'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('saved history keeps the meaning of inserted sounds', (
    tester,
  ) async {
    final started = DateTime.utc(2026, 11, 4);
    await tester.pumpWidget(
      MaterialApp(
        home: PracticeResultDetailPage(
          session: PracticeSession(
            id: 'session',
            userId: 'user',
            exerciseId: 'exercise',
            startedAt: started,
            endedAt: started.add(const Duration(seconds: 3)),
            durationSeconds: 3,
            status: PracticeStatus.completed,
          ),
          result: PronunciationResult(
            id: 'result',
            sessionId: 'session',
            referenceText: 'Think',
            recognizedText: 'Think a',
            overallScore: 75,
            provider: 'test',
            modelVersion: 'test',
            analyzedAt: started,
            phonemes: [weak('∅')],
          ),
        ),
      ),
    );
    expect(find.text('Âm thừa'), findsOneWidget);
    expect(find.text('Không có âm tương ứng trong mẫu'), findsOneWidget);
    expect(find.text('∅'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
