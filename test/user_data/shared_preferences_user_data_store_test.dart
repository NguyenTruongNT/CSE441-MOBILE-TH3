import 'package:flutter_test/flutter_test.dart';

import 'package:th3_english_ai/features/user_data/data/shared_preferences_user_data_store.dart';

void main() {
  const String storageKey = 'test.th3_english_ai.user_data.v1';

  late FakeUserDataPreferencesClient client;
  late SharedPreferencesUserDataStore store;

  setUp(() {
    client = FakeUserDataPreferencesClient();

    store = SharedPreferencesUserDataStore(
      client: client,
      storageKey: storageKey,
    );
  });

  test('trả null khi chưa có dữ liệu', () async {
    expect(await store.read(), isNull);
  });

  test('ghi và đọc lại JSON', () async {
    const String json = '{"schemaVersion":1,"users":[]}';

    await store.write(json);

    expect(await store.read(), json);

    expect(client.values[storageKey], json);
  });

  test('dữ liệu còn khi tạo store instance mới', () async {
    const String json = '{"schemaVersion":1,"selectedUserId":"user-a"}';

    await store.write(json);

    final SharedPreferencesUserDataStore reopenedStore =
        SharedPreferencesUserDataStore(client: client, storageKey: storageKey);

    expect(await reopenedStore.read(), json);
  });

  test('clear xóa dữ liệu đã lưu', () async {
    await store.write('{"schemaVersion":1}');

    expect(client.values.containsKey(storageKey), isTrue);

    await store.clear();

    expect(await store.read(), isNull);

    expect(client.values.containsKey(storageKey), isFalse);
  });

  test('từ chối chuỗi rỗng', () async {
    await expectLater(store.write('   '), throwsArgumentError);

    expect(client.values, isEmpty);
  });

  test('các storage key không ghi đè nhau', () async {
    final SharedPreferencesUserDataStore firstStore =
        SharedPreferencesUserDataStore(
          client: client,
          storageKey: 'user-data.first',
        );

    final SharedPreferencesUserDataStore secondStore =
        SharedPreferencesUserDataStore(
          client: client,
          storageKey: 'user-data.second',
        );

    await firstStore.write('{"schemaVersion":1,"value":"first"}');

    await secondStore.write('{"schemaVersion":1,"value":"second"}');

    expect(await firstStore.read(), '{"schemaVersion":1,"value":"first"}');

    expect(await secondStore.read(), '{"schemaVersion":1,"value":"second"}');
  });
}

/// Fake client chỉ dùng trong unit test.
///
/// Fake này mô phỏng persistent key-value storage trong cùng một tiến trình.
/// Nhiều store dùng cùng client sẽ đọc lại được cùng dữ liệu.
class FakeUserDataPreferencesClient implements UserDataPreferencesClient {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> getString(String key) async {
    return values[key];
  }

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}
