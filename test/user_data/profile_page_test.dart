import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:th3_english_ai/core/contracts/contracts.dart';
import 'package:th3_english_ai/features/user_data/data/persistent_user_repository.dart';
import 'package:th3_english_ai/features/user_data/data/user_data_store.dart';
import 'package:th3_english_ai/features/user_data/presentation/profile_page.dart';

void main() {
  Future<PersistentUserRepository> createRepository({
    bool withProfiles = true,
  }) async {
    final PersistentUserRepository repository = PersistentUserRepository(
      store: MemoryUserDataStore(),
    );

    if (withProfiles) {
      await repository.saveProfile(
        UserProfile(
          id: 'user-khanh',
          displayName: 'Vũ Tuấn Khanh',
          createdAt: DateTime.utc(2026, 11, 2, 8),
        ),
      );

      await repository.saveProfile(
        UserProfile(
          id: 'user-demo',
          displayName: 'Người dùng Demo',
          createdAt: DateTime.utc(2026, 11, 2, 9),
        ),
      );

      await repository.selectProfile('user-khanh');
    }

    return repository;
  }

  Future<void> pumpProfilePage(
    WidgetTester tester, {
    required PersistentUserRepository repository,
    Size size = const Size(400, 800),
  }) async {
    await tester.binding.setSurfaceSize(size);

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF12796F)),
        ),
        home: Scaffold(
          body: ProfilePage(
            userRepository: repository,
            idFactory: () => 'user-new',
            clock: () => DateTime.utc(2026, 11, 2, 10),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('hiển thị hai hồ sơ và hồ sơ đang chọn', (
    WidgetTester tester,
  ) async {
    final PersistentUserRepository repository = await createRepository();

    await pumpProfilePage(tester, repository: repository);

    expect(find.text('Vũ Tuấn Khanh'), findsOneWidget);
    expect(find.text('Người dùng Demo'), findsOneWidget);
    expect(find.text('Đang chọn'), findsOneWidget);
    expect(find.text('Chọn'), findsOneWidget);
  });

  testWidgets('hiển thị trạng thái rỗng', (WidgetTester tester) async {
    final PersistentUserRepository repository = await createRepository(
      withProfiles: false,
    );

    await pumpProfilePage(tester, repository: repository);

    expect(find.text('Chưa có hồ sơ'), findsOneWidget);
    expect(find.text('Tạo hồ sơ đầu tiên'), findsOneWidget);
  });

  testWidgets('tạo hồ sơ mới và tự động chọn', (WidgetTester tester) async {
    final PersistentUserRepository repository = await createRepository(
      withProfiles: false,
    );

    await pumpProfilePage(tester, repository: repository);

    await tester.tap(find.text('Tạo hồ sơ đầu tiên'));

    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('profile-display-name-field')),
      'Hồ sơ mới',
    );

    await tester.tap(find.byKey(const ValueKey('profile-form-submit-button')));

    await tester.pumpAndSettle();

    expect(find.text('Hồ sơ mới'), findsOneWidget);
    expect(find.text('Đang chọn'), findsOneWidget);

    final List<UserProfile> profiles = await repository.listProfiles();

    final UserProfile? selected = await repository.getSelectedProfile();

    expect(profiles, hasLength(1));
    expect(selected, isNotNull);
    expect(selected!.id, 'user-new');
    expect(selected.displayName, 'Hồ sơ mới');
  });

  testWidgets('không tạo hồ sơ khi tên trống', (WidgetTester tester) async {
    final PersistentUserRepository repository = await createRepository(
      withProfiles: false,
    );

    await pumpProfilePage(tester, repository: repository);

    await tester.tap(find.text('Tạo hồ sơ đầu tiên'));

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('profile-form-submit-button')));

    await tester.pump();

    expect(find.text('Vui lòng nhập tên hồ sơ.'), findsOneWidget);

    expect(await repository.listProfiles(), isEmpty);
  });

  testWidgets('chọn hồ sơ khác', (WidgetTester tester) async {
    final PersistentUserRepository repository = await createRepository();

    await pumpProfilePage(tester, repository: repository);

    await tester.tap(find.byKey(const ValueKey('select-profile-user-demo')));

    await tester.pumpAndSettle();

    final UserProfile? selected = await repository.getSelectedProfile();

    expect(selected, isNotNull);
    expect(selected!.id, 'user-demo');

    expect(find.text('Đã chọn hồ sơ Người dùng Demo.'), findsOneWidget);
  });

  testWidgets('chỉnh sửa hồ sơ không tạo bản ghi trùng', (
    WidgetTester tester,
  ) async {
    final PersistentUserRepository repository = await createRepository();

    await pumpProfilePage(tester, repository: repository);

    await tester.tap(find.byKey(const ValueKey('edit-profile-user-khanh')));

    await tester.pumpAndSettle();

    final Finder nameField = find.byKey(
      const ValueKey('profile-display-name-field'),
    );

    await tester.enterText(nameField, 'Khanh cập nhật');

    await tester.tap(find.byKey(const ValueKey('profile-form-submit-button')));

    await tester.pumpAndSettle();

    final List<UserProfile> profiles = await repository.listProfiles();

    expect(profiles, hasLength(2));

    final UserProfile updatedProfile = profiles.firstWhere(
      (UserProfile profile) => profile.id == 'user-khanh',
    );

    expect(updatedProfile.displayName, 'Khanh cập nhật');

    expect(find.text('Khanh cập nhật'), findsOneWidget);
  });

  testWidgets('không tràn giao diện ở kích thước mobile', (
    WidgetTester tester,
  ) async {
    final PersistentUserRepository repository = await createRepository();

    await pumpProfilePage(
      tester,
      repository: repository,
      size: const Size(360, 800),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Hồ sơ người học'), findsOneWidget);
  });

  testWidgets('không tràn giao diện ở kích thước desktop', (
    WidgetTester tester,
  ) async {
    final PersistentUserRepository repository = await createRepository();

    await pumpProfilePage(
      tester,
      repository: repository,
      size: const Size(1366, 768),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Hồ sơ người học'), findsOneWidget);
  });
}
