# Review phần bàn giao của Sơn — 02/11/2026

PR: https://github.com/NguyenTruongNT/CSE441-MOBILE-TH3/pull/4

Nhánh: `son-feature/discipline-progress`, commit `a8d80047744f122eaafd4a83855f1c4e916001a4`.
Đối chiếu với `origin/main` tại `d4a0ac7` và phân công trong README.

## Kết luận

**Bản sửa tiếp theo theo yêu cầu Trường:** nhánh `truong-fix/discipline-completion` đã bổ sung đặt lịch Android, đổi hồ sơ, streak không giới hạn 30 ngày, múi giờ IANA và cập nhật khi qua ngày. Đã có 46 test toàn dự án đạt. Báo cáo này giữ nguyên kết quả review commit Sơn ban đầu; trạng thái mới và phần nghiệm thu thiết bị còn lại xem `../discipline/rules-and-reminders.md`.

**Cập nhật sau review:** nhóm đã thống nhất dùng thêm dữ liệu giả lập. Nhánh `truong-fix/discipline-demo-config` bổ sung cấu hình Android, chạy fake mặc định có nhãn, và chặn demo ghi vào dữ liệu thật. Xem `demo-setup.md` để dùng bản sửa. Các nhận xét/kết quả bên dưới ghi nhận commit Sơn ban đầu, không phải kết quả kiểm tra bản sửa.

Chưa đạt nghiệm thu toàn bộ. Chưa merge PR vào main vì chức năng nhắc Android chưa được triển khai thực sự. Không đánh dấu Sơn hoàn thành chỉ dựa trên các test hiện có.

## Đối chiếu nhiệm vụ

| Nhiệm vụ | Kết quả review |
| --- | --- |
| Dashboard ngày/7 ngày, mục tiêu, streak | Có giao diện và calculator; test cơ bản đạt. Dashboard chỉ truy vấn 30 ngày nên streak dài hơn bị cắt. |
| Repository theo hợp đồng, fake độc lập | Có constructor nhận repository và fake. Entry point hiện chạy fake trong bộ nhớ; chưa chứng minh dữ liệu thật/lưu mở lại. Đây là phần cần phối hợp tích hợp với Khanh/Trường. |
| Xin quyền, bật/tắt, chọn giờ | Có giao diện và đường gọi xin quyền. Chưa có test quyền bị từ chối hoặc thay đổi giờ với adapter thật. |
| Đặt/hủy/lên lịch lại Android, tránh trùng | Chưa đạt: `LocalReminderService.scheduleDaily` chỉ gọi cancel rồi debugPrint, không gọi API đặt lịch. Manifest thiếu receiver cho lịch và khởi động lại; Gradle chưa bật core library desugaring mà plugin yêu cầu. |
| Đổi hồ sơ | Chưa đạt: tải lại hồ sơ không hủy lịch hồ sơ cũ; không lên lịch hồ sơ mới. Chưa có test chuyển giữa hai user. |
| Web | Có thông báo trình duyệt và timer khi trang mở; có ghi giới hạn web. Timer dùng giờ máy thay vì múi giờ hồ sơ; chưa kiểm chứng thực tế trong trình duyệt. |
| Cùng ngày/liên tiếp/bỏ ngày/nửa đêm | Có 7 test calculator đạt. Chưa có test dashboard tự cập nhật khi qua nửa đêm mà không refresh. |
| Thay mục tiêu/giờ nhắc | Có test đổi mục tiêu bằng fake. Chưa có test đổi giờ/hủy lịch cũ với adapter thật. |
| Tài liệu công thức và minh chứng | Có `docs/discipline/rules-and-reminders.md`. Mô tả Android đã đặt lịch không khớp code; 5 test reminder chỉ kiểm tra FakeReminderService. Chưa có minh chứng nhận thông báo thật Android, chạy nền/khởi động lại. |
| Phạm vi sửa file | Có sửa thêm main.dart, pubspec.yaml/lock và AndroidManifest.xml vốn do Trường quản lý. Cần review tích hợp các file chung. ProgressPage cũng import app/shared, ngoài ranh giới chỉ module và core/contracts đã thống nhất. |

## Các điểm cần sửa trước merge

1. Triển khai đặt lịch Android thực sự theo múi giờ hồ sơ, cấu hình Gradle/receiver, báo lỗi khi không đặt được lịch; kiểm tra hủy/đổi giờ/tránh trùng và sau khởi động lại trên Android.
2. Hủy nhắc user cũ khi đổi hồ sơ, tải/lên lịch user mới; thêm test hai hồ sơ và quyền bị từ chối.
3. Không giới hạn dữ liệu tính streak ở 30 ngày; bổ sung trường hợp 31+ ngày và cập nhật qua nửa đêm.
4. Tách rõ demo khỏi dữ liệu thật. `DemoSimulationBar` hiện có thể ghi phiên giả vào repository thật khi được inject; không dùng các phiên mô phỏng làm minh chứng thời gian luyện thực tế.
5. Sửa tài liệu theo thực trạng và bổ sung test adapter thật (mock plugin/platform), minh chứng Android. Test fake không xác nhận hệ điều hành đã nhận lịch.

## Kiểm tra chạy lại

- `flutter analyze`: đạt, không có issue.
- `flutter test`: 32/32 đạt (18 test discipline và 14 test nền).
- `flutter build web --release`: đạt, tạo `build/web`.
- `flutter build apk --release`: thất bại tại `:app:checkReleaseAarMetadata`: dependency `:flutter_local_notifications` yêu cầu bật core library desugaring cho `:app`. Đây là lỗi build của nhánh được review, không phải kết luận từ test fake.

Không chỉnh sửa module thay Sơn và không gửi thông báo cho thành viên trong phiên review này.
