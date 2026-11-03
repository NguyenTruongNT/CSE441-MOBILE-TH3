# TH3 — English AI · Nhóm 12

Ứng dụng Flutter học tiếng Anh, theo dõi kỷ luật luyện tập và phân tích phát âm. CSE441 · 65KTPM · Nhóm 12.

**Đang bổ sung theo rà soát ngày 03/11/2026. Chưa đủ điều kiện đánh dấu hoàn thành 7/7 mục.** Tài khoản demo, SQLite, tiến độ và giao diện đã được bổ sung. Mô hình AI cụ thể đang chờ người dùng chốt; backend heuristic cũ bị chặn trả điểm vì chưa phân tích âm vị thật. Chưa có kết quả thử nhiều giọng hoặc nghiệm thu thông báo/micro trên Android thật.

## Bắt đầu

Cần Flutter/Dart thỏa `sdk: ^3.13.2`, Android SDK cho bản Android, Chrome cho web.

```powershell
flutter pub get
flutter run -d chrome --web-port 7357
```

Chọn một tài khoản **Học viên 1–4** để vào. Không có thao tác tạo hồ sơ trong luồng chính. Tài khoản cũ đã lưu được import sang SQLite và vẫn có thể chọn. Chế độ demo không có xác thực mật khẩu; dữ liệu được lưu riêng theo tài khoản trên từng thiết bị, không đồng bộ giữa các máy.

- [Hướng dẫn thao tác trong ứng dụng](docs/huong-dan-su-dung.md)
- [Đối chiếu 7 mục và nhiệm vụ từng thành viên](docs/doi-chieu-th3.md)
- [Bộ thử người thật và thiết bị](docs/kiem-thu-nghien-thu.md)
- [Biểu mẫu 40 phiên, chưa có số liệu điền trước](docs/pronunciation/evaluation-results.csv)
- [Schema SQLite và chuyển dữ liệu](docs/user_data/sqlite-schema.md)

## Backend phát âm

Người dùng đã chọn mô hình mã nguồn mở, chấp nhận tải model/tài nguyên máy. Đang chờ chốt đề xuất Wav2Vec2Phoneme trước khi tích hợp. Không dùng transcript giống câu chuẩn để kết luận âm vị đúng, không tự sinh điểm khi backend lỗi.

Backend cũ có thể mở bằng lệnh sau để kiểm tra health/API lỗi, nhưng **chưa trả kết quả chấm điểm**:

```powershell
dart run backend/pronunciation/bin/server.dart
```

Cấu hình endpoint Flutter qua `PRONUNCIATION_API_URL` sau khi backend mới sẵn sàng:

```powershell
flutter run -d chrome --web-port 7357 --dart-define=PRONUNCIATION_API_URL=http://127.0.0.1:8080/api/pronounce/analyze
```

Android emulator dùng mặc định `http://10.0.2.2:8080/api/pronounce/analyze`. Điện thoại Android nối USB có thể dùng:

```powershell
adb reverse tcp:8080 tcp:8080
flutter run -d <device-id> --dart-define=PRONUNCIATION_API_URL=http://127.0.0.1:8080/api/pronounce/analyze
```

Nếu chạy qua mạng, dùng endpoint HTTPS mà điện thoại truy cập được. Web truy cập từ máy khác cần HTTPS để dùng micro. Không đặt API key bí mật vào Flutter.

## Dữ liệu và thông báo

SQLite/Drift có các bảng `users`, `settings`, `sessions`, `results`, `phoneme_feedback`, `app_state`; ghi phiên/kết quả trong cùng giao dịch. Bản JSON cũ được import một lần và giữ nguyên bản gốc. Đăng xuất xóa lựa chọn tài khoản, không xóa lịch sử; khi mở lại ứng dụng cần chọn tài khoản.

Android sử dụng recorder PCM/WAV 16kHz và TTS nền tảng; web sử dụng MediaRecorder và TTS trình duyệt. Cần kiểm tra audio thật trên từng thiết bị.

Thông báo dùng adapter thật mặc định. Android đặt lịch lặp với OS; web chỉ nhắc khi tab đang mở. Quyền thông báo, pin và trạng thái ứng dụng ảnh hưởng giờ nhận; cần nghiệm thu trên máy thật.

Web đóng gói `web/sqlite3.wasm` và `web/drift_worker.dart.js` từ release Drift 2.35.3. Máy chủ phải phục vụ WASM với MIME `application/wasm`. Dùng cùng origin/cổng để giữ đúng CSDL; không nghiệm thu lưu bền vững trong tab ẩn danh.

## Kiểm tra và build

```powershell
flutter analyze
flutter test
flutter build web --release
flutter build apk --release
```

Test/build không thay thế kiểm thử giọng thật, micro và thông báo. APK tại `build/app/outputs/flutter-apk/app-release.apk`; web tại `build/web/`. Chỉ dùng bản build mới nhất sau khi kiểm tra thay đổi.

## Thành viên và phạm vi kế thừa

| Thành viên | Phạm vi |
|---|---|
| Nguyễn Văn Trường | Điều phối, hợp đồng, khung ứng dụng, review/merge và tích hợp |
| Vũ Tuấn Khanh | Người dùng, lưu trữ, lịch sử và dữ liệu |
| Vũ Hải Đăng | Bài luyện, thu âm, nhận dạng, phân tích phát âm và phản hồi |
| Lý Đình Sơn | Mục tiêu, streak, thống kê và nhắc học |

Đợt bổ sung hiện tại kế thừa module của từng thành viên và ghi rõ phần sửa thêm, việc chờ nghiệm thu trong [bảng đối chiếu](docs/doi-chieu-th3.md). Không sử dụng số liệu chưa xác minh trong tài liệu đánh giá cũ làm minh chứng nộp bài.
