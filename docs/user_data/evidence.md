# Minh chứng nghiệm thu module User Data

## 1. Thông tin chung

Học phần:

```text
CSE441 - Phát triển ứng dụng cho các thiết bị di động
```

Lớp:

```text
65KTPM
```

Nhóm:

```text
Nhóm 12
```

Thành viên phụ trách:

```text
Vũ Tuấn Khanh
```

Nhánh triển khai:

```text
khanh-feature/user-data
```

Phạm vi mã nguồn:

```text
lib/features/user_data/
```

Phạm vi kiểm thử:

```text
test/user_data/
```

Phạm vi tài liệu:

```text
docs/user_data/
```

Phạm vi ảnh minh chứng:

```text
screenshots/user_data/
```

Dependency lưu trữ:

```text
shared_preferences: ^2.5.6
```

Persistent store:

```text
SharedPreferencesUserDataStore
SharedPreferencesAsyncClient
```

## 2. Mục tiêu nghiệm thu

Module User Data chịu trách nhiệm:

- Tạo và cập nhật hồ sơ người học.
- Chọn hồ sơ đang hoạt động.
- Lưu hồ sơ đang chọn.
- Tách dữ liệu học tập theo từng hồ sơ.
- Lưu cài đặt học tập theo hồ sơ.
- Lưu phiên luyện tập và kết quả phát âm.
- Chống lưu trùng theo `sessionId`.
- Truy vấn lịch sử theo người dùng và khoảng thời gian.
- Kiểm tra quyền sở hữu trước khi trả kết quả.
- Lưu dữ liệu bền vững trên Android và Web.
- Hiển thị giao diện Hồ sơ, Lịch sử và Chi tiết kết quả.
- Hỗ trợ giao diện thích ứng Mobile và Desktop Web.

## 3. Thành phần đã triển khai

### 3.1 Lưu trữ

```text
UserDataStore
MemoryUserDataStore
SharedPreferencesUserDataStore
SharedPreferencesAsyncClient
UserDataPreferencesClient
```

### 3.2 Schema và serializer

```text
UserDataDocument
UserDataDocumentManager
UserDataSerializers
```

### 3.3 Repository

```text
PersistentUserRepository
PersistentLearningRepository
```

### 3.4 Giao diện

```text
ProfilePage
ProfileFormDialog
HistoryPage
PracticeResultDetailPage
```

### 3.5 Dữ liệu demo

```text
UserDataDemoSeed
```

Dữ liệu demo chỉ dùng để phát triển và kiểm thử độc lập, không phải kết quả AI thật.

## 4. Minh chứng Web

Thư mục:

```text
screenshots/user_data/web/
```

### 4.1 Trang Tiến độ yêu cầu chọn hồ sơ

Ảnh:

```text
screenshots/user_data/web/01_progress_requires_profile_web.png
```

Nội dung xác minh:

- `ProgressPage` đã sử dụng `UserRepository` thật.
- Khi chưa có hồ sơ được chọn, ứng dụng không tự dùng người dùng giả.
- Trang Tiến độ yêu cầu tạo hoặc chọn hồ sơ trước khi đọc dữ liệu.
- Thông báo lỗi nghiệp vụ được hiển thị rõ ràng.
- Có tùy chọn thử tải lại dữ liệu.

### 4.2 Trạng thái Hồ sơ rỗng

Ảnh:

```text
screenshots/user_data/web/02_profile_empty_web.png
```

Nội dung xác minh:

- `ProfilePage` đã thay thế trang chờ tích hợp.
- Trang hiển thị trạng thái chưa có hồ sơ.
- Người dùng có thể tạo hồ sơ đầu tiên.
- Giao diện hiển thị đúng trên Web.

### 4.3 Hộp thoại tạo hồ sơ

Ảnh:

```text
screenshots/user_data/web/03_create_profile_dialog_web.png
```

Nội dung xác minh:

- Hộp thoại có trường tên hiển thị.
- Hộp thoại có trường múi giờ.
- Múi giờ mặc định là `Asia/Ho_Chi_Minh`.
- Có nút hủy và tạo hồ sơ.
- Biểu mẫu có validation cho dữ liệu bắt buộc.

### 4.4 Hồ sơ đầu tiên được chọn

Ảnh:

```text
screenshots/user_data/web/04_first_profile_selected_web.png
```

Nội dung xác minh:

- Hồ sơ được lưu vào repository.
- Hồ sơ mới được chọn tự động.
- Trạng thái `Đang chọn` được hiển thị.
- Giao diện hiển thị tên, múi giờ và ngày tạo.

### 4.5 Hai hồ sơ riêng biệt

Ảnh:

```text
screenshots/user_data/web/05_two_profiles_web.png
```

Nội dung xác minh:

- Tạo được ít nhất hai hồ sơ.
- Hồ sơ mới không ghi đè hồ sơ cũ.
- Chỉ có một hồ sơ mang trạng thái `Đang chọn`.
- Hồ sơ còn lại có thao tác `Chọn`.
- Mỗi hồ sơ có thao tác chỉnh sửa.

### 4.6 Chuyển hồ sơ đang chọn

Ảnh:

```text
screenshots/user_data/web/06_switch_selected_profile_web.png
```

Nội dung xác minh:

- `UserRepository.selectProfile()` hoạt động.
- Trạng thái đang chọn được chuyển sang đúng hồ sơ.
- Giao diện tải lại trạng thái từ repository.
- Không tạo thêm hồ sơ khi thực hiện thao tác chọn.

### 4.7 Hộp thoại chỉnh sửa hồ sơ

Ảnh:

```text
screenshots/user_data/web/07_edit_profile_dialog_web.png
```

Nội dung xác minh:

- Biểu mẫu chỉnh sửa hiển thị dữ liệu hiện có.
- Có thể sửa tên hiển thị.
- Có thể sửa múi giờ.
- ID và ngày tạo của hồ sơ không bị thay đổi.

### 4.8 Hồ sơ sau khi cập nhật

Ảnh:

```text
screenshots/user_data/web/08_profile_updated_web.png
```

Nội dung xác minh:

- Tên hồ sơ được cập nhật.
- Cập nhật cùng ID không tạo bản ghi trùng.
- Tổng số hồ sơ không tăng sau khi chỉnh sửa.
- Trạng thái hồ sơ đang chọn được giữ đúng.

### 4.9 Dữ liệu còn sau khi refresh Web

Ảnh:

```text
screenshots/user_data/web/09_profiles_after_refresh_web.png
```

Nội dung xác minh:

- Danh sách hồ sơ vẫn còn sau khi nhấn `Ctrl + R`.
- Hồ sơ đã chỉnh sửa vẫn giữ nội dung mới.
- Hồ sơ đang chọn vẫn được đánh dấu đúng.
- Dữ liệu không chỉ tồn tại trong state của widget.

### 4.10 Dữ liệu còn sau khi chạy lại Web

Ảnh:

```text
screenshots/user_data/web/10_profiles_after_relaunch_web.png
```

Nội dung xác minh:

- Ứng dụng Web đã được dừng và chạy lại.
- Hai hồ sơ vẫn tồn tại sau khi ứng dụng chạy lại.
- Hồ sơ đang chọn vẫn đúng.
- `SharedPreferencesUserDataStore` hoạt động trên Web.

### 4.11 Trang Lịch sử của hồ sơ đã chọn

Ảnh:

```text
screenshots/user_data/web/11_empty_history_selected_profile_web.png
```

Nội dung xác minh:

- `HistoryPage` đã thay thế trang chờ tích hợp.
- Trang đọc đúng hồ sơ đang chọn.
- Hiển thị số phiên.
- Hiển thị thời gian luyện.
- Hiển thị điểm trung bình.
- Trạng thái lịch sử rỗng được xử lý.
- Không tự dựng kết quả AI khi chưa có session thật.

### 4.12 Trang Tiến độ sau khi chọn hồ sơ

Ảnh:

```text
screenshots/user_data/web/12_progress_after_profile_selected_web.png
```

Nội dung xác minh:

- Module Discipline nhận `UserRepository` thật.
- Module Discipline nhận `LearningRepository` thật.
- Trang Tiến độ đọc dữ liệu của hồ sơ đang chọn.
- Thông báo yêu cầu chọn hồ sơ không còn xuất hiện.
- Dữ liệu mặc định của hồ sơ được tải đúng.

## 5. Minh chứng Android

Thư mục:

```text
screenshots/user_data/android/
```

### 5.1 Trạng thái Hồ sơ rỗng trên Android

Ảnh:

```text
screenshots/user_data/android/01_profile_empty_android.png
```

Nội dung xác minh:

- `ProfilePage` chạy được trên Android.
- Trạng thái rỗng hiển thị đúng.
- Giao diện không bị tràn ở màn hình Mobile.

### 5.2 Tạo hồ sơ trên Android

Ảnh:

```text
screenshots/user_data/android/02_create_profile_android.png
```

Nội dung xác minh:

- Hộp thoại tạo hồ sơ hoạt động trên Android.
- Text field nhận dữ liệu.
- Múi giờ được nhập và lưu.
- Nút tạo hồ sơ có thể thao tác.

### 5.3 Hai hồ sơ trên Android

Ảnh:

```text
screenshots/user_data/android/03_two_profiles_android.png
```

Nội dung xác minh:

- Tạo được hai hồ sơ trên Android.
- Danh sách hiển thị theo chiều dọc.
- Card hồ sơ không bị cắt hoặc tràn.
- Nút chọn và chỉnh sửa thao tác được.

### 5.4 Hồ sơ đang chọn trên Android

Ảnh:

```text
screenshots/user_data/android/04_selected_profile_android.png
```

Nội dung xác minh:

- Chuyển hồ sơ đang chọn thành công.
- Chỉ một hồ sơ có trạng thái `Đang chọn`.
- Trạng thái repository và giao diện thống nhất.

### 5.5 Dữ liệu còn sau khi chạy lại Android

Ảnh:

```text
screenshots/user_data/android/05_profiles_after_relaunch_android.png
```

Nội dung xác minh:

- Ứng dụng đã được dừng hoàn toàn.
- Không xóa ứng dụng hoặc Clear Storage.
- Ứng dụng được chạy lại bằng `flutter run`.
- Hai hồ sơ vẫn còn.
- Hồ sơ đang chọn vẫn đúng.
- `SharedPreferencesUserDataStore` hoạt động trên Android.

### 5.6 Trang Lịch sử Android

Ảnh:

```text
screenshots/user_data/android/06_history_android.png
```

Nội dung xác minh:

- `HistoryPage` chạy được trên Android.
- Trang hiển thị hồ sơ đang chọn.
- Trạng thái lịch sử rỗng hiển thị đúng.
- Giao diện không tràn.
- Bộ lọc ngày hiển thị và thao tác được.

### 5.7 Trang Tiến độ Android

Ảnh:

```text
screenshots/user_data/android/07_progress_selected_profile_android.png
```

Nội dung xác minh:

- Trang Tiến độ sử dụng hồ sơ thật từ module User Data.
- Cài đặt mặc định được đọc từ `LearningRepository`.
- Giao diện Mobile hoạt động sau khi tích hợp repository thật.

## 6. Minh chứng kiểm thử tự động

Thư mục:

```text
screenshots/user_data/tests/
```

### 6.1 Test module User Data

Ảnh:

```text
screenshots/user_data/tests/01_user_data_tests_passed.png
```

Lệnh:

```text
flutter test test/user_data
```

Nội dung xác minh:

- Unit test repository đạt.
- Unit test schema và serializer đạt.
- Widget test giao diện đạt.
- Test persistent store đạt.
- Test responsive đạt.

### 6.2 Flutter Analyze

Ảnh:

```text
screenshots/user_data/tests/02_flutter_analyze_passed.png
```

Lệnh:

```text
flutter analyze
```

Kết quả yêu cầu:

```text
No issues found!
```

### 6.3 Toàn bộ test dự án

Ảnh:

```text
screenshots/user_data/tests/03_all_project_tests_passed.png
```

Lệnh:

```text
flutter test
```

Nội dung xác minh:

- Test User Data đạt.
- Test Discipline đạt.
- Test tích hợp hiện có không bị ảnh hưởng.
- Thay đổi module không làm hỏng chức năng của thành viên khác.

### 6.4 Test persistent store

Ảnh:

```text
screenshots/user_data/tests/04_persistent_store_tests_passed.png
```

Lệnh:

```text
flutter test test/user_data/shared_preferences_user_data_store_test.dart
```

Nội dung xác minh:

- Store trả `null` khi chưa có dữ liệu.
- Store ghi và đọc lại JSON.
- Store instance mới đọc lại dữ liệu đã lưu.
- `clear()` xóa dữ liệu.
- Chuỗi rỗng bị từ chối.
- Các storage key không ghi đè nhau.

## 7. Minh chứng repository

### 7.1 UserRepository

Các chức năng đã kiểm thử:

- Danh sách hồ sơ ban đầu rỗng.
- Lưu hồ sơ mới.
- Lưu hai hồ sơ.
- Cập nhật hồ sơ theo ID.
- Cập nhật không tạo bản ghi trùng.
- Chọn hồ sơ.
- Đọc hồ sơ đang chọn.
- Từ chối ID không tồn tại.
- Từ chối tên rỗng.
- Hồ sơ được giữ khi tạo repository mới trên cùng store.

### 7.2 LearningRepository

Các chức năng đã kiểm thử:

- Lưu `PracticeSession` completed cùng `PronunciationResult`.
- Completed không có result bị từ chối.
- Cancelled hoặc analysisFailed có result bị từ chối.
- `result.sessionId` không khớp `session.id` bị từ chối.
- Cùng session ID và cùng nội dung không tạo bản ghi trùng.
- Cùng session ID nhưng khác nội dung bị từ chối.
- Lịch sử được tách theo `userId`.
- User khác không được đọc result.
- Settings được lưu riêng theo user.
- Settings mặc định đúng hợp đồng.
- Truy vấn khoảng `[fromUtc, toUtc)`.
- Phiên mới nhất được trả trước.

## 8. Minh chứng idempotency

Quy tắc được kiểm tra:

### Trường hợp hợp lệ

```text
Cùng session ID
Cùng nội dung session
Cùng nội dung result
```

Kết quả:

```text
Không tạo bản ghi mới
Không ghi đè dữ liệu
Không báo lỗi
```

### Trường hợp xung đột

```text
Cùng session ID
Nội dung session hoặc result khác
```

Kết quả:

```text
AppFailureCode.storage
Dữ liệu cũ không bị ghi đè
Không tạo bản ghi mới
```

## 9. Minh chứng tách dữ liệu người dùng

Quy trình kiểm tra:

1. Tạo hồ sơ A.
2. Tạo hồ sơ B.
3. Lưu session của A.
4. Lưu session của B.
5. Chọn hồ sơ A.
6. Mở trang Lịch sử.
7. Chỉ phiên của A được hiển thị.
8. Chọn hồ sơ B.
9. Mở trang Lịch sử.
10. Chỉ phiên của B được hiển thị.
11. User B không thể gọi `getResult` cho session của A.

Kết quả:

```text
Dữ liệu được tách theo userId
Không làm lộ result của user khác
```

## 10. Minh chứng responsive

Các kích thước đã kiểm thử tự động:

```text
Mobile: 360 x 800
Desktop: 1366 x 768
```

Các màn hình đã kiểm tra:

- ProfilePage.
- ProfileFormDialog.
- HistoryPage.
- PracticeResultDetailPage.

Kết quả:

- Không có `RenderFlex overflow`.
- Card không bị cắt.
- Danh sách cuộn được.
- Nút thao tác có thể sử dụng.
- Văn bản dài dùng ellipsis khi phù hợp.
- Grid Desktop có chiều cao ổn định.
- Danh sách Mobile tự tính chiều cao theo nội dung.

## 11. Minh chứng lưu trữ bền vững

### Web

Các ca đã kiểm tra:

- Tạo hai hồ sơ.
- Chọn hồ sơ.
- Refresh trang.
- Hồ sơ vẫn còn.
- Hồ sơ đang chọn vẫn đúng.
- Dừng và chạy lại ứng dụng Web.
- Hồ sơ vẫn còn sau khi chạy lại.

Kết quả:

```text
Persistence Web: Đạt
```

### Android

Các ca đã kiểm tra:

- Tạo hai hồ sơ.
- Chọn hồ sơ.
- Dừng ứng dụng bằng lệnh `q`.
- Không gỡ ứng dụng.
- Không Clear Storage.
- Chạy lại ứng dụng.
- Hồ sơ vẫn còn.
- Hồ sơ đang chọn vẫn đúng.

Kết quả:

```text
Persistence Android: Đạt
```

## 12. Kết quả nghiệm thu

### Repository và dữ liệu

- [x] Có schema version 1.
- [x] Có serializer đầy đủ.
- [x] Có UserRepository.
- [x] Có LearningRepository.
- [x] Có lưu hồ sơ.
- [x] Có lưu selected profile.
- [x] Có lưu LearningSettings.
- [x] Có lưu PracticeSession.
- [x] Có lưu PronunciationResult.
- [x] Có lưu PhonemeFeedback.
- [x] Có idempotency theo session ID.
- [x] Có kiểm tra quyền sở hữu.
- [x] Có tách dữ liệu theo user.

### Giao diện

- [x] Có trang Hồ sơ.
- [x] Có hộp thoại tạo hồ sơ.
- [x] Có chỉnh sửa hồ sơ.
- [x] Có chọn hồ sơ.
- [x] Có trang Lịch sử.
- [x] Có bộ lọc ngày.
- [x] Có trang Chi tiết kết quả.
- [x] Có trạng thái loading.
- [x] Có trạng thái rỗng.
- [x] Có trạng thái lỗi.
- [x] Giao diện Mobile không tràn.
- [x] Giao diện Desktop không tràn.

### Persistence

- [x] Đã thêm `shared_preferences`.
- [x] Đã triển khai `SharedPreferencesUserDataStore`.
- [x] Đã dùng `SharedPreferencesAsync`.
- [x] Unit test persistent store đạt.
- [x] Dữ liệu còn sau refresh Web.
- [x] Dữ liệu còn sau khi chạy lại Web.
- [x] Dữ liệu còn sau khi chạy lại Android.
- [x] Selected profile còn sau khi chạy lại.

### Kiểm thử

- [x] Test module User Data đạt.
- [x] Flutter analyze không lỗi.
- [x] Toàn bộ test dự án đạt.
- [x] Test responsive Mobile đạt.
- [x] Test responsive Desktop đạt.
- [x] Test ownership đạt.
- [x] Test idempotency đạt.
- [x] Test persistent store đạt.

### Tài liệu và bàn giao

- [x] Có tài liệu schema.
- [x] Có hướng dẫn setup và reset.
- [x] Có tài liệu kiểm thử.
- [x] Có tài liệu minh chứng.
- [x] Có ảnh Web.
- [x] Có ảnh Android.
- [x] Có ảnh kết quả test.
- [ ] Đã tạo Pull Request.
- [ ] Nhóm trưởng đã review.
- [ ] Nhóm trưởng đã merge.

## 13. Lệnh tái kiểm tra

Cài dependency:

```cmd
flutter pub get
```

Phân tích mã:

```cmd
flutter analyze
```

Test module User Data:

```cmd
flutter test test\user_data
```

Test persistent store:

```cmd
flutter test test\user_data\shared_preferences_user_data_store_test.dart
```

Test toàn bộ dự án:

```cmd
flutter test
```

Chạy Web:

```cmd
flutter run -d chrome
```

Liệt kê emulator:

```cmd
flutter emulators
```

Khởi động emulator:

```cmd
flutter emulators --launch Pixel_5
```

Liệt kê thiết bị:

```cmd
flutter devices --device-timeout 60
```

Chạy Android:

```cmd
flutter run -d emulator-5554
```

ID Android phải được thay bằng ID thực tế từ `flutter devices`.

## 14. File và thư mục bàn giao

```text
lib/features/user_data/
test/user_data/
docs/user_data/
screenshots/user_data/
lib/main.dart
pubspec.yaml
pubspec.lock
```

Các file tài liệu:

```text
docs/user_data/schema.md
docs/user_data/setup-and-reset.md
docs/user_data/testing.md
docs/user_data/evidence.md
```

Các thư mục ảnh:

```text
screenshots/user_data/web/
screenshots/user_data/android/
screenshots/user_data/tests/
```

## 15. Giới hạn

- Hồ sơ là hồ sơ cục bộ, không phải tài khoản đăng nhập.
- Module không triển khai xác thực người dùng.
- Dữ liệu không đồng bộ giữa nhiều thiết bị.
- Dữ liệu không được tuyên bố là đã mã hóa.
- Không lưu khóa API trong SharedPreferences.
- Không lưu audio, ảnh hoặc video trong SharedPreferences.
- Dữ liệu demo không phải kết quả AI thật.
- Lịch sử thật phụ thuộc module phát âm gọi `savePractice`.
- `shared_preferences` phù hợp với dữ liệu JSON nhỏ trong phạm vi bài tập.
- Nếu dữ liệu tăng lớn, cần chuyển sang giải pháp CSDL phù hợp hơn.
- Unit test fake client không thay thế kiểm tra plugin thật.
- Persistence chỉ được đánh dấu hoàn thành sau kiểm tra thực tế trên Web và Android.

## 16. Kết luận

Module User Data đã hoàn thành các yêu cầu chính:

- Quản lý nhiều hồ sơ cục bộ.
- Lưu hồ sơ đang chọn.
- Tách dữ liệu theo người dùng.
- Lưu settings, session và result.
- Chống lưu trùng.
- Kiểm tra quyền sở hữu.
- Hiển thị giao diện Hồ sơ và Lịch sử.
- Hiển thị chi tiết kết quả phát âm.
- Hỗ trợ Android và Web.
- Lưu dữ liệu bền vững bằng `SharedPreferencesAsync`.
- Có unit test, widget test và kiểm thử tích hợp thủ công.
- Có tài liệu và ảnh minh chứng bàn giao.
