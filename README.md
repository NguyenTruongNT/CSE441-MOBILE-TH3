# TH3 — English AI · Nhóm 12

Ứng dụng Flutter học tiếng Anh, theo dõi kỷ luật và phân tích phát âm bằng mô hình mã nguồn mở. CSE441 · 65KTPM · Nhóm 12.

Đã triển khai tài khoản demo, SQLite/Drift, mục tiêu/streak/thống kê/nhắc học, thu âm Android/web, nhận dạng văn bản và âm vị thật trên backend CPU. Giao diện dùng Be Vietnam Pro đóng gói, nền sáng và điểm nhấn xanh–tím; sidebar desktop thu gọn được, mobile có nút micro giữa thanh dưới.

**Chưa công bố hoàn thành nghiệm thu 7/7:** còn bộ thử 4 người × 10 câu và micro/thông báo trên Android thật. Mô hình có thể nhận nhầm; điểm là độ khớp chuỗi âm vị, chưa được hiệu chuẩn bởi chuyên gia. Xem [đối chiếu checklist và thành viên](docs/doi-chieu-th3.md).

## Chạy lần đầu trên Windows

Cần Flutter/Dart thỏa `sdk: ^3.13.2`, Python 3.11+ 64-bit, Chrome; Android SDK nếu chạy Android. Đã chạy mô hình CPU trên máy RAM 16 GB. Lần cài đầu cần Internet và vài GB trống cho thư viện/model; không đưa model vào Git.

Từ thư mục gốc dự án:

```powershell
flutter pub get
powershell -ExecutionPolicy Bypass -File backend/pronunciation/setup_backend.ps1
.\run_backend.bat
```

Chờ backend báo khởi động xong. Mở terminal thứ hai:

```powershell
Invoke-RestMethod http://127.0.0.1:8080/health
flutter run -d chrome --web-port 7357
```

Health cần có `assessmentReady: true`. Chọn **Học viên 1–4 → Luyện nói → Nghe mẫu → Bắt đầu ghi âm → Dừng & Phân tích → Lịch sử**. Backend tải hai model ở revision đã khóa; những lần sau dùng cache tại `backend/pronunciation/.models/`. Hướng dẫn chi tiết: [backend](backend/pronunciation/README.md), [thao tác ứng dụng](docs/huong-dan-su-dung.md).

## Android và địa chỉ API

Emulator dùng mặc định `http://10.0.2.2:8080/api/pronounce/analyze`. Điện thoại nối USB:

```powershell
adb reverse tcp:8080 tcp:8080
flutter run -d <device-id> --dart-define=PRONUNCIATION_API_URL=http://127.0.0.1:8080/api/pronounce/analyze
```

Địa chỉ backend khác cấu hình qua `PRONUNCIATION_API_URL`. Khi đi qua mạng dùng HTTPS; localhost trên điện thoại là chính điện thoại. Web cần localhost hoặc HTTPS để dùng micro. Backend mặc định chỉ lắng nghe localhost; đây là backend demo cục bộ, chưa phải dịch vụ công khai có xác thực.

## Dữ liệu và thông báo

SQLite có bảng `users`, `settings`, `sessions`, `results`, `phoneme_feedback`, `app_state`; ghi phiên/kết quả trong cùng giao dịch. Dữ liệu JSON cũ được import một lần, giữ bản gốc. [Schema và chuyển đổi](docs/user_data/sqlite-schema.md).

Tài khoản demo không có mật khẩu. Mỗi tài khoản có dữ liệu riêng trên thiết bị, không đồng bộ giữa các máy. Đăng xuất giữ lịch sử; mở lại cần chọn tài khoản. Web dùng cùng origin/cổng để mở lại đúng CSDL. Máy chủ web phải phục vụ `sqlite3.wasm` với MIME `application/wasm`.

Android ghi PCM16 WAV 16 kHz, web dùng MediaRecorder; backend chuyển audio sang mono 16 kHz rồi chạy hai mô hình độc lập. Không dùng transcript do client gửi để sinh điểm. Không có fallback điểm mô phỏng trong bản mặc định.

Android dùng thông báo theo lịch hệ điều hành; web chỉ nhắc khi tab đang mở. Cần kiểm tra quyền, pin, giờ nhận và khởi động lại trên thiết bị thật.

## Kiểm tra và build

```powershell
flutter analyze
flutter test
.venv/Scripts/python.exe -m unittest discover -s backend/pronunciation/tests -v
flutter build web --release --no-wasm-dry-run
flutter build apk --release
```

APK: `build/app/outputs/flutter-apk/app-release.apk`; web: `build/web/`. SQLite dùng WASM; bản Flutter web này build JavaScript.

- [Quy trình nghiệm thu và 10 câu cho 4 người](docs/kiem-thu-nghien-thu.md)
- [CSV 40 phiên để điền sau khi đo](docs/pronunciation/evaluation-results.csv)
- [API và thuật toán điểm thực tế](docs/pronunciation/api-and-scoring.md)
- [Báo cáo model, bao gồm ca nhận nhầm](docs/pronunciation/evaluation.md)
- [Ảnh giao diện và kết quả kiểm tra trình duyệt](screenshots/final/)

## Kế thừa và bổ sung

| Thành viên | Phần được kế thừa |
|---|---|
| Nguyễn Văn Trường | Điều phối, hợp đồng dữ liệu, khung app, review và tích hợp |
| Vũ Tuấn Khanh | Model/repository người dùng, dữ liệu và lịch sử |
| Vũ Hải Đăng | 16 bài, màn luyện, recorder/STT/TTS web, phản hồi và gợi ý bài |
| Lý Đình Sơn | Streak, mục tiêu, thống kê, adapter nhắc học |

Phần sửa thêm trong đợt tích hợp được ghi riêng ở [bảng đối chiếu](docs/doi-chieu-th3.md). Giữ bộ test/module cũ để bảo toàn hợp đồng; màn tạo hồ sơ cũ không nằm trong luồng ứng dụng chính. Font Be Vietnam Pro có [giấy phép OFL](assets/fonts/OFL.txt); font dự phòng/IPA có giấy phép [Roboto](assets/fonts/Roboto-OFL.txt) và [Noto Sans](assets/fonts/NotoSans-OFL.txt). Hai model của Meta có giấy phép Apache 2.0 theo model card được dẫn trong tài liệu backend.
