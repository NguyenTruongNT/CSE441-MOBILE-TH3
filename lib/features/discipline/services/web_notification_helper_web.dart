// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<bool> requestWebNotificationPermission() async {
  if (!html.Notification.supported) return false;
  final perm = await html.Notification.requestPermission();
  return perm == 'granted';
}

Future<bool> showWebNotification({
  required String title,
  required String body,
}) async {
  if (!html.Notification.supported) return false;

  var currentPerm = html.Notification.permission;
  if (currentPerm != 'granted') {
    currentPerm = await html.Notification.requestPermission();
  }

  if (currentPerm == 'granted') {
    html.Notification(
      title,
      body: body,
      icon: 'favicon.png',
    );
    return true;
  }

  return false;
}
