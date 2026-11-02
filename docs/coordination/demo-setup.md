# Cấu hình dùng chung cho Trường và Sơn

Nhánh tích hợp: `truong-fix/discipline-demo-config`, dựa trên nhánh Sơn tại `a8d8004`.

## Chạy dữ liệu giả lập

Nhóm thống nhất dùng thêm dữ liệu giả lập để phát triển và demo. Bản chạy mặc định dùng `FakeLearningRepository` và `FakeReminderService`, không cần CSDL, API hay quyền thông báo. Dashboard có nhãn dữ liệu giả lập. Các tab còn lại vẫn chờ tích hợp.

```bash
flutter pub get
flutter run -d chrome
flutter run -d <android-device-id>
```

Repository được tạo một lần ở main và truyền vào ProgressPage. Có dữ liệu mẫu, đổi mục tiêu và nút cộng phút để thử UI. Dữ liệu/cài đặt chỉ lưu trong bộ nhớ và đặt lại khi khởi động lại ứng dụng. Thông báo mặc định được mô phỏng, không gửi tới hệ điều hành. Thanh công cụ mô phỏng chỉ hiện khi dùng fake repository và không ghi phiên giả vào repository thật.

## Thử thông báo hệ thống

Giữ dữ liệu học giả lập nhưng dùng LocalReminderService:

```bash
flutter run -d <android-device-id> --dart-define=USE_REAL_NOTIFICATIONS=true
flutter run -d chrome --dart-define=USE_REAL_NOTIFICATIONS=true
```

Chế độ này dành cho Sơn phát triển/kiểm tra adapter thật. Cần cấp quyền thông báo bằng thao tác trong giao diện. Nút thông báo thử dùng đường gọi thông báo thật; trên web cần trình duyệt hỗ trợ và cấp quyền, nhắc theo timer chỉ hoạt động khi trang còn mở. Android đặt lịch hằng ngày vẫn chưa triển khai trong service tại mốc này; cấu hình build và receiver không thay thế code đặt lịch. Không dùng kết quả fake để kết luận thông báo hệ thống đã hoạt động.

## Cấu hình Android

- Bật `isCoreLibraryDesugaringEnabled` và dependency `desugar_jdk_libs:2.1.4` theo README của plugin được cài.
- Khai báo ScheduledNotificationReceiver và ScheduledNotificationBootReceiver để sẵn sàng cho triển khai lịch/khôi phục lịch.
- Giữ POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED, SCHEDULE_EXACT_ALARM và VIBRATE. Bỏ USE_EXACT_ALARM trùng mục đích; nếu Sơn chọn exact scheduling thì còn phải xử lý quyền tương ứng trong code.
- APK release hiện dùng debug signing của bài tập.

## Dùng chung code

Sơn có thể ghép nhánh sửa cấu hình vào nhánh của mình:

```bash
git fetch origin
git switch son-feature/discipline-progress
git merge origin/truong-fix/discipline-demo-config
```

Trường tiếp tục kiểm tra tích hợp trên `truong-fix/discipline-demo-config`. Chưa merge vào main hoặc đánh dấu hoàn tất phần nhắc Android. Các việc còn lại theo báo cáo `son-review-2026-11-02.md`: lịch Android thật, đổi hồ sơ, streak trên 30 ngày và minh chứng/test bổ sung.

## Kết quả kiểm tra bản sửa — 02/11/2026

- `flutter analyze`: không có issue.
- `flutter test`: 32/32 test đạt.
- `flutter build apk --release`: thành công; APK tại `build/app/outputs/flutter-apk/app-release.apk` (48.0 MB).
- `flutter build web --release`: thành công; đầu ra tại `build/web`.
- Chưa chạy nghiệm thu thông báo hoặc cài APK trên thiết bị thật trong phiên này.
