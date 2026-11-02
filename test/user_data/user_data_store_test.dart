import 'package:flutter_test/flutter_test.dart';

import 'package:th3_english_ai/features/user_data/data/user_data_schema.dart';
import 'package:th3_english_ai/features/user_data/data/user_data_store.dart';

void main() {
  group('MemoryUserDataStore', () {
    test('trả null khi chưa có dữ liệu', () async {
      final MemoryUserDataStore store = MemoryUserDataStore();

      expect(await store.read(), isNull);
    });

    test('ghi và đọc lại chuỗi JSON', () async {
      final MemoryUserDataStore store = MemoryUserDataStore();

      await store.write('{"schemaVersion":1}');

      expect(await store.read(), '{"schemaVersion":1}');
    });

    test('clear xóa dữ liệu', () async {
      final MemoryUserDataStore store = MemoryUserDataStore(
        initialValue: '{"schemaVersion":1}',
      );

      await store.clear();

      expect(await store.read(), isNull);
    });
  });

  group('UserDataDocumentManager', () {
    test('trả tài liệu rỗng khi store chưa có dữ liệu', () async {
      final MemoryUserDataStore store = MemoryUserDataStore();

      final UserDataDocumentManager manager = UserDataDocumentManager(store);

      final UserDataDocument document = await manager.read();

      expect(document.schemaVersion, currentUserDataSchemaVersion);
      expect(document.selectedUserId, isNull);
      expect(document.users, isEmpty);
      expect(document.learningSettings, isEmpty);
      expect(document.practiceSessions, isEmpty);
      expect(document.pronunciationResults, isEmpty);
    });

    test('ghi và mở lại tài liệu', () async {
      final MemoryUserDataStore store = MemoryUserDataStore();

      final UserDataDocumentManager firstManager = UserDataDocumentManager(
        store,
      );

      final UserDataDocument document = UserDataDocument.empty();

      document.users.add(<String, Object?>{
        'id': 'user-001',
        'displayName': 'Khanh',
        'timeZone': 'Asia/Ho_Chi_Minh',
        'createdAt': '2026-11-02T08:00:00.000Z',
      });

      document.selectedUserId = 'user-001';

      await firstManager.write(document);

      final UserDataDocumentManager secondManager = UserDataDocumentManager(
        store,
      );

      final UserDataDocument reopened = await secondManager.read();

      expect(reopened.selectedUserId, 'user-001');
      expect(reopened.users, hasLength(1));
      expect(reopened.users.single['displayName'], 'Khanh');
    });
  });
}
