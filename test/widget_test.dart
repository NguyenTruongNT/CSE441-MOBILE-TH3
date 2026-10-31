import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:th3_english_ai/app/app.dart';

void main() {
  testWidgets('App opens the progress destination', (tester) async {
    await tester.pumpWidget(const EnglishLearningApp());
    expect(find.text('Mỗi ngày một bước tiến.'), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
