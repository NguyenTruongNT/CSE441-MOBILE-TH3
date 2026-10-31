import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'app_theme.dart';

/// Composition root: replace page builders when feature modules are delivered.
class EnglishLearningApp extends StatelessWidget {
  const EnglishLearningApp({super.key, this.pages = const AppPages()});

  final AppPages pages;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'English AI · Nhóm 12',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: AppShell(pages: pages),
  );
}
