# Đối chiếu TH3 và nhiệm vụ từng thành viên

Rà soát ngày 03/11/2026 · nhánh `truong-feature/th3-completion`. Phân biệt phần code đã có với nghiệm thu bằng người/thiết bị thật.

## Lựa chọn đã chốt

- Chọn tài khoản demo có sẵn, đăng xuất; không tạo hồ sơ trong luồng chính.
- Android + web; SQLite/Drift cục bộ, có bảng/giao dịch; không đồng bộ giữa thiết bị.
- Nền sáng, thẻ trắng, gradient xanh–tím; Be Vietnam Pro đóng gói, tiêu đề đậm/nội dung thoáng.
- Desktop có logo/tên app, sidebar thu gọn bằng icon, bấm để mở; mục chọn là thẻ gradient nổi bật.
- Mobile có thanh dưới gọn và nút Luyện nói ở giữa; avatar trên cùng mở Tài khoản.
- Wav2Vec2Phoneme + ASR mã nguồn mở trên backend; được phép tải model để kiểm tra.
- Nhóm tổ chức 4 người × 10 câu, chuẩn bị bộ câu/biểu mẫu và kiểm tra Android thật.

## Checklist giảng viên

| Mục | Bản code hiện tại | Phạm vi đã kiểm tra và phần còn lại |
|---|---|---|
| 1. CSDL người dùng/lịch sử/kết quả | SQLite/Drift với users, settings, sessions, results, phoneme_feedback, app_state; khóa ngoại/index, ghi giao dịch, chống trùng, import JSON cũ | Test giao dịch/rollback/tách tài khoản/import; lưu và mở lại qua Chrome. Còn nghiệm thu lưu/mở trên Android thật |
| 2. Streak/thời gian/mục tiêu | Kế thừa Sơn; dùng dữ liệu SQLite có sự kiện cập nhật; không tính thời gian đợi API; ngày theo múi giờ tài khoản | Test quy tắc streak, qua ngày/DST, cập nhật sau lưu; có giao diện tiến độ |
| 3. Thu âm/nhận dạng | Web MediaRecorder, Android PCM16 WAV; backend ASR từ audio thực | Đã chạy ghi âm qua Chrome với audio TTS tổng hợp và API thật. Còn micro Android và giọng người thật |
| 4. AI/so sánh âm vị | Wav2Vec2Phoneme nhận nhãn từ audio, căn chỉnh edit distance với IPA; điểm 0–100 có định nghĩa; ASR không tham gia điểm | Đã tải/nạp model, gọi API CPU, kiểm tra âm thay/thêm/thiếu trong thuật toán. Chưa hiệu chuẩn với chuyên gia; đã ghi nhận model bỏ lọt một ca TTS |
| 5. Điểm/âm lỗi/gợi ý | Kế thừa phản hồi của Đăng; hiện âm chuẩn/nhận dạng, trạng thái chữ + màu, gợi ý khẩu hình/bài liên quan; lưu chi tiết | Test UI responsive và luồng kết quả thật trên web. Mức chính xác gợi ý phụ thuộc model; chờ đối chiếu người nghe |
| 6. Nhắc học/tiến độ | LocalReminderService thật mặc định; Android lịch OS, web tab mở; cài đặt theo tài khoản | Test lịch/đổi giờ/tắt và lưu cài đặt. Còn nhận thông báo/khởi động lại trên Android thật |
| 7. Nhiều người/giọng | 4 tài khoản demo, 10 câu thống nhất catalog, CSV 40 phiên và hướng dẫn người nghe đối chiếu | **Chưa nghiệm thu**: chưa có 40 bản ghi/nhãn người thật. Audio tổng hợp không thay thế mục này |

**Không đánh dấu hoàn thành 7/7 hoặc khẳng định độ chính xác AI chỉ dựa trên test/build.** Có thể bàn giao code và bản build để nhóm tổ chức nghiệm thu phần còn lại.

## Đối chiếu cá nhân

| Thành viên | Phần code kế thừa | Phần sửa/bổ sung khi tích hợp | Việc còn cần thành viên phối hợp |
|---|---|---|---|
| Nguyễn Văn Trường | Hợp đồng, khung app/theme/điều hướng, review/merge | Tài khoản demo; sidebar/navbar mới; font đóng gói; tích hợp model/SQLite; lazy page, bảo toàn trạng thái; sửa build; tài liệu và kiểm tra toàn luồng | Thu kết quả nghiệm thu, kiểm tra bản nộp và minh chứng cuối |
| Vũ Tuấn Khanh | Model/repository/serializer người dùng, JSON, lịch sử, test | Drift SQLite có giao dịch/khóa ngoại/index; import cũ; lịch sử tự cập nhật, tên câu dễ đọc; lọc ngày đúng múi giờ; đổi tài khoản không lẫn dữ liệu | Xác nhận lưu/mở dữ liệu trên Android thật |
| Vũ Hải Đăng | 16 bài, studio luyện, recorder/STT/TTS web, feedback, gợi ý và test | Recorder/TTS Android; backend Python + model âm vị/ASR thật; khóa revision; bỏ fallback và GOP giả; chặn thao tác trùng/đổi bài lúc phân tích; dừng micro khi rời trang; đồng bộ catalog/IPA | Thử 4 người × 10 câu, đối chiếu nhãn âm, ghi nhận nhận nhầm và đánh giá độ ổn định |
| Lý Đình Sơn | Streak, mục tiêu, biểu đồ, nhắc học, test múi giờ | Gắn SQLite có sự kiện; thống nhất theme; adapter thật mặc định; dùng chung quy tắc ngày cho Lịch sử/Tiến độ | Đo giờ nhận nhắc, đổi/tắt lịch và khởi động lại Android; thử web khi tab mở |

Phần bổ sung do đợt tích hợp Trường/Codex thực hiện; không ghi nhận ngược thành phần từng thành viên đã tự làm. Nhánh Đăng trước đó đã merge qua PR #7; các module được kế thừa thay vì viết lại toàn bộ.

## Minh chứng kỹ thuật

- 138 test Flutter đạt: hợp đồng, dữ liệu, SQLite, streak, API client, responsive, lazy page/sidebar và dừng micro khi rời trang.
- 15 test Python đạt: giải mã audio, lỗi/im lặng, so sánh âm vị và bảo vệ dữ liệu API.
- Model đã tải/nạp và trả phản hồi thật từ audio TTS trên CPU; [báo cáo cả ca nhận nhầm](pronunciation/evaluation.md).
- Quy trình trình duyệt tự động và ảnh nằm ở [screenshots/final](../screenshots/final/); phạm vi chính xác theo `verification.json`.
- `flutter analyze` không có vấn đề; build web release JavaScript và APK release đạt. Web dùng CanvasKit cục bộ, font Be Vietnam Pro/Noto Sans/Roboto đóng gói để không phụ thuộc CDN cho bộ render/IPA.
- Build/test thiết bị được ghi trong [hướng dẫn nghiệm thu](kiem-thu-nghien-thu.md). Chưa có thiết bị Android kết nối, không công bố đã nghiệm thu micro/thông báo thực.
