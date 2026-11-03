import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:th3_english_ai/app/app.dart';
import 'package:th3_english_ai/app/demo_account_gate.dart';
import 'package:th3_english_ai/features/user_data/data/learning_database.dart';

void main() {
  for (final width in [360.0, 1366.0]) {
    testWidgets('demo entry, logout and account separation at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = LearningDatabase(NativeDatabase.memory());
      final users = DriftUserRepository(db);
      addTearDown(db.close);
      addTearDown(users.dispose);
      await tester.pumpWidget(
        EnglishLearningApp(
          home: DemoAccountGate(
            users: users,
            buildHome: (user, leave) => Scaffold(
              body: Column(
                children: [
                  Text('Active: ${user.id}'),
                  TextButton(
                    onPressed: () async {
                      await users.signOut();
                      leave();
                    },
                    child: const Text('Leave'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tạo hồ sơ'), findsNothing);
      await tester.tap(find.text('Học viên 1'));
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Active: demo-learner-1'), findsOneWidget);
      await tester.tap(find.text('Leave'));
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Học viên 2'));
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Active: demo-learner-2'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
