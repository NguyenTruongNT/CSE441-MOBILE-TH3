import 'package:flutter_test/flutter_test.dart';

import 'package:th3_english_ai/core/contracts/contracts.dart';
import 'package:th3_english_ai/features/user_data/data/persistent_user_repository.dart';
import 'package:th3_english_ai/features/user_data/data/user_data_store.dart';

void main() {
  group('PersistentUserRepository', () {
    late MemoryUserDataStore store;
    late PersistentUserRepository repository;

    setUp(() {
      store = MemoryUserDataStore();

      repository = PersistentUserRepository(store: store);
    });

    UserProfile createProfile({
      required String id,
      required String name,
      int day = 1,
    }) {
      return UserProfile(
        id: id,
        displayName: name,
        timeZone: 'Asia/Ho_Chi_Minh',
        createdAt: DateTime.utc(2026, 11, day, 8),
      );
    }

    test('danh sách ban đầu rỗng', () async {
      final List<UserProfile> profiles = await repository.listProfiles();

      expect(profiles, isEmpty);
    });

    test('lưu và đọc hai hồ sơ', () async {
      await repository.saveProfile(
        createProfile(id: 'user-khanh', name: 'Vũ Tuấn Khanh'),
      );

      await repository.saveProfile(
        createProfile(id: 'user-demo', name: 'Người dùng Demo', day: 2),
      );

      final List<UserProfile> profiles = await repository.listProfiles();

      expect(profiles, hasLength(2));
      expect(
        profiles.map((UserProfile profile) => profile.id),
        containsAll(<String>['user-khanh', 'user-demo']),
      );
    });

    test('cập nhật cùng ID không tạo hồ sơ trùng', () async {
      await repository.saveProfile(
        createProfile(id: 'user-khanh', name: 'Khanh'),
      );

      await repository.saveProfile(
        createProfile(id: 'user-khanh', name: 'Vũ Tuấn Khanh'),
      );

      final List<UserProfile> profiles = await repository.listProfiles();

      expect(profiles, hasLength(1));
      expect(profiles.single.displayName, 'Vũ Tuấn Khanh');
    });

    test('chọn và đọc hồ sơ hiện tại', () async {
      await repository.saveProfile(
        createProfile(id: 'user-khanh', name: 'Vũ Tuấn Khanh'),
      );

      await repository.saveProfile(
        createProfile(id: 'user-demo', name: 'Người dùng Demo', day: 2),
      );

      await repository.selectProfile('user-demo');

      final UserProfile? selected = await repository.getSelectedProfile();

      expect(selected, isNotNull);
      expect(selected!.id, 'user-demo');
      expect(selected.displayName, 'Người dùng Demo');
    });

    test('từ chối chọn ID không tồn tại', () async {
      await expectLater(
        repository.selectProfile('missing-user'),
        throwsA(
          isA<AppFailure>().having(
            (AppFailure failure) => failure.code,
            'code',
            AppFailureCode.storage,
          ),
        ),
      );
    });

    test('hồ sơ đã chọn còn sau khi tạo '
        'repository instance mới', () async {
      await repository.saveProfile(
        createProfile(id: 'user-khanh', name: 'Vũ Tuấn Khanh'),
      );

      await repository.selectProfile('user-khanh');

      final PersistentUserRepository reopenedRepository =
          PersistentUserRepository(store: store);

      final UserProfile? selected = await reopenedRepository
          .getSelectedProfile();

      expect(selected, isNotNull);
      expect(selected!.id, 'user-khanh');
    });

    test('từ chối tên hồ sơ chỉ có khoảng trắng', () async {
      final UserProfile invalidProfile = UserProfile(
        id: 'invalid-user',
        displayName: '   ',
        createdAt: DateTime.utc(2026, 11, 2),
      );

      await expectLater(
        repository.saveProfile(invalidProfile),
        throwsA(
          isA<AppFailure>().having(
            (AppFailure failure) => failure.code,
            'code',
            AppFailureCode.storage,
          ),
        ),
      );
    });

    test('getSelectedProfile trả null '
        'khi chưa chọn hồ sơ', () async {
      await repository.saveProfile(
        createProfile(id: 'user-khanh', name: 'Vũ Tuấn Khanh'),
      );

      final UserProfile? selected = await repository.getSelectedProfile();

      expect(selected, isNull);
    });
  });
}
