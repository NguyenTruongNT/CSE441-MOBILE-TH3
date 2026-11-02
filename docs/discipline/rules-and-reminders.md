# Kỷ luật và tiến độ — bản tích hợp 02/11/2026

Module ban đầu: Lý Đình Sơn. Trường bổ sung sửa lỗi và tích hợp theo yêu cầu nhóm trưởng. Dữ liệu giả lập được nhóm chấp thuận để phát triển và demo; không thay thế bằng chứng nhận thông báo trên thiết bị thật.

## Dashboard và quy tắc ngày học

- Chỉ tính phiên completed, durationSeconds > 0, đúng user và đã kết thúc; loại phiên hủy/lỗi và dữ liệu tương lai.
- Dùng múi giờ IANA của hồ sơ với thư viện timezone; hỗ trợ UTC và thay đổi DST. Múi giờ không hợp lệ báo lỗi thay vì ngầm dùng UTC+7.
- Gán phiên qua nửa đêm cho ngày bắt đầu. Nhiều phiên/ngày cộng thời lượng nhưng chỉ tính một ngày streak.
- Ngày luyện khác ngày đạt mục tiêu: chỉ cần thời lượng dương để giữ streak. Streak tính lùi từ hôm nay hoặc hôm qua; bỏ từ hai ngày thì về 0.
- Dashboard đọc toàn bộ lịch sử từ repository để không cắt chuỗi ở 30 ngày. Biểu đồ vẫn chỉ hiển thị 7 ngày gần nhất. Truy vấn toàn lịch sử phù hợp phạm vi bài tập; khi dữ liệu lớn cần bổ sung API tổng hợp/phân trang.
- Mục tiêu ngày áp dụng vào biểu đồ 7 ngày theo cài đặt hiện tại; không lưu lịch sử thay đổi mục tiêu ở hợp đồng v1.
- Tự làm mới mỗi 30 giây khi trang còn hoạt động, và khi app trở lại foreground; nhờ đó tiến độ đổi ngày không cần người dùng refresh. Adapter có thể implement Listenable để báo đổi hồ sơ/dữ liệu ngay; adapter không phát tín hiệu vẫn được kiểm tra lại theo chu kỳ.

## Dữ liệu và hồ sơ giả lập

Chạy mặc định bằng `flutter run -d chrome` hoặc thiết bị Android. Có hai hồ sơ mẫu, chọn ngay trên trang Tiến độ. Hồ sơ thứ nhất có lịch sử mẫu theo ngày Việt Nam; hồ sơ thứ hai dùng UTC và lịch sử riêng. Mục tiêu, giờ nhắc và tiến độ tách theo user.

Dữ liệu/cài đặt chỉ ở bộ nhớ, reset khi khởi động lại. Dashboard ghi rõ dữ liệu giả lập. Nút cộng phút chỉ hiện với fake repository và không ghi vào repository thật. FakeReminderService mô phỏng quyền/lịch; không gửi thông báo hệ điều hành. Các phiên demo không phải kết quả luyện phát âm AI.

## Android: adapter thông báo thật

```bash
flutter run -d <android-device-id> --dart-define=USE_REAL_NOTIFICATIONS=true
```

Dữ liệu học vẫn giả lập; service thông báo chuyển sang LocalReminderService. Nhắc mặc định tắt, người dùng phải bật để xin quyền. Nút thông báo thử cũng xin quyền trước khi gửi.

- Khởi tạo plugin, kiểm tra quyền và gọi zonedSchedule với thời điểm kế tiếp theo múi giờ hồ sơ, lặp theo DateTimeComponents.time.
- Dùng inexactAllowWhileIdle, không cần SCHEDULE_EXACT_ALARM/USE_EXACT_ALARM. Android có thể trì hoãn vì tiết kiệm pin; không cam kết đúng từng phút, không bảo đảm hoạt động sau khi bị buộc dừng.
- Dùng ID dành riêng 12001 cho hồ sơ đang chọn; đổi giờ/hồ sơ thay cùng ID, tránh nhiều lịch. Khi chuyển user, hủy lịch cũ trước khi áp dụng cài đặt mới. Khi tắt nhắc, hủy lịch; service mới sau khởi động lại vẫn có thể hủy ID đã lưu trong hệ điều hành.
- Có ScheduledNotificationReceiver/BootReceiver và RECEIVE_BOOT_COMPLETED để plugin phục hồi lịch đã lưu khi khởi động lại máy. Việc lưu cài đặt bền vững trong app còn chờ repository thật của Khanh; bản demo khởi động lại sẽ reset dữ liệu và đồng bộ lại lịch theo hồ sơ demo mặc định.
- Khi từ chối quyền/nền tảng không hỗ trợ, giao diện không lưu trạng thái bật nhắc. Lỗi đặt lịch hiển thị cho người dùng. Không báo thành công thông báo thử nếu quyền bị từ chối hoặc plugin lỗi.
- Khởi tạo/service có giải phóng timer/listener; phản hồi repository sau khi widget dispose không gọi setState.

## Web

Thông báo dùng quyền trình duyệt và HTML Notification. Timer kiểm tra giờ theo múi giờ hồ sơ mỗi 10 giây khi trang còn mở; mỗi user/ngày/phút chỉ gửi một lần trong vòng đời service. Không có Web Push/Service Worker cho nhắc nền khi đóng tab. Trình duyệt có thể giới hạn timer nền; đây không phải cơ chế hẹn giờ nền đáng tin cậy.

## Kiểm thử tự động

```bash
flutter analyze
flutter test
flutter build apk --release
flutter build web --release
```

Toàn dự án có 46 test đạt, gồm 14 test nền và 32 test discipline:

- 7 test calculator gốc: UTC+7, cùng ngày, trạng thái không hợp lệ, liên tiếp/bỏ ngày và phiên qua nửa đêm.
- 5 test FakeReminderService và 6 test giao diện gốc (360/768/800/1366px, mục tiêu, cộng phút demo).
- 7 test service thật qua mock Android method channel: có gọi đặt lịch lặp đúng múi giờ/ngày kế tiếp, cùng ID khi đổi giờ/user, hủy lịch, từ chối quyền, lỗi plugin, hủy sau restart, nền tảng không hỗ trợ; kiểm tra IANA/DST.
- 7 test hồi quy dashboard: streak 45 ngày, đổi user và dữ liệu/cài đặt riêng, chuyển ngày tự động, dispose khi đang tải, quyền denied/unsupported, lỗi đặt lịch không lưu bật nhắc.

Mock channel xác nhận lời gọi tới plugin và xử lý của app, không chứng minh hệ điều hành đã hiển thị thông báo. Chưa có thiết bị Android kết nối trong phiên sửa để nghiệm thu thực tế.

## Nghiệm thu thiết bị còn cần thực hiện

Trên Android thật: bật/từ chối quyền; chọn giờ gần hiện tại; ghi giờ nhận khi app mở/nền; đổi giờ/tắt nhắc/đổi hồ sơ; kiểm tra không nhận lịch cũ; thử khởi động lại thiết bị. Ghi model máy, phiên bản Android và tình trạng tối ưu pin. Trên Chrome: cấp/từ chối quyền, thử thông báo, đổi giờ và đóng tab để xác nhận giới hạn. Không điền kết quả PASS khi chưa đo thực tế.
