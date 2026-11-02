# Khởi tạo và reset module User Data

## 1. Yêu cầu

Module sử dụng các hợp đồng chung tại:

```text
lib/core/contracts/
```

Module cung cấp:

```text
PersistentUserRepository
PersistentLearningRepository
MemoryUserDataStore
UserDataDemoSeed
ProfilePage
HistoryPage
PracticeResultDetailPage
```

## 2. Khởi tạo repository

Trước tiên, tạo một store dùng chung:

```dart
final store = MemoryUserDataStore();
```

Tạo hai repository trên cùng store:

```dart
final userRepository = PersistentUserRepository(
  store: store,
);

final learningRepository = PersistentLearningRepository(
  store: store,
);
```

Hai repository phải dùng cùng một `UserDataStore` để đọc và ghi cùng tài liệu dữ liệu.

## 3. Khởi tạo dữ liệu demo

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
- LearningSettings riêng cho từng hồ sơ.
- Kết quả và phản hồi âm vị mẫu.

`UserDataDemoSeed.seed()` chỉ tạo dữ liệu khi repository chưa có hồ sơ. Gọi lại hàm không tạo dữ liệu trùng.

Dữ liệu demo phải được ghi rõ là dữ liệu giả lập, không phải kết quả AI thật.

## 4. Tích hợp trang Hồ sơ

Constructor:

```dart
ProfilePage(
  userRepository: userRepository,
)
```

Khi cần kiểm thử, có thể truyền ID factory và clock cố định:

```dart
ProfilePage(
  userRepository: userRepository,
  idFactory: () => 'user-test',
  clock: () => DateTime.utc(2026, 11, 2),
)
```

Trang Hồ sơ hỗ trợ:

- Xem danh sách hồ sơ.
- Tạo hồ sơ.
- Sửa tên và múi giờ.
- Chọn hồ sơ hiện tại.
- Trạng thái rỗng.
- Loading và thông báo lỗi.
- Giao diện thích ứng Mobile và Web.

## 5. Tích hợp trang Lịch sử

Constructor:

```dart
HistoryPage(
  userRepository: userRepository,
  learningRepository: learningRepository,
)
```

Trang Lịch sử hỗ trợ:

- Đọc hồ sơ đang chọn.
- Hiển thị lịch sử riêng của hồ sơ.
- Hiển thị số phiên, thời gian luyện và điểm trung bình.
- Lọc theo khoảng ngày.
- Mở chi tiết kết quả phát âm.
- Trạng thái chưa chọn hồ sơ.
- Trạng thái lịch sử rỗng.
- Giao diện thích ứng Mobile và Web.

## 6. Tích hợp vào AppPages

Nhóm trưởng thực hiện tích hợp tại composition root.

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

Sau đó truyền `pages` vào ứng dụng:

```dart
EnglishLearningApp(
  pages: pages,
)
```

Thành viên module User Data không tự sửa `main.dart`, `app.dart` hoặc `app_shell.dart` nếu chưa được nhóm trưởng thống nhất.

## 7. Reset dữ liệu

Để reset dữ liệu khi phát triển hoặc kiểm thử:

```dart
await store.clear();
```

Sau khi reset:

- Danh sách hồ sơ rỗng.
- `selectedUserId` trở về `null`.
- LearningSettings đã lưu bị xóa.
- Toàn bộ phiên luyện tập bị xóa.
- Toàn bộ kết quả phát âm bị xóa.

Nếu cần tạo lại dữ liệu demo:

```dart
await UserDataDemoSeed.seed(
  userRepository: userRepository,
  learningRepository: learningRepository,
);
```

## 8. MemoryUserDataStore

`MemoryUserDataStore` chỉ lưu dữ liệu trong bộ nhớ của tiến trình.

Ưu điểm:

- Không cần dependency nền tảng.
- Phù hợp unit test.
- Phù hợp demo độc lập.
- Có thể tạo instance mới với dữ liệu JSON ban đầu.

Giới hạn:

- Dữ liệu mất khi ứng dụng được khởi động lại.
- Không đáp ứng yêu cầu persistence thực tế.

Không dùng `MemoryUserDataStore` làm bằng chứng dữ liệu còn sau khi đóng và mở lại ứng dụng.

## 9. Persistent store Android và Web

Persistent store phải triển khai interface:

```dart
abstract interface class UserDataStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}
```

Repository không cần thay đổi khi chuyển từ `MemoryUserDataStore` sang persistent store.

Công nghệ lưu trữ phải:

- Hỗ trợ Android.
- Hỗ trợ Web.
- Lưu và đọc đúng chuỗi JSON UTF-8.
- Giữ dữ liệu sau khi đóng và mở lại ứng dụng.
- Không lưu khóa API.
- Chuyển lỗi nền tảng thành `AppFailureCode.storage`.

Dependency và cấu hình dùng chung do nhóm trưởng cập nhật.

## 10. Kiểm tra thủ công

### Hồ sơ

1. Mở trang Hồ sơ.
2. Tạo hồ sơ A.
3. Tạo hồ sơ B.
4. Sửa tên hồ sơ A.
5. Chọn hồ sơ A.
6. Chuyển sang hồ sơ B.
7. Xác nhận hồ sơ đang chọn được đánh dấu đúng.

### Lịch sử

1. Chọn hồ sơ A.
2. Mở trang Lịch sử.
3. Kiểm tra chỉ có phiên của A.
4. Chọn hồ sơ B.
5. Mở lại trang Lịch sử.
6. Kiểm tra không còn dữ liệu của A.
7. Mở chi tiết một kết quả.
8. Kiểm tra điểm, transcript và phản hồi âm vị.

### Persistence

1. Tạo ít nhất hai hồ sơ.
2. Lưu phiên và kết quả.
3. Đóng hoàn toàn ứng dụng.
4. Mở lại ứng dụng.
5. Kiểm tra hồ sơ vẫn còn.
6. Kiểm tra hồ sơ đang chọn vẫn đúng.
7. Kiểm tra lịch sử và settings vẫn còn.
8. Thử lưu lại cùng session ID.
9. Xác nhận không có bản ghi trùng.

## 11. Lệnh chạy kiểm thử

```text
flutter test test/user_data
flutter analyze
flutter test
```

## 12. Lệnh chạy ứng dụng

Web:

```text
flutter run -d chrome
```

Android:

```text
flutter devices
flutter run -d <device-id>
```

Ví dụ:

```text
flutter run -d emulator-5554
```

## 13. Giới hạn

- Đây là hồ sơ cục bộ, không phải đăng nhập.
- Dữ liệu demo không phải kết quả AI thật.
- Memory store không duy trì dữ liệu khi ứng dụng khởi động lại.
- Module không lưu audio.
- Module không quản lý API secret.
- Module không tự thay đổi hợp đồng chung.