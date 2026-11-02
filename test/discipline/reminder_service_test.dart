import 'package:flutter_test/flutter_test.dart';
import 'package:th3_english_ai/core/contracts/contracts.dart';
import 'package:th3_english_ai/features/discipline/data/fake_discipline_data.dart';

void main() {
  group('FakeReminderService', () {
    late FakeReminderService service;

    setUp(() {
      service = FakeReminderService();
    });

    test('Requests permission correctly', () async {
      final permission = await service.requestPermission();
      expect(permission, ReminderPermission.granted);
    });

    test('Schedules daily reminder when enabled', () async {
      final settings = LearningSettings(
        userId: 'user-001',
        dailyGoalMinutes: 20,
        reminderEnabled: true,
        reminderHour: 21,
        reminderMinute: 30,
      );

      await service.scheduleDaily(settings);
      expect(service.scheduled['user-001'], isNotNull);
      expect(service.scheduled['user-001']!.reminderHour, 21);
      expect(service.scheduled['user-001']!.reminderMinute, 30);
    });

    test('Cancels schedule when reminderEnabled is false', () async {
      final enabledSettings = LearningSettings(
        userId: 'user-001',
        dailyGoalMinutes: 20,
        reminderEnabled: true,
        reminderHour: 21,
        reminderMinute: 30,
      );
      await service.scheduleDaily(enabledSettings);
      expect(service.scheduled['user-001'], isNotNull);

      final disabledSettings = LearningSettings(
        userId: 'user-001',
        dailyGoalMinutes: 20,
        reminderEnabled: false,
        reminderHour: 21,
        reminderMinute: 30,
      );
      await service.scheduleDaily(disabledSettings);
      expect(service.scheduled['user-001'], isNull);
    });

    test('Direct cancel removes scheduled reminder', () async {
      final settings = LearningSettings(
        userId: 'user-002',
        dailyGoalMinutes: 15,
        reminderEnabled: true,
      );
      await service.scheduleDaily(settings);
      expect(service.scheduled['user-002'], isNotNull);

      await service.cancel('user-002');
      expect(service.scheduled['user-002'], isNull);
    });

    test('Immediate test notification works', () async {
      final sent = await service.sendImmediateTestNotification(
        title: 'Title',
        body: 'Body',
      );
      expect(sent, isTrue);
      expect(service.testNotifications.length, 1);
      expect(service.testNotifications.first, 'Title: Body');
    });
  });
}

