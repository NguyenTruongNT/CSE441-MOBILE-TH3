# Hướng dẫn sử dụng English AI

## Vào ứng dụng

Trên máy Windows đã cài môi trường/model: mở `run_web.bat` ở thư mục gốc dự án. Script kiểm tra và khởi động backend, chờ model sẵn sàng rồi mở Chrome. Chỉ mở trang web hoặc chạy Flutter riêng sẽ không tự bật máy chủ AI. Nếu dùng `run_backend.bat` riêng, giữ cửa sổ đó mở trong suốt buổi luyện.

1. Mở ứng dụng trên Android hoặc trình duyệt.
2. Chọn **Học viên 1**, **Học viên 2**, **Học viên 3** hoặc **Học viên 4**. Tài khoản cục bộ từ phiên bản cũ được giữ lại nếu đã có dữ liệu.
3. Ứng dụng mở trang **Tiến độ**. Mỗi tài khoản có mục tiêu, lịch sử và kết quả riêng.

Đây là chế độ tài khoản demo theo lựa chọn của nhóm, không phải xác thực bằng mật khẩu. Không có nút tạo hồ sơ trong luồng dùng chính. Dữ liệu SQLite nằm trên thiết bị hoặc trong bộ nhớ lưu trữ của trình duyệt, không đồng bộ giữa các máy. Xóa dữ liệu ứng dụng/trang web sẽ xóa CSDL cục bộ; dùng cùng địa chỉ và cổng web để mở lại đúng dữ liệu.

## Đặt mục tiêu và nhắc học

1. Trong **Tiến độ**, chọn số phút muốn luyện mỗi ngày.
2. Bật **Nhắc học** và chấp nhận quyền thông báo.
3. Chọn giờ nhắc. Cài đặt được tự động lưu.
4. Luyện phát âm để cộng thời gian học, cập nhật biểu đồ 7 ngày và streak.

Một ngày có ít nhất một phiên hoàn thành với thời lượng lớn hơn 0 được tính là ngày luyện. Nhiều phiên trong cùng ngày không tăng thêm số ngày streak. Streak được giữ nếu ngày luyện gần nhất là hôm nay hoặc hôm qua; bỏ một ngày sẽ ngắt chuỗi. Phiên qua nửa đêm được tính theo ngày bắt đầu trong múi giờ tài khoản. Thời gian chờ AI không tính vào thời gian học.

Android có lịch nhắc do hệ điều hành quản lý. Chế độ tiết kiệm pin có thể làm nhắc trễ; buộc dừng ứng dụng có thể chặn thông báo. Trên web, cần giữ tab mở và cho phép thông báo; không có thông báo nền khi đã đóng trình duyệt.

## Điều hướng desktop/mobile

- Desktop: logo/tên ứng dụng ở đầu thanh bên. Bấm mũi tên để thu gọn thành icon hoặc mở rộng; mục đang chọn hiện thẻ gradient xanh–tím. Thu gọn không làm mất trạng thái trang.
- Mobile: **Tiến độ**, nút micro **Luyện nói** nổi bật ở giữa, **Lịch sử**. Bấm avatar ở góc trên để vào **Tài khoản**.
- Tiêu đề, nội dung và thao tác dùng font Be Vietnam Pro đi kèm ứng dụng. Trang có thể cuộn để xem đủ nội dung khi màn hình nhỏ hoặc cỡ chữ hệ thống lớn.

## Luyện phát âm

1. Chọn **Luyện nói** ở thanh bên trên desktop hoặc nút micro giữa thanh dưới trên mobile.
2. Trang đầu là **Danh sách bài luyện**. Tìm theo câu/IPA hoặc lọc **Nhóm âm**, rồi bấm thẻ bài muốn luyện. Danh sách chưa hiển thị micro hay tự chọn sẵn bài.
3. Màn luyện riêng hiển thị câu, IPA và gợi ý khẩu hình. Desktop đặt câu mẫu và ghi âm cạnh nhau; mobile xếp dọc. Nút **Danh sách bài luyện** ở trên quay lại và giữ bộ lọc/vị trí cuộn. Quay lại khi đang thu hoặc phân tích sẽ hủy lần luyện chưa hoàn tất.
4. Bấm **Nghe phát âm chuẩn** để nghe giọng TTS trên thiết bị/trình duyệt.
5. Cấp quyền micro khi được hỏi. Bấm **Bắt đầu ghi âm**, đọc trọn câu trong môi trường yên tĩnh.
6. Bấm **Dừng & Phân tích**, chờ backend xử lý. Mỗi bản ghi tối đa 60 giây.
7. Xem điểm, âm chuẩn, âm nhận dạng và gợi ý. “Khớp mẫu” là nhãn mô hình khớp IPA; “Cần luyện” là khác biệt phát hiện; “Chưa đánh giá” nghĩa là chưa đủ chắc chắn. “Âm thừa” là phần mô hình nhận thêm ngoài mẫu, không phải một âm tên `∅` cần luyện. Bài cải thiện được chọn theo đơn vị IPA thực sự có trong câu; nếu không có bài phù hợp, đọc hướng dẫn và luyện lại bài hiện tại.
8. Sang **Lịch sử** để xem phiên vừa lưu và chi tiết kết quả.

Backend phải đang chạy và điện thoại phải truy cập được địa chỉ backend đã cấu hình. Transcript trực tiếp trên web chỉ là hỗ trợ khi trình duyệt có khả năng này; kết quả phân tích cần dựa vào audio được gửi. Nếu thiếu bằng chứng hoặc mất kết nối, ứng dụng báo lỗi và không tự sinh điểm thay thế.

Khi rời trang trong lúc thu, micro dừng và bản ghi chưa phân tích bị hủy. Khi đã gửi phân tích, chờ kết quả trước khi chọn bài khác. Ghi âm im lặng, quá nhỏ hoặc quá ngắn sẽ yêu cầu ghi lại. Lần cài model đầu tiên: xem [cách chạy backend](../backend/pronunciation/README.md).

Điểm so sánh âm vị là công cụ hỗ trợ luyện tập. Mô hình có thể nhận nhầm giọng, tiếng ồn hoặc biến thể phát âm; đối chiếu với người nghe trong bộ kiểm thử trước khi đưa ra kết luận về độ chính xác.

## Xem lịch sử và đổi tài khoản

1. Mở **Lịch sử**, chọn khoảng ngày nếu cần.
2. Chọn phiên luyện để xem điểm, câu chuẩn, câu nhận dạng và phản hồi đã lưu.
3. Chọn avatar **Tài khoản → Đăng xuất**; desktop có thêm nút **Đăng xuất** dưới sidebar.
4. Chọn tài khoản khác ở màn hình vào ứng dụng. Lịch sử cũ vẫn được giữ; giao diện và trạng thái phiên trước được đóng.

## Khi gặp lỗi

| Hiện tượng | Thao tác |
|---|---|
| Không ghi âm được | Kiểm tra quyền micro trong cài đặt ứng dụng/trình duyệt; đóng ứng dụng khác đang chiếm micro |
| Web không hiện quyền micro | Dùng localhost trên máy phát triển hoặc HTTPS khi truy cập từ máy khác |
| Không nghe mẫu | Kiểm tra âm lượng, giọng tiếng Anh/TTS đã cài trên thiết bị; thử lại sau thao tác bấm của người dùng |
| Không kết nối backend / Failed to fetch | Trên máy chạy dự án, mở `run_backend.bat`, chờ `Application startup complete`; kiểm tra `http://127.0.0.1:8080/health` có `assessmentReady: true`, rồi ghi âm lại. Máy chủ phải tiếp tục chạy. Điện thoại/máy khác cần địa chỉ API phù hợp, localhost là chính thiết bị đó |
| Phân tích chậm | Đợi backend tải model hoàn tất; thử câu ngắn, không gửi nhiều yêu cầu cùng lúc |
| Không nhận nhắc học | Kiểm tra quyền, giờ, múi giờ, chế độ tiết kiệm pin; web phải giữ tab mở |
| Chưa thấy phiên mới | Mở lại Lịch sử hoặc kéo để tải lại; kiểm tra tài khoản đang dùng |

Các chức năng cần thiết bị/model thật chỉ được đánh dấu nghiệm thu sau khi chạy checklist tại [bộ kiểm thử](kiem-thu-nghien-thu.md).
