# Kiểm thử module User Data

## 1. Mục tiêu

Bộ kiểm thử xác minh:

- Repository tuân thủ hợp đồng chung.
- Dữ liệu được serialize và deserialize chính xác.
- Hồ sơ được lưu và chọn đúng.
- Dữ liệu được tách riêng theo từng hồ sơ.
- Phiên và kết quả được lưu nguyên tử.
- Không tạo session trùng.
- Lịch sử mới nhất hiển thị trước.
- Giao diện hoạt động trên Mobile và Web.
- Trạng thái phát âm không chỉ được thể hiện bằng màu sắc.

## 2. Lệnh kiểm thử

Chạy riêng module User Data:

```text
flutter test test/user_data
```

Phân tích mã:

```text
flutter analyze
```

Chạy toàn bộ test dự án:

```text
flutter test
```

Chạy một file cụ thể:

```text
flutter test test/user_data/user_repository_test.dart
flutter test test/user_data/learning_repository_test.dart
flutter test test/user_data/profile_page_test.dart
flutter test test/user_data/history_page_test.dart
flutter test test/user_data/practice_result_detail_page_test.dart
```

## 3. Các nhóm test

### 3.1 UserDataStore và schema

File:

```text
test/user_data/user_data_store_test.dart
```

Nội dung kiểm tra:

- Store ban đầu trả về `null`.
- Ghi và đọc chuỗi JSON.
- Xóa dữ liệu.
- Tạo tài liệu schema v1 rỗng.
- Ghi và mở lại tài liệu bằng instance manager mới.
- Dữ liệu JSON giữ đúng hồ sơ được chọn.

### 3.2 Serializer

File:

```text
test/user_data/user_data_serializers_test.dart
```

Nội dung kiểm tra:

- `UserProfile` chuyển đổi JSON hai chiều.
- `LearningSettings` chuyển đổi JSON hai chiều.
- `PracticeSession` chuyển đổi JSON hai chiều.
- `PronunciationResult` chuyển đổi JSON hai chiều.
- Danh sách `PhonemeFeedback` được giữ nguyên.
- DateTime được chuẩn hóa về UTC.
- Enum được lưu bằng `.name`.
- Enum không hợp lệ bị từ chối.
- Dữ liệu sai kiểu tạo lỗi lưu trữ.

### 3.3 UserRepository

File:

```text
test/user_data/user_repository_test.dart
```

Nội dung kiểm tra:

- Danh sách hồ sơ ban đầu rỗng.
- Lưu hai hồ sơ.
- Cập nhật cùng ID không tạo bản ghi trùng.
- Chọn hồ sơ.
- Đọc hồ sơ đang chọn.
- Từ chối ID không tồn tại.
- Hồ sơ đã chọn còn khi tạo repository instance mới trên cùng store.
- Từ chối tên hồ sơ trống.

### 3.4 LearningRepository

File:

```text
test/user_data/learning_repository_test.dart
```

Nội dung kiểm tra:

- Lưu phiên completed cùng kết quả.
- Đọc lại session và result.
- Lưu lại cùng session ID và cùng nội dung không tạo bản ghi trùng.
- Cùng session ID nhưng nội dung khác bị từ chối.
- Completed không có result bị từ chối.
- `result.sessionId` không khớp bị từ chối.
- Cancelled có result bị từ chối.
- Dữ liệu lịch sử được tách theo user.
- User khác không được đọc kết quả.
- Settings mặc định đúng hợp đồng.
- Settings được lưu riêng theo từng user.
- Lịch sử được lọc theo khoảng thời gian.
- Lịch sử được sắp mới nhất trước.
- Khoảng thời gian không hợp lệ bị từ chối.

### 3.5 Demo seed

File:

```text
test/user_data/user_data_demo_seed_test.dart
```

Nội dung kiểm tra:

- Seed tạo hai hồ sơ.
- Hồ sơ Khanh được chọn mặc định.
- Hai user có lịch sử riêng.
- User Khanh có hai phiên.
- User demo có một phiên.
- Gọi seed nhiều lần không tạo dữ liệu trùng.

### 3.6 ProfilePage

File:

```text
test/user_data/profile_page_test.dart
```

Nội dung kiểm tra:

- Hiển thị hai hồ sơ.
- Hiển thị hồ sơ đang chọn.
- Hiển thị trạng thái rỗng.
- Tạo hồ sơ mới.
- Hồ sơ mới được chọn tự động.
- Không cho tạo tên rỗng.
- Chọn hồ sơ khác.
- Sửa hồ sơ không tạo bản ghi trùng.
- Không tràn ở kích thước Mobile 360 px.
- Không tràn ở kích thước Desktop 1366 px.

### 3.7 HistoryPage

File:

```text
test/user_data/history_page_test.dart
```

Nội dung kiểm tra:

- Yêu cầu chọn hồ sơ khi chưa có hồ sơ được chọn.
- Hiển thị trạng thái lịch sử rỗng.
- Chỉ hiển thị lịch sử của hồ sơ đang chọn.
- Không làm lộ dữ liệu của hồ sơ khác.
- Phiên mới nhất hiển thị trước.
- Hiển thị đúng điểm của phiên.
- Mở được trang chi tiết kết quả.
- Không tràn ở kích thước Mobile.
- Không tràn ở kích thước Desktop.

### 3.8 PracticeResultDetailPage

File:

```text
test/user_data/practice_result_detail_page_test.dart
```

Nội dung kiểm tra:

- Hiển thị điểm tổng.
- Hiển thị văn bản chuẩn.
- Hiển thị văn bản nhận dạng.
- Hiển thị provider và model version.
- Hiển thị phản hồi âm vị.
- Hiển thị trạng thái `Đúng`.
- Hiển thị trạng thái `Cần luyện thêm`.
- Hiển thị trạng thái `Chưa đánh giá`.
- Trạng thái có cả biểu tượng và chữ, không chỉ dùng màu.
- Không tràn trên Mobile.
- Không tràn trên Desktop.

## 4. Ca kiểm thử thủ công với hai hồ sơ

### Hồ sơ A

```text
ID: user-khanh
Tên: Vũ Tuấn Khanh
Múi giờ: Asia/Ho_Chi_Minh
```

### Hồ sơ B

```text
ID: user-demo
Tên: Người dùng Demo
Múi giờ: Asia/Ho_Chi_Minh
```

Quy trình:

1. Tạo hoặc seed hai hồ sơ.
2. Chọn hồ sơ A.
3. Xác nhận chỉ thấy lịch sử A.
4. Chọn hồ sơ B.
5. Xác nhận chỉ thấy lịch sử B.
6. Mở kết quả của từng hồ sơ.
7. Xác nhận không thể đọc result của user khác.
8. Lưu lại cùng session ID.
9. Xác nhận số lượng session không tăng.

## 5. Kiểm thử idempotency

Trường hợp 1:

```text
Cùng session ID
Cùng nội dung session
Cùng nội dung result
```

Kết quả mong đợi:

```text
Không tạo bản ghi mới
Không báo lỗi
```

Trường hợp 2:

```text
Cùng session ID
Nội dung session hoặc result khác
```

Kết quả mong đợi:

```text
AppFailureCode.storage
Không ghi đè dữ liệu cũ
```

## 6. Kiểm thử quyền sở hữu

Quy trình:

1. Lưu session cho user A.
2. Lưu result của session A.
3. Gọi `getResult` bằng user B.
4. Repository phải từ chối.
5. Dữ liệu user A không được trả cho user B.

## 7. Kiểm thử responsive

Các kích thước tối thiểu:

```text
Mobile: 360 x 800
Tablet: 768 px chiều rộng
Desktop: 1366 x 768
```

Kiểm tra:

- Không có `RenderFlex overflow`.
- Nút thao tác có thể bấm.
- Nội dung dài dùng ellipsis khi cần.
- Card và danh sách cuộn được.
- Bottom Navigation và NavigationRail không che nội dung.
- Dialog thêm/sửa hồ sơ hiển thị đầy đủ.

## 8. Kiểm thử persistence thực tế

Chỉ nghiệm thu sau khi persistent store được tích hợp.

Quy trình:

1. Chạy ứng dụng.
2. Tạo hai hồ sơ.
3. Chọn một hồ sơ.
4. Lưu settings.
5. Lưu session và result.
6. Đóng hoàn toàn ứng dụng.
7. Mở lại ứng dụng.
8. Xác nhận hồ sơ, selected user, settings, lịch sử và result vẫn còn.
9. Kiểm tra dữ liệu trên Android.
10. Kiểm tra dữ liệu trên Web.

Memory store không được dùng làm bằng chứng cho ca kiểm thử này.

## 9. Kết quả gần nhất

Ngày kiểm tra: 02/11/2026

```text
flutter test test/user_data: 58 test đạt
flutter test: toàn bộ test dự án đạt
flutter analyze: No issues found
```

Persistent storage:

```text
shared_preferences: 2.5.6
SharedPreferencesUserDataStore: đã triển khai
Unit test persistent store: đạt
Web refresh: dữ liệu hồ sơ còn
Web chạy lại: dữ liệu hồ sơ còn
Android chạy lại: dữ liệu hồ sơ còn
Selected profile sau mở lại: còn chính xác
```

Giới hạn:

```text
Hồ sơ là dữ liệu cục bộ, không phải tài khoản đăng nhập.
Lịch sử có dữ liệu thật khi module phát âm gọi savePractice.
Không lưu audio hoặc API secret trong SharedPreferences.
```
```
## 10. Lỗi và giới hạn còn lại

- Persistent store đang chờ dependency lưu trữ được thêm vào mã nguồn chung.
- Hồ sơ là hồ sơ cục bộ, không phải hệ thống đăng nhập.
- Dữ liệu demo không phải kết quả AI thật.
- Chưa tuyên bố persistence hoàn thành nếu chưa kiểm tra đóng và mở lại ứng dụng.
- Không lưu khóa API hoặc audio cá nhân.