import 'package:flutter_test/flutter_test.dart';

import 'package:th3_english_ai/features/user_data/data/persistent_learning_repository.dart';
import 'package:th3_english_ai/features/user_data/data/persistent_user_repository.dart';
import 'package:th3_english_ai/features/user_data/data/user_data_store.dart';
import 'package:th3_english_ai/features/user_data/demo/user_data_demo_seed.dart';

void main() {
  group('UserDataDemoSeed', () {
    test('tạo hai hồ sơ và lịch sử tách biệt', () async {
      final MemoryUserDataStore store = MemoryUserDataStore();

      final PersistentUserRepository userRepository = PersistentUserRepository(
        store: store,
      );

      final PersistentLearningRepository learningRepository =
          PersistentLearningRepository(store: store);

      await UserDataDemoSeed.seed(
        userRepository: userRepository,
        learningRepository: learningRepository,
      );

      final profiles = await userRepository.listProfiles();

      expect(profiles, hasLength(2));

      final selected = await userRepository.getSelectedProfile();

      expect(selected, isNotNull);
      expect(selected!.id, 'user-khanh');

      final khanhSessions = await learningRepository.listSessions(
        userId: 'user-khanh',
        fromUtc: DateTime.utc(2026, 11, 1),
        toUtc: DateTime.utc(2026, 11, 4),
      );

      final demoSessions = await learningRepository.listSessions(
        userId: 'user-demo',
        fromUtc: DateTime.utc(2026, 11, 1),
        toUtc: DateTime.utc(2026, 11, 4),
      );

      expect(khanhSessions, hasLength(2));
      expect(demoSessions, hasLength(1));
    });

    test('gọi seed nhiều lần không tạo dữ liệu trùng', () async {
      final MemoryUserDataStore store = MemoryUserDataStore();

      final PersistentUserRepository userRepository = PersistentUserRepository(
        store: store,
      );

      final PersistentLearningRepository learningRepository =
          PersistentLearningRepository(store: store);

      await UserDataDemoSeed.seed(
        userRepository: userRepository,
        learningRepository: learningRepository,
      );

      await UserDataDemoSeed.seed(
        userRepository: userRepository,
        learningRepository: learningRepository,
      );

      final profiles = await userRepository.listProfiles();

      final sessions = await learningRepository.listSessions(
        userId: 'user-khanh',
        fromUtc: DateTime.utc(2026, 11, 1),
        toUtc: DateTime.utc(2026, 11, 4),
      );

      expect(profiles, hasLength(2));
      expect(sessions, hasLength(2));
    });
  });
}
