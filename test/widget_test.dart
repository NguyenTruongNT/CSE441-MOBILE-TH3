import 'package:flutter_test/flutter_test.dart';
import 'package:th3_english_ai/app/app.dart';
import 'package:th3_english_ai/app/app_navigation.dart';

void main() {
  testWidgets('App opens the progress destination', (tester) async {
    await tester.pumpWidget(const EnglishLearningApp());
    expect(find.text('Mỗi ngày một bước tiến.'), findsOneWidget);
    expect(find.byType(LearningSidebar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
