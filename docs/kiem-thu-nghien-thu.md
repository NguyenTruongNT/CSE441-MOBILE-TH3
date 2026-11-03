# Bộ kiểm thử nghiệm thu TH3

## Chuẩn bị

- Ít nhất 4 người đồng ý tham gia, có giọng hoặc mức phát âm khác nhau; dùng mã P01–P04, không ghi tên thật.
- Mỗi người dùng một tài khoản demo riêng, đọc cùng 10 câu dưới đây. Không lấy dữ liệu mô phỏng làm kết quả thử người thật.
- Ghi nền tảng, phiên bản ứng dụng, model/revision, micro, môi trường và thời gian mỗi lần thử.
- Ít nhất 2 người nghe đối chiếu độc lập các âm mục tiêu, thống nhất nhãn cuối nếu có bất đồng.
- Audio chỉ lưu làm minh chứng khi người thử đồng ý; tách khỏi Git. Bảng kết quả ẩn danh không tự chứng minh có sự đồng ý.

## Bộ 10 câu

| Bài trong ứng dụng | Câu đọc | Âm mục tiêu |
|---|---|---|
| 01 | I think this method is great | θ, ð, ŋk |
| 02 | They breathe together in the weather | ð |
| 03 | She sells sea shells on the seashore | s, ʃ |
| 04 | Charles chooses a cheap watch while John rejoices | tʃ, dʒ |
| 05 | The sheep on the ship looks big and neat | iː, ɪ |
| 06 | He asked six questions in the test | skt, ks, st |
| 07 | The red light turns right very quickly | r, l |
| 08 | They go home slowly in the cold snow | eɪ, əʊ |
| 09 | The young singer is thinking of a song | ŋ, ŋk |
| 10 | Many modern men make more money | m, n |

Catalog đã được đối chiếu giữa Flutter và backend bằng test tự động. Người nghe vẫn cần đối chiếu IPA/câu thực tế, ghi nhận khác biệt biến thể giọng thay vì mặc định mọi khác biệt đều là lỗi.

## Các bước cho mỗi người

1. Chọn tài khoản tương ứng; ghi mã người thử, nền tảng và môi trường.
2. Nghe mẫu, đọc câu một lần ở giọng tự nhiên. Không bắt người thử cố bắt chước để làm đẹp số liệu.
3. Ghi âm, phân tích, mở kết quả và ghi lại điểm, âm AI đánh dấu, thời gian xử lý, mã phiên.
4. Hai người nghe ghi nhãn độc lập dựa trên bản ghi được cho phép lưu/nghe.
5. Với từng âm mục tiêu, đối chiếu AI và nhãn thống nhất: đúng cùng, sai cùng, cảnh báo sai hoặc bỏ lọt.
6. Thử lại ít nhất một câu; ghi chênh lệch điểm và nhận xét độ ổn định.
7. Hoàn thành đủ 40 phiên (4 người × 10 câu), không điền trước kết quả.

Biểu mẫu: [evaluation-results.csv](pronunciation/evaluation-results.csv). Các ô điểm và kết quả được để trống để nhóm điền sau khi đo.

## Cách tổng hợp

- Tỷ lệ đồng thuận = số âm có nhãn AI giống nhãn người nghe / tổng số âm có đủ nhãn × 100%.
- Tỷ lệ cảnh báo sai = số âm người nghe đánh đúng nhưng AI đánh cần luyện / tổng số âm người nghe đánh đúng × 100%.
- Tỷ lệ bỏ lọt = số âm người nghe đánh cần luyện nhưng AI đánh đúng / tổng số âm người nghe đánh cần luyện × 100%.
- Báo riêng số trường hợp không đủ bằng chứng, lỗi mạng, âm chưa đánh giá; không gộp thành 0 điểm.
- Không tính tỷ lệ nếu mẫu số bằng 0. Ghi số mẫu, không chỉ phần trăm.
- Với kiểm thử nhỏ, kết luận giới hạn trong bộ câu/người đã thử; không khẳng định độ chính xác chung.

## Checklist Android/web

| Ca | Kỳ vọng | Kết quả thực |
|---|---|---|
| Vào tài khoản A, đăng xuất, vào B | Lịch sử/mục tiêu tách riêng | Chưa ghi nhận |
| Luyện xong → Lịch sử/Tiến độ | Cập nhật đúng tài khoản | Chưa ghi nhận |
| Đóng/mở lại, chọn lại tài khoản | Dữ liệu vẫn còn | Chưa ghi nhận |
| Hai thao tác lưu thử lại cùng ID | Một phiên duy nhất | Chưa ghi nhận |
| Cấp và từ chối micro | Thu được audio thật hoặc hướng dẫn cấp quyền | Chưa ghi nhận |
| Im lặng, audio quá ngắn/lỗi | Báo thiếu bằng chứng/audio lỗi, không tự sinh điểm | Chưa ghi nhận |
| Tắt backend/mạng | Báo lỗi, không có kết quả giả | Chưa ghi nhận |
| Đăng xuất khi đang phân tích | Không gán kết quả sang tài khoản mới | Chưa ghi nhận |
| Đặt giờ nhắc, đổi giờ, tắt | Không tạo lịch trùng; nhận thông báo đúng điều kiện | Chưa ghi nhận |
| Khởi động lại Android | Kiểm tra nhận nhắc trong điều kiện hệ điều hành cho phép | Chưa ghi nhận |
| Web đóng tab | Không kỳ vọng thông báo nền | Chưa ghi nhận |
| Rộng 360/768/1366px | Không tràn, thao tác và đọc kết quả được | Chưa ghi nhận |

Ghi giờ hẹn và giờ nhận thực cho thông báo; ghi rõ máy thật/emulator, trạng thái màn hình và tiết kiệm pin. Không thay nghiệm thu thiết bị bằng unit test.

## Kiểm tra kỹ thuật có thể chạy lại

Đã đạt 138 test Flutter và 15 test backend. Phạm vi thử trình duyệt thực tế ghi trong [verification.json](../screenshots/final/verification.json); không tự đánh dấu cột nghiệm thu Android ở trên bằng kết quả web.

Từ thư mục gốc, sau khi đã cài/nạp model và chạy backend:

```powershell
powershell -File tool/create_smoke_audio.ps1
.venv/Scripts/python.exe tool/check_models.py
flutter build web --release --no-wasm-dry-run
python -m http.server 8910 --bind 127.0.0.1 --directory build/web
```

Terminal khác:

```powershell
npm install --prefix .dart_tool/ui-review playwright
node tool/verify_web.cjs
```

Script dùng Chrome ở đường dẫn Windows thông thường (hoặc biến CHROME_PATH). Nó tạo audio TTS tổng hợp cục bộ để kiểm tra model và thiết bị microphone giả của Chrome để kiểm tra toàn luồng. Giữ cả ca model nhận nhầm trong báo cáo. Không xem đây là bộ thử người thật và không commit audio từ người tham gia.
