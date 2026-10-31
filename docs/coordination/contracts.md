# Hợp đồng kết nối module — v1

Nguồn chuẩn: `lib/core/contracts/contracts.dart`. Nhóm trưởng sở hữu hợp đồng; các thành viên triển khai interface thay vì tự tạo model trùng tên. Không có dependency mới ở phiên bản này.

## Chủ sở hữu và đầu vào màn hình

- Khanh cài `UserRepository`, `LearningRepository`, giao diện hồ sơ/lịch sử.
- Đăng cài `PronunciationService`, giao diện luyện, ghi âm và nội dung `Exercise`.
- Sơn cài `ReminderService`, giao diện tiến độ/cài đặt.
- Trường ghép instance và truyền qua constructor. Module chỉ import hợp đồng và mã của chính mình, không import module khác.

Đầu vào đề nghị khi bàn giao widget (chữ ký constructor cụ thể do chủ module công bố):

```dart
// Ví dụ yêu cầu đầu vào, chưa phải widget có sẵn.
ProgressPage(userRepository: users, learningRepository: learning,
             reminderService: reminders)
PronunciationPage(userRepository: users, learningRepository: learning,
                  pronunciationService: pronunciation)
HistoryPage(userRepository: users, learningRepository: learning)
ProfilePage(userRepository: users, learningRepository: learning,
            reminderService: reminders)
```

Mỗi module tự tạo fake trong thư mục test/demo để chạy riêng. Fake không gọi API thật và phải gắn nhãn nếu hiện lên UI. Các repository thực tế chưa được cài đặt trong phần việc của Trường.

## Quy ước dữ liệu

- ID là chuỗi không rỗng, ổn định; chủ module phát sinh ID bảo đảm duy nhất. Các trường tên/nội dung bắt buộc phải được adapter kiểm tra trước khi lưu.
- Timestamp được model chuẩn hóa UTC. Khi lưu JSON, dùng ISO-8601 có hậu tố `Z`; enum lưu bằng `.name`. Adapter lưu trữ chịu trách nhiệm serialize/deserialize và báo `AppFailure(storage, ...)` nếu dữ liệu hỏng.
- Điểm là số hữu hạn 0–100; không có bằng chứng chấm thì throw `AppFailure(insufficientEvidence, ...)`, không dựng kết quả điểm 0.
- `recognizedIpa`, điểm từng âm và cặp timestamp có thể không được provider hỗ trợ. Dùng null và `notAssessed`; không suy ra âm sai chỉ từ transcript.
- Khoảng âm thanh tính bằng milliseconds; có cả đầu/cuối hoặc không có cả hai. Danh sách phản hồi giữ thứ tự từ/âm.
- `AudioSample` chứa bytes và MIME thực của bản ghi; Đăng chịu trách nhiệm kiểm tra codec/dung lượng/tần số phù hợp provider. Không dùng đường dẫn file làm hợp đồng vì web cần hỗ trợ bytes.
- `Exercise.sampleAudioUri` tùy chọn; nguồn âm thanh phải hợp lệ và có quyền sử dụng. `targetPhonemes` giữ thứ tự âm mục tiêu.

Ví dụ JSON lưu trữ cho một phiên thành công (minh họa cấu trúc, không phải điểm đo thật):

```json
{
  "session": {
    "id": "session-demo-001",
    "userId": "user-demo-001",
    "exerciseId": "exercise-think",
    "startedAt": "2026-11-01T12:00:00Z",
    "endedAt": "2026-11-01T12:01:00Z",
    "durationSeconds": 40,
    "status": "completed"
  },
  "result": {
    "id": "result-demo-001",
    "sessionId": "session-demo-001",
    "referenceText": "think",
    "recognizedText": "think",
    "overallScore": 75.0,
    "provider": "demo-only",
    "modelVersion": "fixture-v1",
    "analyzedAt": "2026-11-01T12:01:00Z",
    "phonemes": [
      {
        "word": "think",
        "expectedIpa": "θ",
        "recognizedIpa": null,
        "score": 60.0,
        "status": "needsPractice",
        "startMilliseconds": null,
        "endMilliseconds": null,
        "suggestion": "Luyện âm /θ/ theo hướng dẫn của bài học."
      }
    ]
  }
}
```

## Lưu và truy vấn

`savePractice` là giao dịch nguyên tử, idempotent theo session ID. Gọi lại cùng ID và nội dung không tạo bản ghi mới; cùng ID khác nội dung phải báo lỗi lưu trữ, không âm thầm ghi đè. Adapter kiểm tra user/bài tồn tại và `result.sessionId == session.id`. Phiên `completed` có kết quả; `cancelled`/`analysisFailed` không có kết quả. Thời lượng hoàn thành cần lớn hơn 0 và không vượt thời gian thực đã trôi qua.

`listSessions` lọc `startedAt` theo khoảng `[fromUtc, toUtc)`, mới nhất trước. Caller truyền UTC và khoảng hợp lệ; repository kiểm tra user. `getResult` phải kiểm tra sở hữu theo user, trả null khi chưa có kết quả; không làm lộ dữ liệu hồ sơ khác.

`getSettings` mặc định: 15 phút/ngày, nhắc tắt, 20:00, `Asia/Ho_Chi_Minh`; không tự bật thông báo. `saveProfile` tạo mới hoặc cập nhật cùng ID. `selectProfile` phải kiểm tra ID tồn tại.

## Thời gian, streak và đổi hồ sơ

- Chỉ phiên `completed` có thời lượng > 0 được tính vào thời gian/streak; loại thời gian chờ API và không hoạt động.
- Gán phiên cho ngày bắt đầu theo múi giờ hồ sơ. Phiên qua nửa đêm vẫn thuộc ngày bắt đầu ở v1; quy tắc thống kê phải nhất quán.
- Truy vấn chuyển ranh giới ngày địa phương thành UTC trước khi gọi repository, không cắt chuỗi ngày UTC.
- Nhiều phiên/ngày tính một ngày streak; ngày có luyện khác với ngày đạt mục tiêu phút.
- Streak hiện tại kết thúc hôm nay hoặc hôm qua; ngày gần nhất cũ hơn hôm qua thì 0. Dùng đồng hồ có thể thay thế khi test.
- Khi đổi hồ sơ: hủy nhắc hồ sơ cũ, chọn hồ sơ mới, tải lại dữ liệu/cài đặt, lên lịch hồ sơ mới nếu bật và được cấp quyền. Không hiển thị dữ liệu cache của user cũ.
- Không đổi thời lượng/điểm lịch sử khi thay mục tiêu.

## Lỗi và khả năng nền tảng

Adapter chuyển lỗi thành `AppFailure` với `code` trong hợp đồng. UI hiển thị thông báo dễ hiểu và thao tác thử lại, không hiện khóa/token hay toàn bộ phản hồi nhạy cảm từ provider.

`ReminderService.requestPermission` phân biệt granted/denied/unsupported. `scheduleDaily` thay lịch cũ theo user, hủy nếu tắt; lỗi nền tảng báo có kiểu. Không cam kết web nhận nhắc khi đóng trình duyệt nếu chưa có triển khai hỗ trợ.

## Bàn giao và thay đổi

Mỗi thành viên gửi đường dẫn widget đầu vào, constructor, adapter, dependency, quyền nền tảng, lệnh chạy/test và hạn chế. Trường review trước khi sửa cấu hình chung. Thay đổi hợp đồng phải cập nhật tài liệu và thông báo cả nhóm; không tự đổi chữ ký trong module.
