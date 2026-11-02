import 'dart:convert';

import '../../../core/contracts/contracts.dart';
import 'user_data_store.dart';

const int currentUserDataSchemaVersion = 1;

const String defaultTimeZone = 'Asia/Ho_Chi_Minh';

/// Tài liệu gốc được lưu bởi module User Data.
class UserDataDocument {
  UserDataDocument({
    required this.schemaVersion,
    required this.selectedUserId,
    required this.users,
    required this.learningSettings,
    required this.practiceSessions,
    required this.pronunciationResults,
  });

  factory UserDataDocument.empty() {
    return UserDataDocument(
      schemaVersion: currentUserDataSchemaVersion,
      selectedUserId: null,
      users: <Map<String, Object?>>[],
      learningSettings: <Map<String, Object?>>[],
      practiceSessions: <Map<String, Object?>>[],
      pronunciationResults: <Map<String, Object?>>[],
    );
  }

  final int schemaVersion;
  String? selectedUserId;

  final List<Map<String, Object?>> users;
  final List<Map<String, Object?>> learningSettings;
  final List<Map<String, Object?>> practiceSessions;
  final List<Map<String, Object?>> pronunciationResults;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'selectedUserId': selectedUserId,
      'users': users,
      'learningSettings': learningSettings,
      'practiceSessions': practiceSessions,
      'pronunciationResults': pronunciationResults,
    };
  }

  String encode() => jsonEncode(toJson());
}

/// Đọc, kiểm tra và ghi tài liệu dữ liệu gốc.
class UserDataDocumentManager {
  const UserDataDocumentManager(this.store);

  final UserDataStore store;

  Future<UserDataDocument> read() async {
    final String? rawValue;

    try {
      rawValue = await store.read();
    } catch (error) {
      throw AppFailure(
        AppFailureCode.storage,
        'Không thể đọc dữ liệu người dùng: $error',
      );
    }

    if (rawValue == null || rawValue.trim().isEmpty) {
      return UserDataDocument.empty();
    }

    try {
      final Object? decoded = jsonDecode(rawValue);

      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Tài liệu gốc phải là một JSON object.');
      }

      return _decodeDocument(decoded);
    } on AppFailure {
      rethrow;
    } catch (error) {
      throw AppFailure(
        AppFailureCode.storage,
        'Dữ liệu người dùng không hợp lệ: $error',
      );
    }
  }

  Future<void> write(UserDataDocument document) async {
    if (document.schemaVersion != currentUserDataSchemaVersion) {
      throw AppFailure(
        AppFailureCode.storage,
        'Không thể ghi schema version ${document.schemaVersion}.',
      );
    }

    try {
      await store.write(document.encode());
    } catch (error) {
      throw AppFailure(
        AppFailureCode.storage,
        'Không thể ghi dữ liệu người dùng: $error',
      );
    }
  }

  Future<void> clear() async {
    try {
      await store.clear();
    } catch (error) {
      throw AppFailure(
        AppFailureCode.storage,
        'Không thể xóa dữ liệu người dùng: $error',
      );
    }
  }

  UserDataDocument _decodeDocument(Map<String, Object?> json) {
    final Object? rawVersion = json['schemaVersion'];

    if (rawVersion is! int) {
      throw const AppFailure(
        AppFailureCode.storage,
        'Dữ liệu thiếu schemaVersion hợp lệ.',
      );
    }

    if (rawVersion > currentUserDataSchemaVersion) {
      throw AppFailure(
        AppFailureCode.storage,
        'Dữ liệu được tạo bởi schema mới hơn: $rawVersion.',
      );
    }

    final Map<String, Object?> migratedJson = _migrate(json, rawVersion);

    return UserDataDocument(
      schemaVersion: currentUserDataSchemaVersion,
      selectedUserId: migratedJson['selectedUserId'] as String?,
      users: _readObjectList(migratedJson, 'users'),
      learningSettings: _readObjectList(migratedJson, 'learningSettings'),
      practiceSessions: _readObjectList(migratedJson, 'practiceSessions'),
      pronunciationResults: _readObjectList(
        migratedJson,
        'pronunciationResults',
      ),
    );
  }

  Map<String, Object?> _migrate(
    Map<String, Object?> source,
    int sourceVersion,
  ) {
    if (sourceVersion == currentUserDataSchemaVersion) {
      return source;
    }

    // Hiện tại chỉ có schema v1.
    // Các migration tương lai sẽ được thêm tuần tự tại đây.
    throw AppFailure(
      AppFailureCode.storage,
      'Chưa hỗ trợ migration từ schema $sourceVersion.',
    );
  }

  List<Map<String, Object?>> _readObjectList(
    Map<String, Object?> json,
    String key,
  ) {
    final Object? rawValue = json[key];

    if (rawValue == null) {
      return <Map<String, Object?>>[];
    }

    if (rawValue is! List<Object?>) {
      throw AppFailure(
        AppFailureCode.storage,
        'Trường "$key" phải là danh sách.',
      );
    }

    return rawValue.map((Object? item) {
      if (item is! Map<String, Object?>) {
        throw AppFailure(
          AppFailureCode.storage,
          'Mỗi phần tử trong "$key" phải là JSON object.',
        );
      }

      return Map<String, Object?>.from(item);
    }).toList();
  }
}
