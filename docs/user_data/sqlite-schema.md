# Schema SQLite/Drift

CSDL schema version 1, tên `english_ai`. Android dùng SQLite native; web dùng SQLite WASM với lưu trữ bền vững do Drift chọn theo trình duyệt. Không đồng bộ đám mây và không phải hệ thống xác thực tài khoản.

| Bảng | Khóa và dữ liệu |
|---|---|
| users | PK id; display_name, time_zone, created_at UTC |
| settings | PK/FK user_id → users; mục tiêu phút, bật nhắc, giờ/phút và múi giờ |
| sessions | PK id; FK user_id → users; bài, bắt đầu/kết thúc UTC, thời lượng chủ động, trạng thái |
| results | PK id; UNIQUE/FK session_id → sessions; câu chuẩn, câu nhận dạng, điểm 0–100, provider, model version, thời gian UTC |
| phoneme_feedback | PK (result_id, position); FK result_id → results; từ, IPA chuẩn/nhận dạng, điểm nullable, trạng thái, mốc thời gian nullable, gợi ý |
| app_state | PK key; value; lựa chọn tài khoản và dấu import dữ liệu cũ |

Index `sessions_user_date(user_id, started_at)` phục vụ lịch sử theo người và ngày. Khóa ngoại được bật khi mở CSDL. Các CHECK ràng buộc trạng thái, điểm, giờ, thời lượng và cặp mốc thời gian.

`savePractice` ghi session, result và phoneme_feedback trong một transaction. Lỗi bất kỳ sẽ rollback toàn bộ. Gửi lại cùng ID và dữ liệu không tạo bản trùng; dữ liệu khác dùng cùng ID bị từ chối. Truy xuất kết quả kiểm tra chủ sở hữu. Các repository phát sự kiện sau ghi để Tiến độ và Lịch sử tải lại.

## Chuyển dữ liệu cũ

`migrateLegacyUserData` đọc schema JSON cũ bằng serializer của Khanh, import trong một transaction và ghi dấu `legacy_import_v1`. Bản SharedPreferences gốc được giữ nguyên. Không tự xóa/reset khi dữ liệu cũ không đọc được; màn hình tài khoản báo lỗi để người dùng thử lại.

Tài khoản có sẵn và lịch sử cũ được giữ. Bốn tài khoản demo được bổ sung nếu chưa có. Chọn tài khoản là cơ chế phân tách dữ liệu demo, không cung cấp kiểm soát truy cập an toàn với người có quyền trên thiết bị.

## Kiểm chứng

`test/user_data/learning_database_test.dart` kiểm tra SQLite thật trong bộ nhớ: roundtrip feedback, retry idempotent, từ chối truy cập chéo, rollback khi trùng result ID, ghi đồng thời, đăng xuất giữ lịch sử và import dữ liệu cũ một lần. Test trình duyệt/thiết bị mở lại là bước nghiệm thu riêng.
