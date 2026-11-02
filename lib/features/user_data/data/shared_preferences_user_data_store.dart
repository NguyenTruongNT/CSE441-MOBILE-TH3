import 'package:shared_preferences/shared_preferences.dart';

import 'user_data_store.dart';

/// API tối thiểu mà User Data cần từ persistent key-value storage.
///
/// Interface này giúp unit test không phụ thuộc plugin nền tảng.
abstract interface class UserDataPreferencesClient {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);

  Future<void> remove(String key);
}

/// Client thật sử dụng SharedPreferencesAsync.
///
/// SharedPreferencesAsync không giữ cache cục bộ, vì vậy mỗi thao tác đọc
/// lấy giá trị mới nhất từ persistent storage của nền tảng.
class SharedPreferencesAsyncClient implements UserDataPreferencesClient {
  SharedPreferencesAsyncClient({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> getString(String key) {
    return _preferences.getString(key);
  }

  @override
  Future<void> setString(String key, String value) {
    return _preferences.setString(key, value);
  }

  @override
  Future<void> remove(String key) {
    return _preferences.remove(key);
  }
}

/// Persistent implementation của [UserDataStore].
///
/// Toàn bộ tài liệu JSON của module User Data được lưu dưới một key.
/// Schema, migration và validation được xử lý bởi
/// UserDataDocumentManager, không nằm trong store này.
class SharedPreferencesUserDataStore implements UserDataStore {
  SharedPreferencesUserDataStore({
    UserDataPreferencesClient? client,
    this.storageKey = defaultStorageKey,
  }) : _client = client ?? SharedPreferencesAsyncClient();

  static const String defaultStorageKey = 'th3_english_ai.user_data.v1';

  final UserDataPreferencesClient _client;

  /// Cho phép dùng key khác nhau trong test hoặc môi trường riêng.
  final String storageKey;

  @override
  Future<String?> read() {
    return _client.getString(storageKey);
  }

  @override
  Future<void> write(String value) async {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        'value',
        'Dữ liệu JSON không được để trống.',
      );
    }

    await _client.setString(storageKey, value);
  }

  @override
  Future<void> clear() {
    return _client.remove(storageKey);
  }
}
