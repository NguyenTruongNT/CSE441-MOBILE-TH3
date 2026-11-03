# Hướng dẫn sử dụng English AI

## Vào ứng dụng

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

## Luyện phát âm

1. Chọn **Luyện phát âm** ở thanh bên trên desktop hoặc thanh điều hướng dưới trên mobile.
2. Tìm/chọn một bài, đọc nội dung, IPA và gợi ý khẩu hình.
3. Bấm **Nghe phát âm chuẩn** để nghe giọng TTS trên thiết bị/trình duyệt.
4. Cấp quyền micro khi được hỏi. Bấm **Bắt đầu ghi âm**, đọc trọn câu trong môi trường yên tĩnh.
5. Bấm **Dừng & Phân tích**, chờ backend xử lý. Mỗi bản ghi tối đa 60 giây.
6. Xem điểm, âm chuẩn, âm nhận dạng và gợi ý. Bấm bài luyện cải thiện để luyện tiếp.
7. Sang **Lịch sử** để xem phiên vừa lưu và chi tiết kết quả.

Backend phải đang chạy và điện thoại phải truy cập được địa chỉ backend đã cấu hình. Transcript trực tiếp trên web chỉ là hỗ trợ khi trình duyệt có khả năng này; kết quả phân tích cần dựa vào audio được gửi. Nếu thiếu bằng chứng hoặc mất kết nối, ứng dụng báo lỗi và không tự sinh điểm thay thế.

Điểm so sánh âm vị là công cụ hỗ trợ luyện tập. Mô hình có thể nhận nhầm giọng, tiếng ồn hoặc biến thể phát âm; đối chiếu với người nghe trong bộ kiểm thử trước khi đưa ra kết luận về độ chính xác.

## Xem lịch sử và đổi tài khoản

1. Mở **Lịch sử**, chọn khoảng ngày nếu cần.
2. Chọn phiên luyện để xem điểm, câu chuẩn, câu nhận dạng và phản hồi đã lưu.
3. Chọn **Tài khoản → Đăng xuất**, hoặc nút đăng xuất trên thanh đầu trang.
4. Chọn tài khoản khác ở màn hình vào ứng dụng. Lịch sử cũ vẫn được giữ; giao diện và trạng thái phiên trước được đóng.

## Khi gặp lỗi

| Hiện tượng | Thao tác |
|---|---|
| Không ghi âm được | Kiểm tra quyền micro trong cài đặt ứng dụng/trình duyệt; đóng ứng dụng khác đang chiếm micro |
| Web không hiện quyền micro | Dùng localhost trên máy phát triển hoặc HTTPS khi truy cập từ máy khác |
| Không nghe mẫu | Kiểm tra âm lượng, giọng tiếng Anh/TTS đã cài trên thiết bị; thử lại sau thao tác bấm của người dùng |
| Không kết nối backend | Kiểm tra backend, địa chỉ API, cổng và cùng mạng; localhost trên điện thoại là chính điện thoại |
| Phân tích chậm | Đợi backend tải model hoàn tất; thử câu ngắn, không gửi nhiều yêu cầu cùng lúc |
| Không nhận nhắc học | Kiểm tra quyền, giờ, múi giờ, chế độ tiết kiệm pin; web phải giữ tab mở |
| Chưa thấy phiên mới | Mở lại Lịch sử hoặc kéo để tải lại; kiểm tra tài khoản đang dùng |

Các chức năng cần thiết bị/model thật chỉ được đánh dấu nghiệm thu sau khi chạy checklist tại [bộ kiểm thử](kiem-thu-nghien-thu.md).
