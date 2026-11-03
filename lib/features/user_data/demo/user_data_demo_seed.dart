import '../../../core/contracts/contracts.dart';
import '../data/persistent_learning_repository.dart';
import '../data/persistent_user_repository.dart';

/// Tạo dữ liệu mẫu cho module User Data.
///
/// Dữ liệu chỉ được tạo khi repository chưa có hồ sơ.
/// Hàm seed có thể gọi nhiều lần mà không tạo dữ liệu trùng.
class UserDataDemoSeed {
  const UserDataDemoSeed._();

  static Future<void> seed({
    required PersistentUserRepository userRepository,
    required PersistentLearningRepository learningRepository,
  }) async {
    final List<UserProfile> existingProfiles = await userRepository
        .listProfiles();

    if (existingProfiles.isNotEmpty) {
      return;
    }

    final UserProfile khanhProfile = UserProfile(
      id: 'user-khanh',
      displayName: 'Vũ Tuấn Khanh',
      timeZone: 'Asia/Ho_Chi_Minh',
      createdAt: DateTime.utc(2026, 11, 2, 8),
    );

    final UserProfile demoProfile = UserProfile(
      id: 'user-demo',
      displayName: 'Người dùng Demo',
      timeZone: 'Asia/Ho_Chi_Minh',
      createdAt: DateTime.utc(2026, 11, 2, 9),
    );

    await userRepository.saveProfile(khanhProfile);
    await userRepository.saveProfile(demoProfile);
    await userRepository.selectProfile(khanhProfile.id);

    await learningRepository.saveSettings(
      LearningSettings(
        userId: khanhProfile.id,
        dailyGoalMinutes: 30,
        reminderEnabled: true,
        reminderHour: 20,
        reminderMinute: 0,
      ),
    );

    await learningRepository.saveSettings(
      LearningSettings(
        userId: demoProfile.id,
        dailyGoalMinutes: 15,
        reminderEnabled: false,
        reminderHour: 19,
        reminderMinute: 30,
      ),
    );

    await _seedPractice(
      learningRepository: learningRepository,
      sessionId: 'session-khanh-001',
      resultId: 'result-khanh-001',
      userId: khanhProfile.id,
      exerciseId: 'exercise-hello',
      startedAt: DateTime.utc(2026, 11, 1, 13),
      referenceText: 'Hello world',
      recognizedText: 'Hello world',
      score: 92,
    );

    await _seedPractice(
      learningRepository: learningRepository,
      sessionId: 'session-khanh-002',
      resultId: 'result-khanh-002',
      userId: khanhProfile.id,
      exerciseId: 'exercise-thank-you',
      startedAt: DateTime.utc(2026, 11, 2, 13),
      referenceText: 'Thank you very much',
      recognizedText: 'Thank you very much',
      score: 87,
    );

    await _seedPractice(
      learningRepository: learningRepository,
      sessionId: 'session-demo-001',
      resultId: 'result-demo-001',
      userId: demoProfile.id,
      exerciseId: 'exercise-good-morning',
      startedAt: DateTime.utc(2026, 11, 2, 14),
      referenceText: 'Good morning',
      recognizedText: 'Good morning',
      score: 81,
    );
  }

  static Future<void> _seedPractice({
    required PersistentLearningRepository learningRepository,
    required String sessionId,
    required String resultId,
    required String userId,
    required String exerciseId,
    required DateTime startedAt,
    required String referenceText,
    required String recognizedText,
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
      referenceText: referenceText,
      recognizedText: recognizedText,
      overallScore: score,
      provider: 'demo-provider',
      modelVersion: 'demo-v1',
      analyzedAt: startedAt.add(const Duration(minutes: 4)),
      phonemes: <PhonemeFeedback>[
        PhonemeFeedback(
          word: referenceText.split(' ').first,
          expectedIpa: '/demo/',
          recognizedIpa: '/demo/',
          score: score,
          status: score >= 85
              ? PhonemeStatus.correct
              : PhonemeStatus.needsPractice,
          startMilliseconds: 0,
          endMilliseconds: 600,
          suggestion: score >= 85
              ? 'Phát âm rõ và ổn định.'
              : 'Luyện chậm hơn và chú ý khẩu hình.',
        ),
      ],
    );

    await learningRepository.savePractice(session: session, result: result);
  }
}
