import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;

bool _initialized = false;

tz.Location profileLocation(String name) {
  if (name == 'UTC' || name == 'Etc/UTC') return tz.UTC;
  if (!_initialized) {
    data.initializeTimeZones();
    _initialized = true;
  }
  // Reject unknown zones rather than silently using Vietnam time.
  return tz.getLocation(name);
}

tz.TZDateTime profileTime(DateTime instant, String zone) =>
    tz.TZDateTime.from(instant.toUtc(), profileLocation(zone));

tz.TZDateTime nextReminder(DateTime now, String zone, int hour, int minute) {
  final local = profileTime(now, zone);
  var next = tz.TZDateTime(
    local.location,
    local.year,
    local.month,
    local.day,
    hour,
    minute,
  );
  if (!next.isAfter(local)) {
    next = tz.TZDateTime(
      local.location,
      local.year,
      local.month,
      local.day + 1,
      hour,
      minute,
    );
  }
  return next;
}
