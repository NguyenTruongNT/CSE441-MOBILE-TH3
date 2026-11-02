# Khởi tạo và reset module User Data

## 1. Mục đích

Module User Data chịu trách nhiệm quản lý:

- Hồ sơ người học cục bộ.
- Hồ sơ đang được chọn.
- Cài đặt học tập riêng của từng hồ sơ.
- Các phiên luyện phát âm.
- Kết quả phân tích phát âm.
- Phản hồi theo từ và âm vị.
- Lịch sử luyện tập.
- Lưu trữ dữ liệu bền vững trên Android và Web.

Module sử dụng các hợp đồng chung tại:

```text
lib/core/contracts/
```

Mã nguồn module nằm tại:

```text
lib/features/user_data/
```

Bài kiểm thử nằm tại:

```text
test/user_data/
```

Tài liệu module nằm tại:

```text
docs/user_data/
```

## 2. Thành phần module

Module cung cấp các thành phần chính:

```text
UserDataStore
MemoryUserDataStore
SharedPreferencesUserDataStore
SharedPreferencesAsyncClient
UserDataDocument
UserDataDocumentManager
UserDataSerializers
PersistentUserRepository
PersistentLearningRepository
UserDataDemoSeed
ProfilePage
ProfileFormDialog
HistoryPage
PracticeResultDetailPage
```

Vai trò của từng thành phần:

- `UserDataStore`: abstraction đọc, ghi và xóa tài liệu JSON.
- `MemoryUserDataStore`: store trong bộ nhớ cho unit test và demo.
- `SharedPreferencesUserDataStore`: store bền vững cho Android và Web.
- `SharedPreferencesAsyncClient`: client kết nối với plugin `shared_preferences`.
- `UserDataDocumentManager`: quản lý schema, đọc và ghi tài liệu gốc.
- `UserDataSerializers`: chuyển đổi model giữa Dart và JSON.
- `PersistentUserRepository`: triển khai `UserRepository`.
- `PersistentLearningRepository`: triển khai `LearningRepository`.
- `UserDataDemoSeed`: tạo dữ liệu giả lập phục vụ phát triển.
- `ProfilePage`: quản lý hồ sơ người học.
- `HistoryPage`: hiển thị lịch sử của hồ sơ đang chọn.
- `PracticeResultDetailPage`: hiển thị chi tiết kết quả phát âm.

## 3. Dependency

Module sử dụng dependency:

```yaml
shared_preferences: ^2.5.6
```

Dependency được dùng để lưu một chuỗi JSON chứa toàn bộ tài liệu User Data.

Module sử dụng API:

```dart
SharedPreferencesAsync
```

Thay vì API `SharedPreferences` cũ.

`SharedPreferencesAsync` thực hiện các thao tác đọc và ghi bất đồng bộ, không phụ thuộc vào cache cục bộ của API legacy.

## 4. Store abstraction

Repository không phụ thuộc trực tiếp vào plugin `shared_preferences`.

Repository chỉ làm việc với interface:

```dart
abstract interface class UserDataStore {
  Future<String?> read();

  Future<void> write(String value);

  Future<void> clear();
}
```

Nhờ abstraction này:

- Repository có thể dùng store trong bộ nhớ khi test.
- Repository có thể dùng store bền vững khi chạy thật.
- Có thể thay đổi công nghệ lưu trữ mà không sửa nghiệp vụ repository.
- Unit test không cần khởi tạo plugin nền tảng.
- Android và Web dùng chung logic repository.

## 5. Khởi tạo persistent store

Khi chạy ứng dụng thật, tạo store:

```dart
final store = SharedPreferencesUserDataStore();
```

Store sử dụng key mặc định:

```text
th3_english_ai.user_data.v1
```

Key mặc định được định nghĩa tại:

```dart
SharedPreferencesUserDataStore.defaultStorageKey
```

Có thể truyền một key khác:

```dart
final store = SharedPreferencesUserDataStore(
  storageKey: 'th3_english_ai.user_data.development',
);
```

Việc sử dụng key riêng có thể cần thiết cho:

- Môi trường phát triển.
- Môi trường kiểm thử.
- Phiên bản schema khác.
- Tránh ghi đè dữ liệu của môi trường khác.

## 6. Khởi tạo repository thật

Hai repository phải dùng chung một `UserDataStore`.

```dart
final store = SharedPreferencesUserDataStore();

final userRepository = PersistentUserRepository(
  store: store,
);

final learningRepository = PersistentLearningRepository(
  store: store,
);
```

Lý do phải dùng cùng store:

- `UserRepository` lưu hồ sơ và hồ sơ đang chọn.
- `LearningRepository` lưu settings, session và result.
- Hai repository cùng đọc và ghi một tài liệu JSON.
- Việc kiểm tra user tồn tại cần dữ liệu từ cùng store.
- Việc chuyển hồ sơ và đọc lịch sử cần trạng thái nhất quán.

Không tạo hai persistent store với hai `storageKey` khác nhau nếu các repository cần làm việc trên cùng dữ liệu.

## 7. Khởi tạo repository bằng Memory store

Trong unit test hoặc demo độc lập:

```dart
final store = MemoryUserDataStore();

final userRepository = PersistentUserRepository(
  store: store,
);

final learningRepository = PersistentLearningRepository(
  store: store,
);
```

`MemoryUserDataStore` phù hợp cho:

- Unit test.
- Widget test.
- Demo logic repository.
- Phát triển giao diện độc lập.
- Kiểm thử schema và serializer.

`MemoryUserDataStore` không phù hợp để chứng minh dữ liệu còn sau khi tắt và mở lại ứng dụng.

Dữ liệu của memory store mất khi tiến trình kết thúc.

## 8. Khởi tạo dữ liệu demo

Dữ liệu demo phục vụ phát triển giao diện và kiểm thử độc lập.

```dart
await UserDataDemoSeed.seed(
  userRepository: userRepository,
  learningRepository: learningRepository,
);
```

Dữ liệu demo gồm:

- Hai hồ sơ người học.
- Hồ sơ `user-khanh` được chọn mặc định.
- Hai phiên luyện tập cho `user-khanh`.
- Một phiên luyện tập cho `user-demo`.
- `LearningSettings` riêng cho từng hồ sơ.
- Kết quả phát âm mẫu.
- Phản hồi âm vị mẫu.

`UserDataDemoSeed.seed()` kiểm tra danh sách hồ sơ trước khi tạo dữ liệu.

Nếu repository đã có hồ sơ, hàm seed không tạo thêm dữ liệu.

Vì vậy có thể gọi lại hàm seed mà không tạo hồ sơ hoặc session trùng trong quy trình demo thông thường.

Dữ liệu từ `UserDataDemoSeed` phải được ghi rõ là:

```text
Dữ liệu giả lập phục vụ phát triển và demo
```

Dữ liệu demo không phải:

- Kết quả API phát âm thật.
- Bằng chứng đánh giá độ chính xác AI.
- Dữ liệu của người tham gia thử nghiệm.
- Kết quả nghiệm thu module phát âm.

## 9. Khởi tạo có điều kiện

Không nên seed dữ liệu demo mặc định trong bản nghiệm thu nếu cần kiểm tra dữ liệu người dùng thật.

Có thể dùng một cờ môi trường hoặc lựa chọn phát triển:

```dart
const bool enableDemoData = true;

if (enableDemoData) {
  await UserDataDemoSeed.seed(
    userRepository: userRepository,
    learningRepository: learningRepository,
  );
}
```

Trong bản phát hành hoặc bản nghiệm thu dữ liệu thật:

```dart
const bool enableDemoData = false;
```

Không đưa dữ liệu cá nhân hoặc audio thật vào demo seed.

## 10. Tích hợp trang Hồ sơ

Constructor:

```dart
ProfilePage(
  userRepository: userRepository,
)
```

Ví dụ:

```dart
final profilePage = ProfilePage(
  userRepository: userRepository,
);
```

Khi kiểm thử, có thể truyền ID factory và clock cố định:

```dart
final profilePage = ProfilePage(
  userRepository: userRepository,
  idFactory: () => 'user-test',
  clock: () => DateTime.utc(
    2026,
    11,
    2,
  ),
);
```

Trang Hồ sơ hỗ trợ:

- Xem danh sách hồ sơ.
- Tạo hồ sơ mới.
- Sửa tên hiển thị.
- Sửa múi giờ.
- Chọn hồ sơ hiện tại.
- Đánh dấu hồ sơ đang chọn.
- Hiển thị trạng thái rỗng.
- Hiển thị loading.
- Hiển thị thông báo lỗi.
- Kéo xuống để tải lại.
- Giao diện thích ứng Mobile và Web.

Khi tạo hồ sơ mới:

1. Giao diện tạo `UserProfile`.
2. Gọi `UserRepository.saveProfile`.
3. Gọi `UserRepository.selectProfile`.
4. Tải lại danh sách.
5. Hồ sơ mới được đánh dấu là hồ sơ đang chọn.

Khi sửa hồ sơ:

1. Giữ nguyên ID.
2. Giữ nguyên thời gian tạo.
3. Cập nhật tên và múi giờ.
4. Repository cập nhật bản ghi cùng ID.
5. Không tạo hồ sơ trùng.

## 11. Tích hợp trang Lịch sử

Constructor:

```dart
HistoryPage(
  userRepository: userRepository,
  learningRepository: learningRepository,
)
```

Ví dụ:

```dart
final historyPage = HistoryPage(
  userRepository: userRepository,
  learningRepository: learningRepository,
);
```

Khi kiểm thử, có thể truyền clock cố định:

```dart
final historyPage = HistoryPage(
  userRepository: userRepository,
  learningRepository: learningRepository,
  clock: () => DateTime.utc(
    2026,
    11,
    3,
  ),
);
```

Trang Lịch sử hỗ trợ:

- Đọc hồ sơ đang chọn.
- Chỉ hiển thị lịch sử của hồ sơ đang chọn.
- Hiển thị số phiên.
- Hiển thị tổng thời gian luyện.
- Hiển thị điểm trung bình.
- Sắp xếp phiên mới nhất trước.
- Lọc theo khoảng ngày.
- Hiển thị trạng thái phiên.
- Mở chi tiết kết quả phát âm.
- Hiển thị trạng thái chưa chọn hồ sơ.
- Hiển thị trạng thái lịch sử rỗng.
- Giao diện thích ứng Mobile và Web.

Khoảng lịch sử sử dụng quy ước:

```text
[fromUtc, toUtc)
```

Trong đó:

- `fromUtc` được bao gồm.
- `toUtc` không được bao gồm.
- `toUtc` của bộ lọc ngày được chuyển sang đầu ngày kế tiếp.

## 12. Trang chi tiết kết quả

`PracticeResultDetailPage` nhận session và result đã được repository kiểm tra quyền sở hữu:

```dart
PracticeResultDetailPage(
  session: session,
  result: result,
)
```

Trang hiển thị:

- Điểm phát âm tổng.
- Mô tả mức điểm.
- Thời lượng luyện.
- Thời điểm luyện.
- Thời điểm phân tích.
- Session ID.
- Văn bản chuẩn.
- Văn bản nhận dạng.
- Provider.
- Model version.
- Danh sách phản hồi âm vị.
- IPA chuẩn.
- IPA nhận dạng nếu có.
- Điểm âm vị nếu có.
- Gợi ý cải thiện.

Trạng thái âm vị được thể hiện bằng cả:

- Biểu tượng.
- Nội dung chữ.
- Màu sắc.

Giao diện không dùng riêng màu sắc làm dấu hiệu trạng thái.

## 13. Tích hợp vào AppPages

`AppPages` nhận các page thông qua `WidgetBuilder`.

Ví dụ:

```dart
final pages = AppPages(
  history: (_) => HistoryPage(
    userRepository: userRepository,
    learningRepository: learningRepository,
  ),
  profile: (_) => ProfilePage(
    userRepository: userRepository,
  ),
);
```

Sau đó truyền vào ứng dụng:

```dart
EnglishLearningApp(
  pages: pages,
)
```

Ví dụ composition root đầy đủ:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = SharedPreferencesUserDataStore();

  final userRepository = PersistentUserRepository(
    store: store,
  );

  final learningRepository =
      PersistentLearningRepository(
    store: store,
  );

  final pages = AppPages(
    history: (_) => HistoryPage(
      userRepository: userRepository,
      learningRepository: learningRepository,
    ),
    profile: (_) => ProfilePage(
      userRepository: userRepository,
    ),
  );

  runApp(
    EnglishLearningApp(
      pages: pages,
    ),
  );
}
```

Nếu module Discipline và Pronunciation cần repository, nhóm trưởng truyền cùng các instance repository này qua constructor.

Không tạo repository riêng ở mỗi page vì có thể dẫn tới trạng thái không nhất quán.

## 14. Tích hợp với module Discipline

Module Discipline cần:

```dart
ProgressPage(
  userRepository: userRepository,
  learningRepository: learningRepository,
  reminderService: reminderService,
)
```

Khi đổi hồ sơ:

1. `UserRepository.selectProfile` lưu hồ sơ mới.
2. Progress page đọc lại hồ sơ đang chọn.
3. Progress page tải settings của hồ sơ mới.
4. Progress page tải sessions của hồ sơ mới.
5. Không sử dụng cache của hồ sơ cũ.

Các repository phải dùng chung persistent store.

## 15. Tích hợp với module Pronunciation

Module Pronunciation tạo:

- `PracticeSession`
- `PronunciationResult`
- `PhonemeFeedback`

Sau khi phân tích thành công:

```dart
await learningRepository.savePractice(
  session: session,
  result: result,
);
```

Quy tắc:

- Session completed bắt buộc có result.
- Session cancelled không có result.
- Session analysisFailed không có result.
- `result.sessionId` phải khớp `session.id`.
- Cùng session ID và cùng nội dung không tạo bản ghi mới.
- Cùng session ID nhưng nội dung khác bị từ chối.
- Không lưu điểm 0 cho lỗi API hoặc thiếu bằng chứng.

## 16. Đọc cấu trúc dữ liệu đã lưu

Persistent store lưu toàn bộ tài liệu dưới dạng một chuỗi JSON.

Cấu trúc cấp cao:

```json
{
  "schemaVersion": 1,
  "selectedUserId": "user-khanh",
  "users": [],
  "learningSettings": [],
  "practiceSessions": [],
  "pronunciationResults": []
}
```

Không sửa trực tiếp JSON trong plugin storage.

Mọi thao tác phải đi qua:

- `PersistentUserRepository`
- `PersistentLearningRepository`
- `UserDataDocumentManager`
- `UserDataSerializers`

## 17. Reset dữ liệu trong code

Để xóa toàn bộ dữ liệu User Data:

```dart
await store.clear();
```

Sau khi reset:

- Danh sách hồ sơ rỗng.
- `selectedUserId` trở về `null`.
- LearningSettings đã lưu bị xóa.
- Toàn bộ phiên luyện tập bị xóa.
- Toàn bộ kết quả phát âm bị xóa.
- Toàn bộ phản hồi âm vị bị xóa.

Nếu cần tạo lại dữ liệu demo:

```dart
await UserDataDemoSeed.seed(
  userRepository: userRepository,
  learningRepository: learningRepository,
);
```

## 18. Nút reset dùng trong phát triển

Nếu cần tạo nút reset tạm thời trong màn hình phát triển:

```dart
FilledButton(
  onPressed: () async {
    await store.clear();

    await UserDataDemoSeed.seed(
      userRepository: userRepository,
      learningRepository: learningRepository,
    );
  },
  child: const Text(
    'Reset dữ liệu demo',
  ),
)
```

Không đưa nút reset không có xác nhận vào bản nghiệm thu chính thức.

Nếu có nút reset trong giao diện thật, cần:

- Hộp thoại xác nhận.
- Cảnh báo dữ liệu không thể khôi phục.
- Không đặt nút reset gần thao tác thông thường.
- Không reset âm thầm khi lỗi đọc dữ liệu.
- Không tự động xóa dữ liệu khi schema không tương thích.

## 19. Reset dữ liệu khi kiểm thử Android

Cách 1, dùng chức năng reset của module:

```dart
await store.clear();
```

Cách 2, xóa dữ liệu ứng dụng trong Android Emulator:

```text
Settings
→ Apps
→ English AI
→ Storage & cache
→ Clear storage
```

Cách 3, gỡ ứng dụng khỏi máy ảo rồi cài lại:

```cmd
flutter run -d <device-id>
```

Việc xóa dữ liệu ứng dụng sẽ xóa toàn bộ SharedPreferences của ứng dụng, không chỉ dữ liệu User Data.

## 20. Reset dữ liệu khi kiểm thử Web

Dữ liệu Web được lưu trong storage của trình duyệt thông qua plugin.

Có thể reset bằng code:

```dart
await store.clear();
```

Hoặc xóa dữ liệu trang trong trình duyệt:

```text
Developer Tools
→ Application
→ Storage
→ Clear site data
```

Việc xóa site data có thể xóa toàn bộ dữ liệu cục bộ của ứng dụng Web.

## 21. Unit test persistent store

`SharedPreferencesAsync` cần plugin nền tảng khi chạy thật.

Để unit test không phụ thuộc plugin, store nhận một client abstraction:

```dart
abstract interface class UserDataPreferencesClient {
  Future<String?> getString(String key);

  Future<void> setString(
    String key,
    String value,
  );

  Future<void> remove(String key);
}
```

Trong ứng dụng thật:

```dart
final store = SharedPreferencesUserDataStore();
```

Store tự tạo:

```dart
SharedPreferencesAsyncClient
```

Trong unit test:

```dart
final fakeClient =
    FakeUserDataPreferencesClient();

final store = SharedPreferencesUserDataStore(
  client: fakeClient,
  storageKey: 'test.user-data',
);
```

Nhiều store dùng cùng fake client có thể mô phỏng việc mở lại repository trong cùng tiến trình test:

```dart
await store.write(json);

final reopenedStore =
    SharedPreferencesUserDataStore(
  client: fakeClient,
  storageKey: 'test.user-data',
);

final restored = await reopenedStore.read();
```

Unit test này xác minh:

- Store dùng đúng key.
- Dữ liệu được ghi.
- Dữ liệu được đọc lại.
- Store mới đọc được dữ liệu đã lưu.
- `clear()` xóa dữ liệu.
- Chuỗi rỗng bị từ chối.
- Các storage key không ghi đè nhau.

Unit test không thay thế kiểm tra thật trên Android và Web.

## 22. Kiểm tra persistence trên Android

Quy trình nghiệm thu:

1. Chạy ứng dụng trên Android.
2. Tạo hồ sơ A.
3. Tạo hồ sơ B.
4. Chọn hồ sơ A.
5. Lưu LearningSettings của A.
6. Lưu session và result cho A.
7. Chuyển sang hồ sơ B.
8. Lưu session và result cho B.
9. Đóng hoàn toàn ứng dụng.
10. Mở lại ứng dụng.
11. Kiểm tra hai hồ sơ vẫn còn.
12. Kiểm tra hồ sơ đang chọn vẫn đúng.
13. Kiểm tra settings vẫn còn.
14. Kiểm tra lịch sử A và B vẫn tách biệt.
15. Lưu lại cùng session ID.
16. Kiểm tra số lượng session không tăng.

Lệnh chạy:

```cmd
flutter devices
flutter run -d <android-device-id>
```

Ví dụ:

```cmd
flutter run -d emulator-5554
```

## 23. Kiểm tra persistence trên Web

Chạy:

```cmd
flutter run -d chrome
```

Quy trình:

1. Tạo hai hồ sơ.
2. Chọn một hồ sơ.
3. Lưu settings và lịch sử.
4. Refresh trang.
5. Kiểm tra dữ liệu vẫn còn.
6. Đóng tab.
7. Mở lại ứng dụng.
8. Kiểm tra dữ liệu vẫn còn.
9. Chuyển hồ sơ.
10. Kiểm tra lịch sử không bị trộn.

Lưu ý:

- Dữ liệu có thể mất nếu người dùng xóa site data.
- Chế độ duyệt riêng tư có thể có chính sách lưu trữ khác.
- Không dùng dữ liệu browser storage làm nơi lưu secret.

## 24. Kiểm tra thủ công trang Hồ sơ

1. Mở trang Hồ sơ.
2. Kiểm tra trạng thái rỗng nếu chưa có dữ liệu.
3. Tạo hồ sơ A.
4. Kiểm tra A được chọn tự động.
5. Tạo hồ sơ B.
6. Chọn hồ sơ B.
7. Kiểm tra B được đánh dấu `Đang chọn`.
8. Sửa tên hồ sơ A.
9. Kiểm tra không tạo hồ sơ trùng.
10. Sửa múi giờ.
11. Refresh hoặc mở lại ứng dụng.
12. Kiểm tra dữ liệu vẫn còn.

## 25. Kiểm tra thủ công trang Lịch sử

1. Chọn hồ sơ A.
2. Mở trang Lịch sử.
3. Kiểm tra chỉ có phiên của A.
4. Kiểm tra phiên mới nhất hiển thị trước.
5. Kiểm tra tổng thời gian luyện.
6. Kiểm tra điểm trung bình.
7. Lọc theo khoảng ngày.
8. Xóa bộ lọc.
9. Mở chi tiết kết quả.
10. Kiểm tra transcript.
11. Kiểm tra provider và model version.
12. Kiểm tra phản hồi âm vị.
13. Chọn hồ sơ B.
14. Mở lại lịch sử.
15. Kiểm tra không còn dữ liệu của A.

## 26. Kiểm tra responsive

Các kích thước tối thiểu:

```text
Mobile: 360 x 800
Tablet: 768 px chiều rộng
Desktop: 1366 x 768
```

Kiểm tra:

- Không có `RenderFlex overflow`.
- Card không bị cắt.
- Nút có thể bấm.
- Danh sách cuộn được.
- Dialog không vượt màn hình.
- Văn bản dài dùng ellipsis khi cần.
- Grid Desktop có chiều cao Card phù hợp.
- NavigationRail hoặc NavigationBar không che nội dung.

## 27. Lệnh chạy kiểm thử

Chạy test module:

```cmd
flutter test test\user_data
```

Chạy analyze:

```cmd
flutter analyze
```

Chạy toàn bộ test:

```cmd
flutter test
```

Chạy test persistent store:

```cmd
flutter test test\user_data\shared_preferences_user_data_store_test.dart
```

Chạy test repository:

```cmd
flutter test test\user_data\user_repository_test.dart
flutter test test\user_data\learning_repository_test.dart
```

Chạy test giao diện:

```cmd
flutter test test\user_data\profile_page_test.dart
flutter test test\user_data\history_page_test.dart
flutter test test\user_data\practice_result_detail_page_test.dart
```

## 28. Xử lý lỗi

Repository chuyển lỗi đọc, ghi, schema và dữ liệu hỏng thành:

```text
AppFailureCode.storage
```

Giao diện phải:

- Hiển thị thông báo dễ hiểu.
- Không hiển thị stack trace cho người dùng.
- Cho phép thử lại khi phù hợp.
- Không tự xóa dữ liệu khi đọc lỗi.
- Không hiển thị secret hoặc dữ liệu nhạy cảm.
- Không ghi đè dữ liệu cũ nếu validation thất bại.

Nếu plugin không khởi tạo:

- Kiểm tra `WidgetsFlutterBinding.ensureInitialized()`.
- Chạy lại `flutter pub get`.
- Khởi động lại ứng dụng, không chỉ hot reload.
- Kiểm tra nền tảng được plugin hỗ trợ.
- Kiểm tra ứng dụng đang chạy trên Android hoặc Web hợp lệ.

## 29. Lưu ý về độ bền dữ liệu

`shared_preferences` phù hợp với dữ liệu cấu hình và lượng JSON nhỏ trong phạm vi bài tập.

Không dùng persistent store này cho:

- Audio dung lượng lớn.
- Video.
- Ảnh.
- Khóa API.
- Token bí mật.
- Dữ liệu cần giao dịch phức tạp.
- Dữ liệu rất lớn.
- Dữ liệu yêu cầu mã hóa bảo mật cao.

Nếu dữ liệu tăng đáng kể, cần đánh giá giải pháp CSDL phù hợp hơn.

## 30. Giới hạn

- Hồ sơ là hồ sơ cục bộ, không phải tài khoản đăng nhập.
- Module không triển khai xác thực.
- Dữ liệu demo không phải kết quả AI thật.
- Module không lưu audio.
- Module không quản lý API secret.
- `shared_preferences` không phải CSDL quan hệ.
- Unit test với fake client không thay thế kiểm thử plugin thật.
- Persistence chỉ được đánh dấu hoàn thành sau khi kiểm tra đóng và mở lại trên Android và Web.
- Không tuyên bố dữ liệu được đồng bộ giữa nhiều thiết bị.
- Không tuyên bố dữ liệu được mã hóa nếu chưa triển khai mã hóa.