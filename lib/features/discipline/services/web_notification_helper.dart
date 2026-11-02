import 'web_notification_helper_stub.dart'
    if (dart.library.html) 'web_notification_helper_web.dart';

Future<bool> triggerBrowserNotification({
  required String title,
  required String body,
}) =>
    showWebNotification(title: title, body: body);

Future<bool> requestBrowserNotificationPermission() =>
    requestWebNotificationPermission();
