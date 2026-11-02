import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:th3_english_ai/app/app_theme.dart';
import 'package:th3_english_ai/core/contracts/contracts.dart';
import 'package:th3_english_ai/features/discipline/data/fake_discipline_data.dart';
import 'package:th3_english_ai/features/discipline/presentation/progress_page.dart';
import 'package:th3_english_ai/features/discipline/presentation/widgets/daily_goal_ring.dart';
import 'package:th3_english_ai/features/discipline/presentation/widgets/demo_simulation_bar.dart';
import 'package:th3_english_ai/features/discipline/presentation/widgets/progress_header_card.dart';
import 'package:th3_english_ai/features/discipline/presentation/widgets/settings_reminder_card.dart';
import 'package:th3_english_ai/features/discipline/presentation/widgets/streak_hero_card.dart';
import 'package:th3_english_ai/features/discipline/presentation/widgets/weekly_bar_chart.dart';

class _FakeUserRepository implements UserRepository {
  UserProfile? selected = UserProfile(
    id: 'default-user-01',
    displayName: 'Học viên mẫu',
    createdAt: DateTime.utc(2026, 10, 1),
  );

  @override
  Future<UserProfile?> getSelectedProfile() async => selected;

  @override
  Future<List<UserProfile>> listProfiles() async => [selected!];

  @override
  Future<void> saveProfile(UserProfile profile) async {
    selected = profile;
  }

  @override
  Future<void> selectProfile(String userId) async {}
}

void main() {
  group('ProgressPage Responsive & Interactions', () {
    late FakeLearningRepository fakeRepo;
    late FakeReminderService fakeReminder;
    late _FakeUserRepository fakeUser;

    setUp(() {
      fakeRepo = FakeLearningRepository();
      fakeReminder = FakeReminderService();
      fakeUser = _FakeUserRepository();
    });

    Widget createTestWidget() {
      return MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ProgressPage(
            userRepository: fakeUser,
            learningRepository: fakeRepo,
            reminderService: fakeReminder,
          ),
        ),
      );
    }

    for (final width in [360.0, 768.0, 800.0, 1366.0]) {
      testWidgets('Renders all cards cleanly at width ${width.toInt()}px without overflow', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(ProgressHeaderCard), findsOneWidget);
        expect(find.byType(StreakHeroCard), findsOneWidget);
        expect(find.byType(DailyGoalRing), findsOneWidget);
        expect(find.byType(WeeklyBarChart), findsOneWidget);
        expect(find.byType(SettingsReminderCard), findsOneWidget);
        expect(find.byType(DemoSimulationBar), findsOneWidget);

        // Verification of 0 layout exceptions/overflows
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Tapping 20 phút goal chip updates goal and saves settings', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final chipFinder = find.widgetWithText(ChoiceChip, '20 phút');
      expect(chipFinder, findsOneWidget);

      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      final settings = await fakeRepo.getSettings('default-user-01');
      expect(settings.dailyGoalMinutes, 20);
      expect(find.textContaining('Mục tiêu: 20p'), findsOneWidget);
    });

    testWidgets('Demo action +5p học adds minutes and updates UI', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Seed had 10 minutes today
      expect(find.text('10'), findsOneWidget);

      final addBtn = find.widgetWithText(FilledButton, '+5p học hôm nay');
      expect(addBtn, findsOneWidget);

      await tester.ensureVisible(addBtn);
      await tester.pumpAndSettle();
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Now should have 15 minutes today
      expect(find.text('15'), findsOneWidget);
      expect(find.textContaining('Đã thêm 5 phút luyện tập'), findsOneWidget);
    });
  });
}
