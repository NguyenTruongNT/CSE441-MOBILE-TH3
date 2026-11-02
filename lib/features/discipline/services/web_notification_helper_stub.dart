// Stub implementation for non-web platforms (Android, iOS, VM, flutter test).

Future<bool> requestWebNotificationPermission() async => false;

Future<bool> showWebNotification({
  required String title,
  required String body,
}) async => false;
