import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/contracts/contracts.dart';
import 'discipline_time.dart';
import 'web_notification_helper.dart';

class NotificationPayload {
  const NotificationPayload({
    required this.title,
    required this.body,
    required this.timestamp,
  });
  final String title;
  final String body;
  final DateTime timestamp;
}

/// A reserved ID replaces the selected profile's alarm even after a restart.
class LocalReminderService implements ReminderService {
  LocalReminderService({
    FlutterLocalNotificationsPlugin? plugin,
    DateTime Function()? clock,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _clock = clock ?? DateTime.now;

  static const dailyNotificationId = 12001;
  final FlutterLocalNotificationsPlugin _plugin;
  final DateTime Function() _clock;
  Future<void>? _initialization;
  final ValueNotifier<NotificationPayload?> onNotificationTriggered =
      ValueNotifier(null);
  Timer? _webTimer;
  String? _lastWebDelivery;
  LearningSettings? _settings;
  bool _disposed = false;

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    try {
      if (!_isAndroid) {
        throw const AppFailure(
          AppFailureCode.unsupported,
          'Nền tảng này chưa hỗ trợ thông báo.',
        );
      }
      final initialized = await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      if (initialized != true) {
        throw StateError('Không khởi tạo được thông báo Android.');
      }
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  @override
  Future<ReminderPermission> requestPermission() async {
    if (kIsWeb) {
      return await requestBrowserNotificationPermission()
          ? ReminderPermission.granted
          : ReminderPermission.denied;
    }
    if (!_isAndroid) return ReminderPermission.unsupported;
    try {
      await initialize();
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()!
          .requestNotificationsPermission();
      return granted == true
          ? ReminderPermission.granted
          : ReminderPermission.denied;
    } catch (_) {
      return ReminderPermission.denied;
    }
  }

  @override
  Future<void> scheduleDaily(LearningSettings settings) async {
    if (_disposed) throw StateError('Reminder service đã đóng.');
    if (!settings.reminderEnabled) {
      await cancel(settings.userId);
      return;
    }
    final next = nextReminder(
      _clock(),
      settings.timeZone,
      settings.reminderHour,
      settings.reminderMinute,
    );
    if (kIsWeb) {
      _webTimer?.cancel();
      _settings = settings;
      _webTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => _checkWebReminder(),
      );
      return;
    }
    await initialize();
    final permitted = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()!
        .areNotificationsEnabled();
    if (permitted != true) {
      throw const AppFailure(
        AppFailureCode.permissionDenied,
        'Chưa có quyền thông báo. Hãy bật nhắc học để cấp quyền.',
      );
    }
    // Inexact alarms need no special access but may be delayed by Android Doze.
    await _plugin.zonedSchedule(
      id: dailyNotificationId,
      title: 'English AI · Nhắc học',
      body:
          'Dành ${settings.dailyGoalMinutes} phút luyện tiếng Anh hôm nay nhé!',
      scheduledDate: next,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'english_ai_daily',
          'Nhắc học hằng ngày',
          channelDescription: 'Nhắc duy trì thói quen luyện tiếng Anh',
          importance: Importance.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: settings.userId,
    );
    _settings = settings;
  }

  @override
  Future<void> cancel(String userId) async {
    if (_settings != null && _settings!.userId != userId) return;
    if (!kIsWeb) {
      await initialize();
      await _plugin.cancel(id: dailyNotificationId);
    }
    _settings = null;
    _webTimer?.cancel();
    _lastWebDelivery = null;
  }

  Future<bool> sendImmediateTestNotification({
    required String title,
    required String body,
  }) async {
    if (_disposed) return false;
    bool delivered;
    try {
      if (kIsWeb) {
        delivered = await triggerBrowserNotification(title: title, body: body);
      } else {
        if (await requestPermission() != ReminderPermission.granted) {
          return false;
        }
        await _plugin.show(
          id: 9999,
          title: title,
          body: body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'english_ai_test',
              'Kiểm tra thông báo',
              importance: Importance.high,
            ),
          ),
        );
        delivered = true;
      }
    } catch (error) {
      debugPrint('Không gửi được thông báo: $error');
      return false;
    }
    if (delivered && !_disposed) {
      onNotificationTriggered.value = NotificationPayload(
        title: title,
        body: body,
        timestamp: _clock(),
      );
    }
    return delivered;
  }

  void _checkWebReminder() {
    final settings = _settings;
    if (settings == null || _disposed) return;
    final now = profileTime(_clock(), settings.timeZone);
    final delivery =
        '${settings.userId}/${now.year}/${now.month}/${now.day}/${now.hour}/${now.minute}';
    if (now.hour == settings.reminderHour &&
        now.minute == settings.reminderMinute &&
        _lastWebDelivery != delivery) {
      _lastWebDelivery = delivery;
      unawaited(
        sendImmediateTestNotification(
          title: 'English AI · Nhắc học',
          body: 'Đến giờ luyện tiếng Anh hôm nay!',
        ),
      );
    }
  }

  /// Native schedules belong to the OS and survive closing this Dart instance.
  void dispose() {
    _disposed = true;
    _webTimer?.cancel();
    onNotificationTriggered.dispose();
  }
}
