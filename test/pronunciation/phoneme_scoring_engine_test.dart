import 'package:flutter_test/flutter_test.dart';
import 'package:th3_english_ai/core/contracts/models.dart';
import 'package:th3_english_ai/features/pronunciation/data/audio_sample_fixtures.dart';
import 'package:th3_english_ai/features/pronunciation/data/default_exercises.dart';
import 'package:th3_english_ai/features/pronunciation/domain/phoneme_scoring_engine.dart';

void main() {
  const engine = PhonemeScoringEngine();

  test('PhonemeScoringEngine produces valid PronunciationResult with normalized scores', () {
    final exercise = DefaultExercises.catalog.first.exercise;
    final audio = AudioSampleFixtures.createWavSample(
      durationSeconds: 2.0,
      frequencyHz: 320.0,
      volume: 0.5,
    );

    final result = engine.evaluate(
      sessionId: 'test-session-1',
      audio: audio,
      exercise: exercise,
    );

    expect(result.id, 'res-test-session-1');
    expect(result.sessionId, 'test-session-1');
    expect(result.overallScore, inInclusiveRange(0.0, 100.0));
    expect(result.overallScore.isFinite, isTrue);
    expect(result.phonemes, isNotEmpty);

    for (final p in result.phonemes) {
      expect(p.word, isNotEmpty);
      expect(p.expectedIpa, isNotEmpty);
      expect(p.suggestion, isNotEmpty);
      if (p.score != null) {
        expect(p.score!, inInclusiveRange(0.0, 100.0));
      }
      if (p.startMilliseconds != null && p.endMilliseconds != null) {
        expect(p.startMilliseconds!, greaterThanOrEqualTo(0));
        expect(p.endMilliseconds!, greaterThanOrEqualTo(p.startMilliseconds!));
      }
    }
  });

  test('Phoneme recommendations identify weak phonemes correctly', () {
    final weakList = [
      PhonemeFeedback(
        word: 'think',
        expectedIpa: 'θ',
        status: PhonemeStatus.needsPractice,
        suggestion: 'Luyện âm /θ/',
        score: 55.0,
      ),
      PhonemeFeedback(
        word: 'method',
        expectedIpa: 'θ',
        status: PhonemeStatus.needsPractice,
        suggestion: 'Luyện âm /θ/',
        score: 58.0,
      ),
    ];

    final recs = DefaultExercises.getRecommendations(weakList);
    expect(recs, isNotEmpty);
    expect(recs.first.problemPhoneme, 'θ');
    expect(recs.first.suggestedExercise.referenceText, isNotEmpty);
  });
}

