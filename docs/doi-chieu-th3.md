# Đối chiếu TH3 và nhiệm vụ từng thành viên

Rà soát ngày 04/11/2026 · Nhóm 12 có 4 thành viên. Bản hoàn thiện đã được nhóm duyệt để đưa lên nhánh Trường và tích hợp vào main. Trạng thái công việc thành viên là đã hoàn thành theo yêu cầu bàn giao; mục 7 được ghi nhận đạt theo xác nhận của nhóm.

## Lựa chọn đã chốt

- Chọn tài khoản demo có sẵn, đăng xuất; không tạo hồ sơ trong luồng chính.
- Android + web; SQLite/Drift cục bộ, có bảng/giao dịch; không đồng bộ giữa thiết bị.
- Nền sáng, thẻ trắng, gradient xanh–tím; Be Vietnam Pro đóng gói, tiêu đề đậm/nội dung thoáng.
- Desktop có logo/tên app, sidebar thu gọn bằng icon, bấm để mở; mục chọn là thẻ gradient nổi bật.
- Mobile có thanh dưới gọn và nút Luyện nói ở giữa; avatar trên cùng mở Tài khoản.
- Wav2Vec2Phoneme + ASR mã nguồn mở trên backend; được phép tải model để kiểm tra.
- Mục 7 nhiều người/giọng được nhóm xác nhận đạt; giữ bộ 4 người × 10 câu làm biểu mẫu tham khảo, không điền số liệu thay cho kết quả đo.

## Checklist giảng viên

| Mục | Bản code hiện tại | Phạm vi đã kiểm tra và phần còn lại |
|---|---|---|
| 1. CSDL người dùng/lịch sử/kết quả | SQLite/Drift với users, settings, sessions, results, phoneme_feedback, app_state; khóa ngoại/index, ghi giao dịch, chống trùng, import JSON cũ | Test giao dịch/rollback/tách tài khoản/import; lưu và mở lại qua Chrome. Còn nghiệm thu lưu/mở trên Android thật |
| 2. Streak/thời gian/mục tiêu | Kế thừa Sơn; dùng dữ liệu SQLite có sự kiện cập nhật; không tính thời gian đợi API; ngày theo múi giờ tài khoản | Test quy tắc streak, qua ngày/DST, cập nhật sau lưu; có giao diện tiến độ |
| 3. Thu âm/nhận dạng | Web MediaRecorder, Android PCM16 WAV; backend ASR từ audio thực | Đã chạy ghi âm qua Chrome với audio TTS tổng hợp và API thật. Còn micro Android và giọng người thật |
| 4. AI/so sánh âm vị | Wav2Vec2Phoneme nhận nhãn từ audio, căn chỉnh edit distance với IPA; điểm 0–100 có định nghĩa; ASR không tham gia điểm | Đã tải/nạp model, gọi API CPU, kiểm tra âm thay/thêm/thiếu trong thuật toán. Chưa hiệu chuẩn với chuyên gia; đã ghi nhận model bỏ lọt một ca TTS |
| 5. Điểm/âm lỗi/gợi ý | Kế thừa phản hồi Đăng; âm chuẩn/nhận dạng, trạng thái chữ + màu, hướng dẫn/bài liên quan, lưu chi tiết | Đã sửa chọn bài bất kỳ: khớp đơn vị IPA trong câu, không ghép qua từ; âm thừa hiển thị riêng, không tạo bài /∅/. Có test hồi quy |
| 6. Nhắc học/tiến độ | LocalReminderService thật mặc định; Android lịch OS, web tab mở; cài đặt theo tài khoản | Test lịch/đổi giờ/tắt và lưu cài đặt. Còn nhận thông báo/khởi động lại trên Android thật |
| 7. Nhiều người/giọng | 4 tài khoản demo, 10 câu thống nhất catalog, biểu mẫu 40 phiên và hướng dẫn | **Đạt theo xác nhận của nhóm ngày 04/11/2026**; số liệu đo không được tự tạo trong repository |

Các mục 1–6 có triển khai trong code; mục 7 được nhóm xác nhận đạt. Test/build chứng minh phạm vi kỹ thuật đã chạy, không tự chứng minh một tỷ lệ chính xác AI hoặc nghiệm thu phần cứng chưa được đo.

## Đối chiếu cá nhân

| Thành viên | Phần code kế thừa | Phần sửa/bổ sung khi tích hợp | Trạng thái |
|---|---|---|---|
| Nguyễn Văn Trường · 2351170625 | Hợp đồng, khung app/theme/điều hướng, review/tích hợp | Tài khoản demo; sidebar/navbar; font đóng gói; model/SQLite; điều hướng danh sách → bài luyện; launcher; báo cáo, sơ đồ và kiểm tra toàn luồng | ✅ Đã hoàn thành |
| Vũ Tuấn Khanh · 2251172386 | Model/repository/serializer người dùng, JSON, lịch sử, test | Drift SQLite có giao dịch/khóa ngoại/index; import cũ; lịch sử cập nhật; lọc ngày theo múi giờ; tách tài khoản | ✅ Đã hoàn thành |
| Vũ Hải Đăng · 2351170580 | 16 bài, studio luyện, recorder/STT/TTS web, feedback/gợi ý và test | Recorder/TTS Android; backend model thật; khóa revision; bỏ điểm giả; hủy micro khi rời; đồng bộ IPA; sửa đề xuất bài/âm thừa | ✅ Đã hoàn thành |
| Lý Đình Sơn · 2351170615 | Streak, mục tiêu, biểu đồ, nhắc học, test múi giờ | Gắn SQLite; thống nhất theme; adapter thật mặc định; dùng chung quy tắc ngày cho Lịch sử/Tiến độ | ✅ Đã hoàn thành |

Phần bổ sung do đợt tích hợp Trường/Codex thực hiện; không ghi nhận ngược thành phần từng thành viên đã tự làm. Nhánh Đăng trước đó đã merge qua PR #7; các module được kế thừa thay vì viết lại toàn bộ.

## Minh chứng kỹ thuật

- 154 test Flutter đạt: hợp đồng, SQLite, streak, API client, responsive, danh sách → bài luyện/back, sidebar, dừng micro, gợi ý IPA và âm thừa.
- 15 test Python đạt: giải mã audio, lỗi/im lặng, so sánh âm vị và bảo vệ dữ liệu API.
- Model đã tải/nạp và trả phản hồi thật từ audio TTS trên CPU; [báo cáo cả ca nhận nhầm](pronunciation/evaluation.md).
- Quy trình trình duyệt tự động và ảnh nằm ở [screenshots/final](../screenshots/final/); phạm vi chính xác theo `verification.json`.
- `flutter analyze` không có vấn đề; build web release JavaScript và APK release đạt. Web dùng CanvasKit cục bộ, font Be Vietnam Pro/Noto Sans/Roboto đóng gói để không phụ thuộc CDN cho bộ render/IPA.
- APK mới đã cài/mở tới màn chọn tài khoản trên máy ảo Pixel 5 Android 17. Máy ảo sau đó gặp System UI ANR/mất kết nối; chưa xác nhận micro, lưu/mở và nhận nhắc trên Android. Phạm vi này được ghi trong [biên bản 04/11](kiem-tra-ky-thuat-2026-11-04.md); không thay bằng kết quả web.
