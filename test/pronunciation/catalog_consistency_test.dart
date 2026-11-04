import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:th3_english_ai/features/pronunciation/data/default_exercises.dart';

void main() {
  test(
    'frontend and backend share the same exercise texts, IPA and targets',
    () {
      final rows = jsonDecode(
        File('assets/pronunciation/exercises.json').readAsStringSync(),
      ) as List;
      final byId = {for (final row in rows) row['id']: row};
      expect(byId.length, DefaultExercises.catalog.length);
      for (final lesson in DefaultExercises.catalog) {
        final row = byId[lesson.id];
        expect(row, isNotNull);
        expect(row['referenceText'], lesson.referenceText);
        expect(row['referenceIpa'], lesson.referenceIpa);
        expect(row['targetPhonemes'], lesson.targetPhonemes);
        for (final target in lesson.targetPhonemes) {
          expect(
            lesson.referenceIpa.contains(target),
            isTrue,
            reason: '${lesson.id} must contain target $target',
          );
        }
      }
    },
  );
}
