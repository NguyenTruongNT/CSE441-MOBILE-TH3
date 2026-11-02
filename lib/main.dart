import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_shell.dart';
import 'features/discipline/discipline.dart';

void main() {
  // Shared demo data survives tab changes, but resets when the app restarts.
  final learning = FakeLearningRepository();
  final users = FakeUserRepository();
  const useRealNotifications = bool.fromEnvironment('USE_REAL_NOTIFICATIONS');
  final reminders = useRealNotifications
      ? LocalReminderService()
      : FakeReminderService();
  runApp(
    EnglishLearningApp(
      pages: AppPages(
        progress: (context) => ProgressPage(
          learningRepository: learning,
          userRepository: users,
          reminderService: reminders,
        ),
      ),
    ),
  );
}
