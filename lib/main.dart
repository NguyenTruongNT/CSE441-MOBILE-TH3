import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_shell.dart';
import 'core/contracts/contracts.dart';
import 'features/discipline/discipline.dart';
import 'features/pronunciation/pronunciation.dart';
import 'features/user_data/user_data.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Một persistent store dùng chung cho toàn bộ dữ liệu người dùng.
  final SharedPreferencesUserDataStore store = SharedPreferencesUserDataStore();

  // Hai repository phải dùng cùng một store để hồ sơ, settings,
  // phiên luyện tập và kết quả luôn nhất quán.
  final PersistentUserRepository userRepository = PersistentUserRepository(
    store: store,
  );

  final PersistentLearningRepository learningRepository =
      PersistentLearningRepository(store: store);

  const bool useRealNotifications = bool.fromEnvironment(
    'USE_REAL_NOTIFICATIONS',
  );

  final ReminderService reminderService = useRealNotifications
      ? LocalReminderService()
      : FakeReminderService();

  runApp(
    EnglishLearningApp(
      pages: AppPages(
        pronunciation: (context) => PronunciationPage(
          learningRepository: learningRepository,
          userRepository: userRepository,
        ),
        progress: (BuildContext context) {
          return ProgressPage(
            learningRepository: learningRepository,
            userRepository: userRepository,
            reminderService: reminderService,
          );
        },
        history: (BuildContext context) {
          return HistoryPage(
            userRepository: userRepository,
            learningRepository: learningRepository,
          );
        },
        profile: (BuildContext context) {
          return ProfilePage(userRepository: userRepository);
        },
      ),
    ),
  );
}
