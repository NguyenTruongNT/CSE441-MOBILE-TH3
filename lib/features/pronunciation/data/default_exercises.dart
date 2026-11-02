import 'package:th3_english_ai/core/contracts/models.dart';
import '../domain/exercise_models.dart';

/// Pre-seeded pronunciation exercises covering major phonetic difficulties
/// encountered by Vietnamese English learners.
class DefaultExercises {
  DefaultExercises._();

  static final List<ExerciseDetail> catalog = [
    ExerciseDetail(
      exercise: const Exercise(
        id: 'ex-01-dental-fricative-unvoiced',
        referenceText: 'I think this method is great',
        referenceIpa: '/aɪ θɪŋk ðɪs ˈmeθəd ɪz ɡreɪt/',
        targetPhonemes: ['θ', 'ð', 'ŋk'],
        sampleAudioUri: null,
      ),
      category: 'Cặp âm dễ nhầm',
      difficulty: 'Trung bình',
      description: 'Luyện âm /θ/ vô thanh (think, method) và /ð/ hữu thanh (this).',
      vietnameseTip:
          'Để đầu lưỡi giữa hai hàm răng, đẩy luồng hơi nhẹ qua kẽ răng. Không thụt lưỡi vào trong để tránh nhầm thành /s/ hay /t/.',
    ),
    ExerciseDetail(
      exercise: const Exercise(
        id: 'ex-02-dental-fricative-voiced',
        referenceText: 'They breathe together in the weather',
        referenceIpa: '/ðeɪ briːð təˈɡeðər ɪn ðə ˈweðər/',
        targetPhonemes: ['ð'],
        sampleAudioUri: null,
      ),
      category: 'Phụ âm khó',
      difficulty: 'Trung bình',
      description: 'Luyện âm /ð/ hữu thanh trong chuỗi câu liên tục.',
      vietnameseTip:
          'Đầu lưỡi chạm nhẹ mép răng cửa trên, rung dây thanh quản khi phát âm /ð/.',
    ),
    ExerciseDetail(
      exercise: const Exercise(
        id: 'ex-03-s-vs-sh',
        referenceText: 'She sells sea shells on the seashore',
        referenceIpa: '/ʃiː selz siː ʃelz ɒn ðə ˈsiːʃɔːr/',
        targetPhonemes: ['ʃ', 's'],
        sampleAudioUri: null,
      ),
      category: 'Cặp âm dễ nhầm',
      difficulty: 'Cơ bản',
      description: 'Phân biệt phụ âm /s/ (răng khép) và /ʃ/ (chu môi cong lưỡi).',
      vietnameseTip:
          'Với /ʃ/ chu môi nhẹ và đưa lưỡi lùi sau vòm miệng; với /s/ khóe môi mở nhẹ, đẩy hơi qua khe hẹp răng cửa.',
    ),
    ExerciseDetail(
      exercise: const Exercise(
        id: 'ex-04-ch-vs-j',
        referenceText: 'Charles chooses a cheap watch',
        referenceIpa: '/tʃɑːrlz ˈtʃuːzɪz ə tʃiːp wɒtʃ/',
        targetPhonemes: ['tʃ'],
        sampleAudioUri: null,
      ),
      category: 'Phụ âm tắc xát',
      difficulty: 'Nâng cao',
      description: 'Luyện âm /tʃ/ vô thanh ở đầu từ và cuối từ.',
      vietnameseTip:
          'Chặn hơi bằng đầu lưỡi tại chân răng cửa trên, rồi bật mạnh ra đồng thời chu môi. Không nhầm thành /tr/ của tiếng Việt.',
    ),
    ExerciseDetail(
      exercise: const Exercise(
        id: 'ex-05-vowel-ship-vs-sheep',
        referenceText: 'The sheep on the ship looks big',
        referenceIpa: '/ðə ʃiːp ɒn ðə ʃɪp lʊks bɪɡ/',
        targetPhonemes: ['iː', 'ɪ'],
        sampleAudioUri: null,
      ),
      category: 'Nguyên âm ngắn và dài',
      difficulty: 'Cơ bản',
      description:
          'Phân biệt nguyên âm dài /iː/ (cười mở mép) và ngắn /ɪ/ (thả lỏng cơ môi).',
      vietnameseTip:
          'Âm /iː/ căng khóe môi sang hai bên; âm /ɪ/ thả lỏng hàm và phát âm nhanh, dứt khoát.',
    ),
    ExerciseDetail(
      exercise: const Exercise(
        id: 'ex-06-ending-clusters',
        referenceText: 'He asked six questions in the test',
        referenceIpa: '/hiː æskt sɪks ˈkwestʃənz ɪn ðə test/',
        targetPhonemes: ['skt', 'ks', 'st'],
        sampleAudioUri: null,
      ),
      category: 'Cụm phụ âm đuôi',
      difficulty: 'Nâng cao',
      description:
          'Luyện nhả đủ các âm đuôi phức /skt/, /ks/, /st/ mà người Việt hay bỏ quên.',
      vietnameseTip:
          'Không bỏ âm cuối. Trong "asked" bật rõ /s/ rồi /t/; trong "six" bật /k/ rồi xì /s/.',
    ),
    ExerciseDetail(
      exercise: const Exercise(
        id: 'ex-07-r-vs-l',
        referenceText: 'The red light turns right very quickly',
        referenceIpa: '/ðə red laɪt tɜːrnz raɪt ˈveri ˈkwɪkli/',
        targetPhonemes: ['r', 'l'],
        sampleAudioUri: null,
      ),
      category: 'Cặp âm dễ nhầm',
      difficulty: 'Trung bình',
      description: 'Phân biệt âm cuộn lưỡi /r/ và âm nâng đầu lưỡi /l/.',
      vietnameseTip:
          'Với /l/ đầu lưỡi chạm vào nướu răng cửa trên; với /r/ lưỡi cong lùi vào sâu khoang miệng và không chạm vòm trên.',
    ),
    ExerciseDetail(
      exercise: const Exercise(
        id: 'ex-08-diphthong-vowels',
        referenceText: 'They go home slowly in the cold snow',
        referenceIpa: '/ðeɪ ɡəʊ həʊm ˈsləʊli ɪn ðə kəʊld snəʊ/',
        targetPhonemes: ['eɪ', 'əʊ'],
        sampleAudioUri: null,
      ),
      category: 'Nguyên âm đôi',
      difficulty: 'Trung bình',
      description: 'Luyện nguyên âm đôi /əʊ/ và /eɪ/ với độ lướt âm mượt mà.',
      vietnameseTip:
          'Khởi đầu từ âm /ə/ lướt nhẹ sang /ʊ/, môi từ từ thu tròn lại ở cuối âm.',
    ),
  ];

  /// Find exercise recommendations targeting specific phonemes that need improvement.
  static List<ImprovementRecommendation> getRecommendations(
    List<PhonemeFeedback> weakPhonemes, {
    String? currentExerciseId,
  }) {
    final recommendations = <ImprovementRecommendation>[];
    final seenPhonemes = <String>{};

    for (final feedback in weakPhonemes) {
      if (feedback.status != PhonemeStatus.needsPractice) continue;
      final target = feedback.expectedIpa;
      if (seenPhonemes.contains(target)) continue;
      seenPhonemes.add(target);

      // Find an exercise that specifically trains this phoneme
      ExerciseDetail? match;
      for (final ex in catalog) {
        if (ex.id != currentExerciseId &&
            ex.targetPhonemes.any((p) => p.contains(target) || target.contains(p))) {
          match = ex;
          break;
        }
      }

      // If no exact target phoneme match, pick any different exercise
      match ??= catalog.firstWhere(
        (ex) => ex.id != currentExerciseId,
        orElse: () => catalog.first,
      );

      recommendations.add(
        ImprovementRecommendation(
          problemPhoneme: target,
          targetWord: feedback.word,
          articulatoryTip: feedback.suggestion,
          suggestedExercise: match,
        ),
      );
    }

    return recommendations;
  }
}
