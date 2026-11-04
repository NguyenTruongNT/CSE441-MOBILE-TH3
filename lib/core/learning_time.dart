import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;

bool _initialized = false;

tz.Location profileLocation(String name) {
  if (name == 'UTC' || name == 'Etc/UTC') return tz.UTC;
  if (!_initialized) {
    data.initializeTimeZones();
    _initialized = true;
  }
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

/// Inclusive calendar dates in the account's zone, returned as a UTC interval.
/// Constructing the next midnight also handles 23/25-hour daylight-saving days.
({DateTime fromUtc, DateTime toUtc}) profileDateRangeUtc(
  DateTime start,
  DateTime end,
  String zone,
) {
  final location = profileLocation(zone);
  final from = tz.TZDateTime(
    location,
    start.year,
    start.month,
    start.day,
  ).toUtc();
  final to = tz.TZDateTime(location, end.year, end.month, end.day + 1).toUtc();
  if (!from.isBefore(to)) throw ArgumentError('Invalid calendar date range.');
  return (fromUtc: from, toUtc: to);
}

String formatCalendarDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String formatProfileDateTime(DateTime instant, String zone) {
  final local = profileTime(instant, zone);
  return '${formatCalendarDate(local)} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
