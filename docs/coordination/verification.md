# Kiểm tra khung ứng dụng của Trường

Phạm vi: khung độc lập, chưa ghép module nghiệp vụ của Khanh/Đăng/Sơn. Kết quả này không xác nhận đủ 7 checklist hoặc chất lượng AI.

## Kết quả đã chạy

- Dart SDK hiện có: 3.13.2.
- `dart analyze lib test`: đạt, không có lỗi/cảnh báo.
- `flutter test --no-pub`: **14/14 test đạt**.
- Kiểm tra điều hướng ở 320/360/768/800/1366px: đạt trong widget test.
- Chữ phóng lớn 2 lần với viewport 360×640: không ghi nhận lỗi layout trong test.
- Inject bốn trang và giữ state khi đổi tab: đạt.
- Kiểm tra đầu vào hợp đồng, UTC và bytes audio bất biến: đạt.

Widget test chạy bằng Flutter test engine, không phải bản ghi kiểm thử Android/Chrome thực tế. Chưa có ảnh/video giao diện thực tế trong đợt này.

## Build và môi trường

- `flutter build web --release --no-pub`: **đạt**, tạo `build/web/`. Wasm dry run cũng đạt; đây vẫn là build web mặc định, chưa phải kiểm thử ứng dụng Wasm trên trình duyệt.
- `flutter build apk --release --no-pub`: **đạt**, tạo `build/app/outputs/flutter-apk/app-release.apk` (khoảng 42.8 MB theo Flutter). APK dùng debug signing có sẵn; chưa cài/chạy trên Android thực tế.
- Build Android có cảnh báo SDK XML giữa phiên bản công cụ, nhưng Gradle kết thúc với exit code 0. Không thay cấu hình SDK chỉ để che cảnh báo.

SDK nằm ngoài workspace nên trong môi trường công cụ cần quyền truy cập Flutter cache; đây là giới hạn môi trường chạy, không phải yêu cầu thay đổi mã dự án.

## Chưa nghiệm thu

- Micro/API thật, phân tích âm vị và điểm AI.
- CSDL, chuyển hồ sơ, lịch sử bền vững.
- Streak/mục tiêu, quyền và nhận thông báo trên Android.
- Luồng toàn bộ, nhiều người dùng/giọng nói, browser/device thật.
- Bản build tích hợp cuối và đóng gói nộp bài.

Các mục này được giao cụ thể trong `truong-tasks.md`. Không đánh dấu hoàn thành khi chưa nhận module và chạy thực tế.
