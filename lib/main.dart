import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_shell.dart';
import 'app/demo_account_gate.dart';
import 'features/discipline/discipline.dart';
import 'features/pronunciation/pronunciation.dart';
import 'features/user_data/user_data.dart';
import 'features/user_data/data/learning_database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Một persistent store dùng chung cho toàn bộ dữ liệu người dùng.
  final database = LearningDatabase();

  // Hai repository phải dùng cùng một store để hồ sơ, settings,
  // phiên luyện tập và kết quả luôn nhất quán.
  final userRepository = DriftUserRepository(database);

  final learningRepository = DriftLearningRepository(database);

  final reminderService = LocalReminderService();

  runApp(
    EnglishLearningApp(
      home: DemoAccountGate(
        users: userRepository,
        initialize: () =>
            migrateLegacyUserData(database, SharedPreferencesUserDataStore()),
        buildHome: (user, leave) => AppShell(
          key: ValueKey(user.id),
          accountName: user.displayName,
          onLogout: () async {
            await reminderService.cancel(user.id);
            await userRepository.signOut();
            leave();
          },
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
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 36,
                        child: Icon(Icons.person_outline_rounded, size: 36),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.displayName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tài khoản demo · Dữ liệu lưu riêng trên thiết bị này',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () async {
                          await reminderService.cancel(user.id);
                          await userRepository.signOut();
                          leave();
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Đăng xuất'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}
