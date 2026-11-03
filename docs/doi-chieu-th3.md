# Đối chiếu TH3 và nhiệm vụ từng thành viên

Ngày rà soát: 03/11/2026. Nhánh bổ sung: `truong-feature/th3-completion`.

## Các lựa chọn đã được người dùng chốt

- Chọn tài khoản demo có sẵn, có đăng xuất; không tạo hồ sơ trong luồng chính.
- Android và web; CSDL SQLite/Drift cục bộ, có bảng/giao dịch, không đồng bộ giữa thiết bị.
- Giao diện sáng, thẻ trắng, điểm nhấn gradient xanh–tím; sidebar desktop, navbar mobile.
- Mô hình mã nguồn mở trên backend; người dùng chấp nhận tải model và tài nguyên máy.
- Người dùng tổ chức kiểm thử ít nhất 4 người, cùng 10 câu; cần chuẩn bị hướng dẫn và biểu mẫu.
- Lựa chọn cụ thể Wav2Vec2Phoneme đang chờ trả lời. Chưa triển khai/tải model khi chưa chốt.

## Checklist giảng viên

| Mục | Kết quả rà soát và phần bổ sung | Trạng thái |
|---|---|---|
| 1. CSDL người dùng, lịch sử, kết quả | Thay JSON bằng SQLite/Drift; bảng users, settings, sessions, results, phoneme_feedback và app_state; khóa ngoại, giao dịch, chống trùng, import dữ liệu cũ giữ bản gốc | Đã triển khai; có test giao dịch/rollback/tách tài khoản và mở web thật |
| 2. Streak, thời gian, mục tiêu | Kế thừa thuật toán Sơn, dùng repository SQLite có thông báo thay đổi; cập nhật sau lưu; không tính thời gian API | Đã triển khai/test; nghiệm thu toàn luồng người thật còn chờ AI |
| 3. Thu âm và speech recognition | Bổ sung Android PCM 16kHz/WAV thật, quyền micro/Internet; web giữ adapter thu âm. Nhận dạng backend mới chờ chốt model | Chưa hoàn tất luồng thật |
| 4. AI so sánh âm vị/chấm điểm | Bỏ fallback sinh điểm khi mất mạng; chặn backend cũ trả điểm dựa transcript; bỏ GOP giả trên UI | Chưa hoàn tất: chờ mô hình, thuật toán và kiểm chứng |
| 5. Điểm, đánh dấu lỗi, bài tập | Kế thừa giao diện và gợi ý của Đăng; sửa responsive và cách diễn đạt; phản hồi thật phụ thuộc mục 4 | Chưa nghiệm thu AI |
| 6. Thông báo và tiến độ | Dùng LocalReminderService mặc định, lưu cài đặt SQLite; Android đặt lịch OS, web giới hạn tab mở | Code/test có; chưa nghiệm thu nhận trên Android thật |
| 7. Nhiều người và giọng | Có bộ 10 câu, 4 tài khoản, CSV 40 phiên trống, cách tính đồng thuận/cảnh báo sai/bỏ lọt; tài liệu số liệu cũ được đánh dấu chưa xác minh | Chờ người thật thực hiện; không điền số liệu giả |

## Đối chiếu cá nhân

| Thành viên | Phần kế thừa | Phần bổ sung trong đợt này | Việc còn phải nghiệm thu |
|---|---|---|---|
| Nguyễn Văn Trường | Hợp đồng, khung điều hướng, theme, tích hợp module | Luồng vào/đăng xuất tài khoản, theme xanh–tím, sidebar/navbar, tích hợp SQLite, sửa build Kotlin, kiểm tra responsive, tài liệu thao tác và bảng đối chiếu | Ghép mô hình đã chọn; kiểm tra toàn luồng trên thiết bị và chuẩn bị bản nộp |
| Vũ Tuấn Khanh | Model/schema JSON, repository, kiểm tra dữ liệu, Hồ sơ/Lịch sử và test lưu trữ | SQLite có giao dịch/khóa ngoại/index; import dữ liệu cũ; tài khoản demo thay tạo hồ sơ; Lịch sử lắng nghe cập nhật | Kiểm tra lưu/mở lại trên Android thật; các ca dữ liệu với phiên AI thật |
| Vũ Hải Đăng | 16 bài, giao diện luyện, web recorder/STT/TTS, backend và bộ test ban đầu | Android recorder/TTS thật, endpoint cấu hình, bỏ fallback/điểm GOP giả, chặn heuristic cũ, sửa tràn mobile, giữ đúng tài khoản khi lưu | Mô hình âm vị thật; lỗi/giới hạn AI; bộ thử 4 người × 10 câu và số liệu đối chiếu |
| Lý Đình Sơn | Streak, biểu đồ, mục tiêu, adapter thông báo, test quy tắc thời gian | Đồng bộ theme; dùng dữ liệu SQLite có sự kiện thay đổi và thông báo thật mặc định | Nhận nhắc thực tế, đổi giờ/tắt/khởi động lại trên Android; web khi tab mở |

Các bổ sung nêu trên do Trường/Codex thực hiện trong đợt tích hợp, không xem là minh chứng từng thành viên đã tự hoàn thành phần còn thiếu. Không đánh dấu toàn bộ đề tài hoàn thành chỉ vì test/build đạt.

## Kiểm tra đã thực hiện

- `flutter analyze`: đạt ở lượt kiểm tra sau thay đổi tài khoản/SQLite/responsive.
- `flutter test`: 132 test đạt, gồm test import dữ liệu cũ.
- Build web release: đạt (JavaScript); thư viện TTS có cảnh báo dry-run WASM, không công bố ứng dụng Flutter WASM. SQLite WASM là thành phần CSDL riêng.
- Build APK release: đạt, gồm cấu hình mạng cho emulator/adb reverse; đã sửa cache Kotlin khác ổ đĩa và lỗi Android lint XML.
- Chrome thật 1366px/360px: đã mở tài khoản demo, Tiến độ và trang phát âm; SQLite khởi tạo được, không có pageerror ở các bước này.
- Chrome: đổi mục tiêu thành 20 phút, reload trang, chọn lại tài khoản và xác nhận mục tiêu vẫn là 20 phút; ảnh `screenshots/completion/persistence-web.png`.
- Smoke test recorder web bằng thiết bị media tổng hợp của Chrome: nhận WebM/Opus và gửi payload audio; không có pageerror. Đây không phải thử giọng người thật. API được giả lập lỗi 503 để kiểm tra đường lỗi.
- Backend cũ: POST phân tích trả 503 `insufficientEvidence`, không trả điểm khi chưa có mô hình âm vị.
- Không có thiết bị Android kết nối ở lúc rà soát. Chưa có thử nghiệm micro/thông báo thực và chưa có kết quả nhiều giọng cho mô hình mới.

Hướng dẫn: [sử dụng](huong-dan-su-dung.md), [nghiệm thu](kiem-thu-nghien-thu.md).
