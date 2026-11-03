# Kết quả kiểm tra model và kế hoạch nhiều giọng

Ngày 03/11/2026. Các số liệu “83,3% đồng thuận” trong báo cáo trước không có đủ minh chứng kiểm chứng, đã bỏ khỏi báo cáo hiện hành. Lịch sử Git vẫn giữ tài liệu cũ. Không dùng chúng làm kết quả nộp bài.

## Đã chạy bằng model thật

Hai checkpoint mã nguồn mở đã tải/nạp, khóa revision trong [manifest](../../backend/pronunciation/models.json). Đầu vào ba ca dưới là **audio tổng hợp Windows SAPI**, gửi đến HTTP API thực, suy luận CPU; không phải bản ghi của 4 người học.

Cùng tham chiếu “I think this method is great”:

| Nội dung TTS đầu vào | ASR trả về | Điểm khớp âm vị | Nhận xét |
|---|---|---|---|
| I think this method is great | I THINK THIS METHOD IS GREAT | 100 | Luồng chuẩn hoạt động; 19 âm phản hồi |
| I sink this method is great | I THINK THIS METHOD IS GREAT | 100 | **Bỏ lọt có thể xảy ra**: model âm vị cũng trả /θ/ thay /s/; không lấy ca này làm minh chứng phân biệt θ/s thành công |
| We go home slowly in the cold snow | WE GO HOME SLOWLY IN THE COLD SNOW | 8,7 | Đọc câu khác bị giảm điểm dù client gửi transcript giống câu chuẩn; điểm thực sự dùng nhãn từ audio |

Thời gian xử lý đo trong ba lần trên lần lượt 2,562 / 0,487 / 0,573 giây. Đây là phép đo riêng trên máy thử, không phải SLA hay tốc độ mọi thiết bị. [Dữ liệu tổng hợp](model-verification.json) giữ cả ca thành công và nhận nhầm, revision và thời gian; audio gốc không đưa lên Git.

Kiểm thử Chrome dùng microphone giả phát file TTS, sau đó gửi bản ghi đến backend model thật. Kết quả lưu trong [verification.json](../../screenshots/final/verification.json) và [ảnh giao diện](../../screenshots/final/). Thử này kiểm tra đường ghi âm/API/lưu dữ liệu; không đo độ chính xác với giọng người.

## Chưa có kết quả người thật

Chưa có đủ 4 người × 10 câu với nhãn người nghe, chưa tính agreement/false positive/false negative. Mục 7 checklist vẫn chờ nghiệm thu. Không thay kết quả này bằng dữ liệu tổng hợp hoặc unit test.

Nhóm thực hiện theo [hướng dẫn nghiệm thu](../kiem-thu-nghien-thu.md), dùng [CSV 40 phiên](evaluation-results.csv). Chỉ điền điểm, nhãn và thời gian sau khi đo. Ghi riêng notAssessed, lỗi, mẫu số; đối chiếu độc lập ít nhất 2 người nghe trước khi tính tỷ lệ.

## Giới hạn

Điểm edit similarity phụ thuộc lỗi nhận dạng của model, khác biệt giọng và catalog IPA. Không chấm trọng âm/ngữ điệu. Timestamp chỉ là khung CTC; không có dữ liệu chuyên gia để khẳng định độ chính xác thời gian. Bản hiện tại là công cụ hỗ trợ luyện tập và cần nghiệm thu trước khi khẳng định chất lượng phân tích.
