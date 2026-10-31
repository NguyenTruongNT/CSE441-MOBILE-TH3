# Ghép module vào khung ứng dụng

## Điểm vào và trách nhiệm

- `lib/main.dart`: chạy `EnglishLearningApp`.
- `lib/app/app.dart`: MaterialApp và theme.
- `lib/app/app_shell.dart`: `AppPages` và điều hướng; dưới 800px dùng navigation bar, từ 800px dùng rail, từ 1100px mở rộng rail.
- `lib/app/shared/app_states.dart`: loading, message và retry dùng chung.
- `lib/core/contracts/contracts.dart`: import chung của model/interface; chi tiết ở `contracts.md`.

Không có module nghiệp vụ thực tế hoặc fake repository dùng trong bản chạy hiện tại. Bốn builder để trống nên ứng dụng hiển thị trang chờ tích hợp.

## Constructor injection

Trường tạo instance adapter tại composition root rồi truyền vào widget qua closure của `AppPages`. Ví dụ dưới đây là mã minh họa, chỉ dùng sau khi các class module được bàn giao và import đúng:

```dart
// users, learning, pronunciation, reminders được khởi tạo một lần ở ngoài build.
runApp(EnglishLearningApp(
  pages: AppPages(
    progress: (_) => ProgressPage(
      userRepository: users,
      learningRepository: learning,
      reminderService: reminders,
    ),
    pronunciation: (_) => PronunciationPage(
      userRepository: users,
      learningRepository: learning,
      pronunciationService: pronunciation,
    ),
    history: (_) => HistoryPage(
      userRepository: users,
      learningRepository: learning,
    ),
    profile: (_) => ProfilePage(
      userRepository: users,
      learningRepository: learning,
      reminderService: reminders,
    ),
  ),
));
```

Đây không phải tên constructor đã được các thành viên xác nhận. Khi nhận module, Trường cập nhật chính xác tên class/import vào composition root, không sửa nội bộ module để ép theo ví dụ.

## Quy tắc vòng đời

- Widget đầu vào là phần nội dung trang; shell đã cung cấp app bar và navigation, tránh thêm thanh điều hướng trùng.
- Mỗi trang tự co giãn theo vùng nội dung được cấp, có scroll khi cần, không dùng chiều rộng cố định bằng toàn màn hình.
- Shell dùng `IndexedStack` để giữ state tab. Không ghi âm, tự gửi API hoặc xin quyền trong `build`/`initState`: tất cả tab có thể được mount ngay lần đầu.
- Ghi âm chỉ khởi động khi người dùng thao tác; phải có dừng/hủy và giải phóng tài nguyên theo vòng đời. Module ghi âm phải xử lý khi app inactive/background và thống nhất cơ chế dừng khi rời tab trước tích hợp thật.
- Tab được giữ state chưa đồng nghĩa dữ liệu được làm mới. Khi đổi hồ sơ hoặc lưu phiên, dùng cơ chế thông báo chung do Trường điều phối để các trang tải lại; không giữ cache user cũ. Cơ chế thông báo dữ liệu sẽ chốt khi nhận API thực tế từ Khanh.
- Nếu adapter khởi tạo bất đồng bộ, composition root hiển thị loading/lỗi trước khi tạo các trang cần adapter; không khởi tạo DB lại mỗi build.

## Checklist nhận module

- [ ] PR chỉ sửa đúng phạm vi và dùng hợp đồng chung.
- [ ] Có widget đầu vào/constructor và hướng dẫn chạy độc lập.
- [ ] Có adapter thực tế, fake test riêng, test và giới hạn đã ghi nhận.
- [ ] Dependency, asset, cấu hình, quyền nền tảng đã liệt kê.
- [ ] Không chứa khóa thật, dữ liệu cá nhân hoặc audio người thử.
- [ ] Analyze/test đạt; nhóm trưởng kiểm tra diff trước merge.
- [ ] Sau ghép, chạy lại khung và luồng liên module trên nền tảng mục tiêu.

## Lệnh kiểm tra

```cmd
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter run -d chrome
flutter devices
flutter run -d <device-id>
flutter build web --release
flutter build apk --release
```

Thay `<device-id>` bằng ID thật. Không commit thư mục `build/`. APK hiện dùng debug signing theo cấu hình Flutter ban đầu; bản release để thử bài tập không phải bản ký phát hành lên store.
