import 'package:th3_english_ai/core/contracts/models.dart';

import '../domain/exercise_models.dart';
import '../domain/ipa_symbols.dart';

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
      description:
          'Luyện âm /θ/ vô thanh (think, method) và /ð/ hữu thanh (this).',
      vietnameseTip: 'Để đầu lưỡi giữa hai hàm răng, đẩy luồng hơi nhẹ qua kẽ răng. Không thụt lưỡi vào trong để tránh nhầm thành /s/ hay /t/.',
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
      vietnameseTip: 'Đầu lưỡi chạm nhẹ mép răng cửa trên, rung dây thanh quản khi phát âm /ð/.',
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
      description:
          'Phân biệt phụ âm /s/ (răng khép) và /ʃ/ (chu môi cong lưỡi).',
      vietnameseTip: 'Với /ʃ/ chu môi nhẹ và đưa lưỡi lùi sau vòm miệng; với /s/ khóe môi mở nhẹ, đẩy hơi qua khe hẹp răng cửa.',
    ),
    ExerciseDetail(
      exercise: const Exercise(
        id: 'ex-04-ch-vs-j',
        referenceText: 'Charles chooses a cheap watch while John rejoices',
        referenceIpa: '/tʃɑːrlz ˈtʃuːzɪz ə tʃiːp wɒtʃ waɪl dʒɒn rɪˈdʒɔɪsɪz/',
        targetPhonemes: ['tʃ', 'dʒ'],
        sampleAudioUri: null,
      ),
      category: 'Phụ âm tắc xát',
      difficulty: 'Nâng cao',
      description:
          'Phân biệt âm /tʃ/ vô thanh và /dʒ/ hữu thanh ở đầu và cuối từ.',
      vietnameseTip: 'Chặn hơi bằng đầu lưỡi tại nướu răng trên rồi bật mạnh ra đồng thời chu môi. Rung thanh quản với /dʒ/, không rung với /tʃ/.',
    ),
    ExerciseDetail(
      exercise: const Exercise(
        id: 'ex-05-vowel-ship-vs-sheep',
        referenceText: 'The sheep on the ship looks big and neat',
        referenceIpa: '/ðə ʃiːp ɒn ðə ʃɪp lʊks bɪɡ ænd niːt/',
        targetPhonemes: ['iː', 'ɪ'],
        sampleAudioUri: null,
      ),
      category: 'Nguyên âm ngắn và dài',
      difficulty: 'Cơ bản',
      description: 'Phân biệt nguyên âm dài /iː/ (cười mở mép) và ngắn /ɪ/ (thả lỏng cơ môi).',
      vietnameseTip: 'Âm /iː/ căng khóe môi sang hai bên; âm /ɪ/ thả lỏng hàm và phát âm nhanh, dứt khoát.',
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
      description: 'Luyện nhả đủ các âm đuôi phức /skt/, /ks/, /st/ mà người Việt hay bỏ quên.',
      vietnameseTip: 'Không bỏ âm cuối. Trong "asked" bật rõ /s/ rồi /t/; trong "six" bật /k/ rồi xì /s/.',
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
      vietnameseTip: 'Với /l/ đầu lưỡi chạm vào nướu răng cửa trên; với /r/ lưỡi cong lùi vào sâu khoang miệng và không chạm vòm trên.',
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
      vietnameseTip: 'Khởi đầu từ âm /ə/ lướt nhẹ sang /ʊ/, môi từ từ thu tròn lại ở cuối âm.',
    ),
    ExerciseDetail(
      exercise: const Exercise(
        id: 'ex-09-nasal-velar-drill',
        referenceText: 'The young singer is thinking of a song',
        referenceIpa: '/ðə jʌŋ ˈsɪŋər ɪz ˈθɪŋkɪŋ əv ə sɒŋ/',
        targetPhonemes: ['ŋk', 'ŋ'],
        sampleAudioUri: null,
      ),
      category: 'Âm mũi và âm vòm',
      difficulty: 'Trung bình',
      description: 'Luyện âm mũi /ŋ/ trong "young, song" và cụm âm /ŋk/ trong "thinking".',
      vietnameseTip: 'Nâng cuống lưỡi chạm ngạc mềm cho hơi thoát qua mũi. Với /ŋk/, sau khi ngắt hơi ở mũi phải bật dứt khoát âm /k/ ở đuôi từ.',
    ),
    ExerciseDetail(
      exercise: const Exercise(
        id: 'ex-10-nasal-bilabial-drill',
        referenceText: 'Many modern men make more money',
        referenceIpa: '/ˈmeni ˈmɒdən men meɪk mɔːr ˈmʌni/',
        targetPhonemes: ['m', 'n'],
        sampleAudioUri: null,
      ),
      category: 'Phụ âm mũi',
      difficulty: 'Cơ bản',
      description:
          'Luyện phụ âm môi /m/ và phụ âm răng /n/ rõ nét ở đầu và cuối từ.',
      vietnameseTip: 'Khép chặt hai môi lại để luồng hơi rung qua khoang mũi. Khi đọc các từ có đuôi /m/ cần ngậm chặt miệng để giữ trọn vẹn âm.',
    ),
    ExerciseDetail(
      exercise: const Exercise(
        id: 'ex-11-dental-unvoiced-drill',
        referenceText: 'Think through thirty-three thoughts on Thursday',
        referenceIpa: '/θɪŋk θruː ˈθɜːti θriː θɔːts ɒn ˈθɜːzdeɪ/',
        targetPhonemes: ['θ'],
        sampleAudioUri: null,
      ),
      category: 'Phụ âm răng xát',
      difficulty: 'Nâng cao',
      description: 'Chuyên sâu luyện âm /θ/ vô thanh đứng đầu các từ nối tiếp.',
      vietnameseTip: 'Đầu lưỡi thò nhẹ giữa hai hàm răng, thổi luồng hơi êm qua khe răng, không phát âm thành /s/ hay /t/.',
    ),
    ExerciseDetail(
      exercise: const Exercise(
        id: 'ex-12-v-vs-w',
        referenceText: 'We visit wonderful villages every Wednesday',
        referenceIpa: '/wiː ˈvɪzɪt ˈwʌndəfʊl ˈvɪlɪdʒɪz ˈevri ˈwenzdeɪ/',
        targetPhonemes: ['v', 'w'],
        sampleAudioUri: null,
      ),
      category: 'Cặp âm dễ nhầm',
      difficulty: 'Trung bình',
      description: 'Phân biệt răng chạm môi /v/ và tròn môi /w/.',
      vietnameseTip: 'Với /v/, răng cửa trên chạm nhẹ môi dưới và rung thanh quản. Với /w/, chu tròn hai môi rồi mở nhanh ra, răng không chạm môi.',
    ),
    ExerciseDetail(
      exercise: const Exercise(
        id: 'ex-13-p-vs-b',
        referenceText: 'Peter paid for a big black bag',
        referenceIpa: '/ˈpiːtər peɪd fər ə bɪɡ blæk bæɡ/',
        targetPhonemes: ['p', 'b'],
        sampleAudioUri: null,
      ),
      category: 'Phụ âm bật hơi',
      difficulty: 'Cơ bản',
      description:
          'Phân biệt âm bật hơi không rung /p/ và âm rung thanh quản /b/.',
      vietnameseTip: 'Với /p/, mím môi nén hơi rồi bật mạnh (có gió thổi vào lòng bàn tay). Với /b/, rung thanh quản ngay khi mở môi, không thổi gió.',
    ),
    ExerciseDetail(
      exercise: const Exercise(
        id: 'ex-14-u-vs-oo',
        referenceText: 'The cool pool is full of good wood',
        referenceIpa: '/ðə kuːl puːl ɪz fʊl əv ɡʊd wʊd/',
        targetPhonemes: ['uː', 'ʊ'],
        sampleAudioUri: null,
      ),
      category: 'Nguyên âm ngắn và dài',
      difficulty: 'Trung bình',
      description:
          'Phân biệt nguyên âm tròn môi kéo dài /uː/ và nguyên âm ngắn /ʊ/.',
      vietnameseTip: 'Với /uː/, chu tròn môi sâu về trước và ngân dài. Với /ʊ/, thả lỏng nhẹ môi và hàm, phát âm ngắn dứt khoát.',
    ),
    ExerciseDetail(
      exercise: const Exercise(
        id: 'ex-15-vowel-ae-vs-e',
        referenceText: 'The bad man met a black cat',
        referenceIpa: '/ðə bæd mæn met ə blæk kæt/',
        targetPhonemes: ['æ', 'e'],
        sampleAudioUri: null,
      ),
      category: 'Nguyên âm đơn',
      difficulty: 'Trung bình',
      description: 'Luyện nguyên âm bẹt /æ/ mở rộng khẩu hình theo chiều dọc.',
      vietnameseTip: 'Hạ thấp hàm dưới mở to miệng theo chiều dọc, đè phẳng cuống lưỡi xuống, phát âm âm lai giữa /a/ và /e/.',
    ),
    ExerciseDetail(
      exercise: const Exercise(
        id: 'ex-16-z-vs-j',
        referenceText: 'Zebras zoom through the jungle with joy',
        referenceIpa: '/ˈzebrəz zuːm θruː ðə ˈdʒʌŋɡl wɪð dʒɔɪ/',
        targetPhonemes: ['z', 'dʒ'],
        sampleAudioUri: null,
      ),
      category: 'Phụ âm xát và tắc xát',
      difficulty: 'Nâng cao',
      description: 'Phân biệt âm xát răng /z/ và âm tắc xát vòm /dʒ/.',
      vietnameseTip: 'Với /z/, khép hai răng và rung mạnh thanh quản. Với /dʒ/, chu môi và khép đầu lưỡi sau chân răng rồi bật ra kết hợp rung thanh quản.',
    ),
  ];

  /// Find exercise recommendations targeting specific phonemes that need improvement.
  static List<ImprovementRecommendation> getRecommendations(
    List<PhonemeFeedback> weakPhonemes, {
    String? currentExerciseId,
  }) {
    final recommendations = <ImprovementRecommendation>[];
    final seenPhonemes = <String>{};
    final usedExerciseIds = <String>{};

    for (final feedback in weakPhonemes) {
      if (feedback.status != PhonemeStatus.needsPractice) continue;
      // An insertion is an extra sound, not a reference phoneme to train.
      if (feedback.isInsertion) continue;
      final target = feedback.expectedIpa.trim();
      final key = IpaSymbols.tokenize(target).join(' ');
      if (key.isEmpty || !seenPhonemes.add(key)) continue;

      // Prefer a dedicated drill, then a sentence containing the same IPA
      // units. Repeating the current lesson is better than an unrelated one.
      ExerciseDetail? match;
      var bestRank = 3;
      for (final ex in catalog) {
        if (usedExerciseIds.contains(ex.id) ||
            !IpaSymbols.containsSequence(ex.referenceIpa, target)) {
          continue;
        }
        final dedicated = ex.targetPhonemes.any(
          (phoneme) => IpaSymbols.containsSequence(phoneme, target),
        );
        final rank = ex.id == currentExerciseId ? 2 : (dedicated ? 0 : 1);
        if (rank < bestRank) {
          match = ex;
          bestRank = rank;
        }
      }
      // Keep the phoneme's own guidance visible when no relevant drill exists.
      if (match == null) continue;

      usedExerciseIds.add(match.id);

      recommendations.add(
        ImprovementRecommendation(
          problemPhoneme: target,
          targetWord: feedback.word,
          articulatoryTip: feedback.suggestion,
          suggestedExercise: match,
        ),
      );

      // Limit to top 3 actionable recommendations to avoid visual overload
      if (recommendations.length >= 3) break;
    }

    return recommendations;
  }
}
