import 'package:flutter_test/flutter_test.dart';
import 'package:th3_english_ai/core/learning_time.dart';

void main() {
  test('history calendar dates use account zone instead of device zone', () {
    final range = profileDateRangeUtc(
      DateTime(2026, 11, 3),
      DateTime(2026, 11, 3),
      'Asia/Ho_Chi_Minh',
    );
    expect(range.fromUtc, DateTime.utc(2026, 11, 2, 17));
    expect(range.toUtc, DateTime.utc(2026, 11, 3, 17));
  });
  test('DST day ends at next local midnight rather than after 24 hours', () {
    final range = profileDateRangeUtc(
      DateTime(2026, 3, 8),
      DateTime(2026, 3, 8),
      'America/New_York',
    );
    expect(range.toUtc.difference(range.fromUtc), const Duration(hours: 23));
  });
}
