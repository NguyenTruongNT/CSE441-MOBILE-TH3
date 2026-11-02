# Chạy bản tích hợp Tiến độ

## Mặc định: dữ liệu và thông báo giả lập

```bash
git switch main
git pull --ff-only origin main
flutter pub get
flutter run -d chrome
```

Android: thay chrome bằng ID từ `flutter devices`. Bản chạy có hai hồ sơ demo, đổi hồ sơ ở đầu trang Tiến độ, dữ liệu và cài đặt tách riêng. Dữ liệu trong bộ nhớ được tạo một lần tại main; reset khi khởi động lại. Nhắc mặc định tắt, bật nhắc chỉ mô phỏng quyền/lịch. Nút cộng phút chỉ xuất hiện với fake repository.

## Dữ liệu giả lập + thông báo thật

```bash
flutter run -d <android-device-id> --dart-define=USE_REAL_NOTIFICATIONS=true
flutter run -d chrome --dart-define=USE_REAL_NOTIFICATIONS=true
```

Bật nhắc học để xin quyền, chọn giờ nhắc hoặc dùng nút thông báo thử. LocalReminderService đã gọi zonedSchedule thật trên Android, dùng múi giờ hồ sơ và lịch không chính xác tuyệt đối để tránh yêu cầu quyền exact alarm. Có thể trễ do cơ chế tiết kiệm pin; không bảo đảm hoạt động sau khi buộc dừng app. Web chỉ nhắc khi trang còn mở và trình duyệt cho phép thông báo.

Quyền POST_NOTIFICATIONS/RECEIVE_BOOT_COMPLETED, receiver phục hồi lịch và Gradle desugaring đã cấu hình. Không cần SCHEDULE_EXACT_ALARM/USE_EXACT_ALARM. Android release của bài tập vẫn dùng debug signing.

## Sơn cập nhật code sửa vào nhánh riêng

Sau khi bản sửa được merge main:

```bash
git fetch origin
git switch son-feature/discipline-progress
git merge origin/main
```

Trường sử dụng main sau khi pull. Không cần lấy nhánh cấu hình cũ. Khi ghép CSDL, truyền UserRepository/LearningRepository/ReminderService vào ProgressPage; không dùng fake làm lưu trữ bền vững. Adapter có thể implement Listenable để báo thay đổi ngay, nếu không dashboard kiểm tra lại mỗi 30 giây và khi app trở về foreground.

Xem [quy tắc, test và cách nghiệm thu thông báo](../discipline/rules-and-reminders.md). Code đã bổ sung đặt lịch/hủy/đổi user, streak 45 ngày và xử lý lỗi, nhưng chưa có bằng chứng nhận thông báo trên Android thật. Không đánh dấu hoàn tất nghiệm thu thiết bị chỉ dựa trên build hoặc mock test.
