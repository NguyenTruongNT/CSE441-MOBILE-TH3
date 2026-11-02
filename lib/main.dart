import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_shell.dart';
import 'features/pronunciation/pronunciation.dart';

void main() {
  runApp(
    EnglishLearningApp(
      pages: AppPages(
        pronunciation: (_) => const PronunciationPage(),
      ),
    ),
  );
}
