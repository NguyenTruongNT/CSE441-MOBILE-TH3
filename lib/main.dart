import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_shell.dart';
import 'features/discipline/discipline.dart';

void main() {
  runApp(
    EnglishLearningApp(
      pages: AppPages(
        progress: (context) => const ProgressPage(),
      ),
    ),
  );
}
