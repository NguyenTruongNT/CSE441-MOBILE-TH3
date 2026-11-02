import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:th3_english_ai/core/contracts/contracts.dart';
import 'package:th3_english_ai/features/discipline/services/local_reminder_service.dart';
import 'package:th3_english_ai/features/discipline/services/discipline_time.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final calls = <MethodCall>[];
  var allowed = true;
  var failSchedule = false;
  late LocalReminderService service;
  final now = DateTime.utc(2026, 11, 2, 14);

  LearningSettings settings({
    String user = 'a',
    int hour = 20,
    bool enabled = true,
  }) => LearningSettings(
    userId: user,
    reminderEnabled: enabled,
    reminderHour: hour,
  );

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    allowed = true;
    failSchedule = false;
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'initialize') return true;
          if (call.method == 'requestNotificationsPermission' ||
              call.method == 'areNotificationsEnabled') {
            return allowed;
          }
          if (call.method == 'zonedSchedule' && failSchedule) {
            throw PlatformException(code: 'schedule_failed');
          }
          return null;
        });
    service = LocalReminderService(clock: () => now);
  });
  tearDown(() {
    service.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('Android receives repeating zoned alarm for next local day', () async {
    await service.scheduleDaily(settings());
    final args =
        calls.singleWhere((c) => c.method == 'zonedSchedule').arguments as Map;
    expect(args['id'], LocalReminderService.dailyNotificationId);
    expect(args['timeZoneName'], 'Asia/Ho_Chi_Minh');
    expect(args['scheduledDateTime'], startsWith('2026-11-03T20:00:00'));
    expect(args['matchDateTimeComponents'], isNotNull);
    expect(args['payload'], 'a');
  });

  test(
    'Changing time/profile replaces one reserved alarm; disabling cancels it',
    () async {
      await service.scheduleDaily(settings());
      await service.scheduleDaily(settings(user: 'b', hour: 22));
      final schedules = calls
          .where((c) => c.method == 'zonedSchedule')
          .toList();
      expect(schedules.length, 2);
      expect(
        (schedules[0].arguments as Map)['id'],
        (schedules[1].arguments as Map)['id'],
      );
      await service.cancel('a');
      expect(calls.where((c) => c.method == 'cancel'), isEmpty);
      await service.scheduleDaily(settings(user: 'b', enabled: false));
      expect(calls.where((c) => c.method == 'cancel').length, 1);
    },
  );

  test(
    'Denied permission prevents alarm and immediate success claims',
    () async {
      allowed = false;
      expect(await service.requestPermission(), ReminderPermission.denied);
      await expectLater(
        service.scheduleDaily(settings()),
        throwsA(isA<AppFailure>()),
      );
      expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
      expect(
        await service.sendImmediateTestNotification(
          title: 'test',
          body: 'test',
        ),
        isFalse,
      );
      expect(service.onNotificationTriggered.value, isNull);
    },
  );

  test('Platform scheduling failures propagate to caller', () async {
    failSchedule = true;
    await expectLater(
      service.scheduleDaily(settings()),
      throwsA(isA<PlatformException>()),
    );
  });

  test(
    'New service can cancel a persisted alarm after process restart',
    () async {
      await service.cancel('previous-user');
      final args =
          calls.singleWhere((c) => c.method == 'cancel').arguments as Map;
      expect(args['id'], LocalReminderService.dailyNotificationId);
    },
  );

  test('Unsupported platform does not claim permission granted', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    expect(await service.requestPermission(), ReminderPermission.unsupported);
  });

  test('IANA timezone observes DST and rejects invalid identifiers', () {
    expect(profileTime(DateTime.utc(2026, 7, 1), 'America/New_York').hour, 20);
    expect(profileTime(DateTime.utc(2026, 12, 1), 'America/New_York').hour, 19);
    expect(() => profileLocation('Invalid/Zone'), throwsA(isA<Exception>()));
    final next = nextReminder(
      DateTime.utc(2026, 10, 31, 16),
      'America/New_York',
      10,
      0,
    );
    expect(next.toUtc(), DateTime.utc(2026, 11, 1, 15));
  });
}
