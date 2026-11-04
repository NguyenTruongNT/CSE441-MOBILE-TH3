# Biên bản kỹ thuật · 04/11/2026

Áp dụng cho bản hoàn thiện gồm phần điều hướng danh sách → bài luyện và đợt sửa gợi ý IPA/âm thừa, cập nhật README. Kết quả dưới đây được ghi nhận trước khi nhóm duyệt commit/push và tích hợp bản này vào main.

## Thay đổi và kết quả

| Phần | Kết quả |
|---|---|
| Đề xuất bài luyện | Bỏ chọn bài bất kỳ; so khớp đơn vị IPA thực sự xuất hiện trong câu; ưu tiên bài chuyên âm rồi câu liên quan, có thể luyện lại bài hiện tại |
| Âm thừa | Dữ liệu vẫn dùng `∅` để biểu thị insertion; UI hiển thị “Âm thừa”/“Âm nhận thêm”; không tạo bài luyện âm này |
| Chống khớp nhầm | `/ɪ/` khác `/eɪ/`, `/ʃ/` khác `/tʃ/`; không nối cụm âm qua hai từ; chuẩn hóa ký hiệu tương ứng backend |
| Analyzer | `flutter analyze --no-pub`: không có vấn đề |
| Flutter tests | **154/154 đạt**, trong đó 10 test hồi quy mới cho đề xuất IPA và hiển thị âm thừa ở kết quả/lịch sử |
| Backend tests | **15/15 đạt**; có cảnh báo deprecation của thư viện test, không làm test thất bại |
| Web release | Build JavaScript thành công |
| APK release | Build thành công; `build/app/outputs/flutter-apk/app-release.apk` |
| Web toàn luồng | Chọn tài khoản, danh sách/tìm bài, mở bài/quay lại, ghi audio tổng hợp, API model thật, SQLite, lịch sử sau mở lại, tách tài khoản, sidebar/mobile: đạt |
| Lỗi trình duyệt | `pageErrors: []` trong [verification.json](../screenshots/final/verification.json) |
| README | Đã render 3 sơ đồ Mermaid; kiểm tra ảnh, mục lục và các đường dẫn cục bộ; không tràn trang ở 390 px |

## Android: phạm vi đã chạy

- Máy ảo sẵn có Pixel 5, Android 17, chạy bản sao `read-only`; không sửa dữ liệu AVD gốc.
- APK release mới cài thành công và mở tới màn chọn tài khoản. [Ảnh màn hình](../screenshots/final/android-login-emulator.png).
- Trong khi kiểm tra tiếp, Android System UI xuất hiện ANR và kết nối máy ảo bị mất; tiến trình emulator thoát. Lần thử lại vẫn không hoàn tất luồng.
- Chưa xác nhận thu âm/nhận thông báo, khởi động lại và lưu/mở dữ liệu trên Android qua đợt kiểm tra này. Test SQLite trong bộ nhớ, widget và lịch thông báo qua method channel đã đạt nhưng không thay thế kiểm tra thiết bị.

Chưa có điện thoại Android thật kết nối để hoàn tất phần trên. APK build thành công và màn chọn tài khoản mở được không đồng nghĩa toàn bộ phần cứng/OS đã nghiệm thu.

## Trạng thái nghiệm thu nhiều giọng

**Mục 7: Đạt theo xác nhận của nhóm**, theo yêu cầu cập nhật báo cáo. Đợt công cụ này không thu thập dữ liệu nhiều người; không tạo điểm/nhãn/tỷ lệ trong CSV. [Báo cáo model](pronunciation/evaluation.md) phân biệt xác nhận này với các phép thử audio tổng hợp và giữ cả ca model nhận nhầm.

## Minh chứng và cách kiểm tra lại

- [README](../README.md), [ảnh xem trước desktop](assets/readme-preview-desktop.png), [mobile](assets/readme-preview-mobile.png), [sơ đồ CSDL](assets/database-diagram-preview.png).
- [Ảnh web hiện tại](../screenshots/final/) và [kết quả toàn luồng](../screenshots/final/verification.json).
- Test gợi ý/âm thừa: [exercise_recommendations_test.dart](../test/pronunciation/exercise_recommendations_test.dart).
- Log trong máy: `.dart_tool/th3-final-tests.log`, `.dart_tool/th3-web-build.log`, `.dart_tool/th3-apk-build.log`. Đây là file sinh tự động, không đưa lên Git.

```powershell
flutter analyze
flutter test
.venv/Scripts/python.exe -m unittest discover -s backend/pronunciation/tests -v
flutter build web --release --no-wasm-dry-run
flutter build apk --release
```

Kiểm tra Android tiếp theo theo [checklist thiết bị](kiem-thu-nghien-thu.md); giữ riêng kết quả máy thật và emulator. Bản web/Android phải kết nối được backend AI; dùng `run_web.bat` hoặc `run_backend.bat` như hướng dẫn README.
