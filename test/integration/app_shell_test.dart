import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:th3_english_ai/app/app.dart';
import 'package:th3_english_ai/app/app_shell.dart';
import 'package:th3_english_ai/app/app_navigation.dart';
import 'package:th3_english_ai/app/shared/app_states.dart';

void main() {
  for (final width in [320.0, 360.0, 768.0, 800.0, 1366.0]) {
    testWidgets('All destinations work at ${width.toInt()}px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const EnglishLearningApp());

      final navigation = find.byType(
        width >= 800 ? LearningSidebar : LearningBottomBar,
      );
      expect(navigation, findsOneWidget);
      final headlines = [
        'Mỗi ngày một bước tiến.',
        'Tự tin hơn qua từng âm.',
        'Nhìn lại để tiến xa hơn.',
        'Hành trình của riêng bạn.',
      ];
      for (var index = 0; index < navigationKeys.length; index++) {
        await tester.tap(find.byKey(navigationKeys[index]));
        await tester.pumpAndSettle();
        expect(find.text(headlines[index]), findsOneWidget);
        expect(find.textContaining('Chờ tích hợp module'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('Large text and short viewport remain scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const EnglishLearningApp());
    final notice = find.textContaining('Chờ tích hợp module');
    await tester.ensureVisible(notice);
    await tester.pumpAndSettle();
    expect(notice.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Injected module pages preserve state across tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      EnglishLearningApp(
        pages: AppPages(
          progress: (_) => const _CounterPage(),
          pronunciation: (_) => const Text('Injected pronunciation'),
          history: (_) => const Text('Injected history'),
          profile: (_) => const Text('Injected profile'),
        ),
      ),
    );
    await tester.tap(find.text('Count: 0'));
    await tester.pump();
    for (final entry in {
      1: 'Injected pronunciation',
      2: 'Injected history',
      3: 'Injected profile',
    }.entries) {
      await tester.tap(find.byKey(navigationKeys[entry.key]));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
    }
    await tester.tap(find.byKey(navigationKeys[0]));
    await tester.pumpAndSettle();
    expect(find.text('Count: 1'), findsOneWidget);
    expect(find.textContaining('Chờ tích hợp module'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('modules initialize on first visit and remain mounted', (
    tester,
  ) async {
    var initializes = 0;
    await tester.pumpWidget(
      EnglishLearningApp(
        pages: AppPages(
          progress: (_) => const Text('Progress ready'),
          pronunciation: (_) =>
              _InitializationProbe(onInitialize: () => initializes++),
        ),
      ),
    );
    expect(initializes, 0);
    await tester.tap(find.byKey(navigationKeys[1]));
    await tester.pumpAndSettle();
    expect(initializes, 1);
    await tester.tap(find.byKey(navigationKeys[0]));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(navigationKeys[1]));
    await tester.pumpAndSettle();
    expect(initializes, 1);
  });

  testWidgets(
    'sidebar collapses and expands without resetting the selected page',
    (tester) async {
      tester.view.physicalSize = const Size(1366, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const EnglishLearningApp());
      await tester.tap(find.byKey(navigationKeys[1]));
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const ValueKey('sidebar-toggle')));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(find.text('Tự tin hơn qua từng âm.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('Shared error state invokes retry', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppMessageState(
            title: 'Không tải được dữ liệu',
            message: 'Vui lòng kiểm tra kết nối.',
            onRetry: () => retries++,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Thử lại'));
    expect(retries, 1);
  });
}

class _InitializationProbe extends StatefulWidget {
  const _InitializationProbe({required this.onInitialize});
  final VoidCallback onInitialize;
  @override
  State<_InitializationProbe> createState() => _InitializationProbeState();
}

class _InitializationProbeState extends State<_InitializationProbe> {
  @override
  void initState() {
    super.initState();
    widget.onInitialize();
  }

  @override
  Widget build(BuildContext context) => const Text('Practice ready');
}

class _CounterPage extends StatefulWidget {
  const _CounterPage();

  @override
  State<_CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<_CounterPage> {
  int count = 0;

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      onPressed: () => setState(() => count++),
      child: Text('Count: $count'),
    ),
  );
}
