# Thiết kế lưu trữ module User Data

> Đây là schema JSON của phiên bản được kế thừa, hiện chỉ dùng cho dữ liệu import. CSDL đang chạy là [SQLite/Drift](sqlite-schema.md); không xem JSON/SharedPreferences là nơi lưu mới.

## 1. Mục tiêu

Module User Data chịu trách nhiệm lưu trữ và truy xuất:

- Hồ sơ người học.
- Hồ sơ đang được chọn.
- Cài đặt học tập của từng hồ sơ.
- Các phiên luyện phát âm.
- Kết quả phân tích phát âm.
- Phản hồi theo từng âm vị.

Phạm vi hiện tại là hồ sơ cục bộ trên thiết bị. Module không triển khai đăng nhập, xác thực tài khoản hoặc đồng bộ dữ liệu giữa nhiều thiết bị.

## 2. Phạm vi mã nguồn

Module được triển khai trong:

```text
lib/features/user_data/
```

Các bài kiểm thử nằm trong:

```text
test/user_data/
```

Các tài liệu bàn giao nằm trong:

```text
docs/user_data/
```

Module chỉ phụ thuộc vào hợp đồng chung tại:

```text
lib/core/contracts/
```

Module không import trực tiếp mã nguồn của module phát âm hoặc module kỷ luật học tập.

## 3. Kiến trúc lưu trữ

Các repository không phụ thuộc trực tiếp vào công nghệ lưu trữ cụ thể.

Dữ liệu được truy cập thông qua interface nội bộ:

```dart
abstract interface class UserDataStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}
```

Các triển khai:

- `MemoryUserDataStore`: dùng cho unit test và demo độc lập.
- Persistent store: dùng để lưu dữ liệu thật trên Android và Web sau khi dependency lưu trữ được nhóm trưởng bổ sung.

Các repository:

- `PersistentUserRepository` triển khai `UserRepository`.
- `PersistentLearningRepository` triển khai `LearningRepository`.

## 4. Phiên bản schema

Phiên bản hiện tại:

```text
schemaVersion = 1
```

Mọi tài liệu gốc đều phải chứa `schemaVersion`.

Nếu dữ liệu không tồn tại, module tạo một tài liệu rỗng ở schema version 1.

Nếu dữ liệu có phiên bản cao hơn phiên bản ứng dụng hỗ trợ, module trả về `AppFailureCode.storage` và không tự ý xóa dữ liệu.

## 5. Root document

Cấu trúc tài liệu JSON gốc:

```json
{
  "schemaVersion": 1,
  "selectedUserId": null,
  "users": [],
  "learningSettings": [],
  "practiceSessions": [],
  "pronunciationResults": []
}
```

Ý nghĩa các trường:

- `schemaVersion`: phiên bản cấu trúc dữ liệu.
- `selectedUserId`: ID của hồ sơ đang được chọn hoặc `null`.
- `users`: danh sách hồ sơ người học.
- `learningSettings`: cài đặt học tập của từng hồ sơ.
- `practiceSessions`: danh sách phiên luyện tập.
- `pronunciationResults`: kết quả phân tích phát âm.

## 6. Hồ sơ người học

Cấu trúc `UserProfile`:

```json
{
  "id": "user-khanh",
  "displayName": "Vũ Tuấn Khanh",
  "timeZone": "Asia/Ho_Chi_Minh",
  "createdAt": "2026-11-02T08:00:00.000Z"
}
```

Ràng buộc:

- `id` không được rỗng.
- `id` phải duy nhất.
- `displayName` không được rỗng sau khi loại khoảng trắng.
- `timeZone` không được rỗng.
- Múi giờ mặc định là `Asia/Ho_Chi_Minh`.
- `createdAt` được chuẩn hóa sang UTC.
- Lưu lại hồ sơ có cùng ID sẽ cập nhật hồ sơ, không tạo bản ghi trùng.

`selectedUserId` chỉ được nhận ID của một hồ sơ đang tồn tại.

Khi chọn ID không tồn tại, repository trả về `AppFailureCode.storage`.

## 7. Cài đặt học tập

Cấu trúc `LearningSettings`:

```json
{
  "userId": "user-khanh",
  "dailyGoalMinutes": 30,
  "reminderEnabled": true,
  "reminderHour": 20,
  "reminderMinute": 0,
  "timeZone": "Asia/Ho_Chi_Minh"
}
```

Ràng buộc:

- Mỗi hồ sơ có tối đa một bản ghi cài đặt.
- `userId` phải tham chiếu đến hồ sơ đang tồn tại.
- `dailyGoalMinutes` phải lớn hơn 0.
- `reminderHour` nằm trong khoảng từ 0 đến 23.
- `reminderMinute` nằm trong khoảng từ 0 đến 59.
- `timeZone` không được rỗng.

Khi hồ sơ chưa có cài đặt, repository trả về giá trị mặc định:

```text
dailyGoalMinutes = 15
reminderEnabled = false
reminderHour = 20
reminderMinute = 0
timeZone = Asia/Ho_Chi_Minh
```

## 8. Phiên luyện tập

Cấu trúc `PracticeSession`:

```json
{
  "id": "session-khanh-001",
  "userId": "user-khanh",
  "exerciseId": "exercise-hello",
  "startedAt": "2026-11-02T08:00:00.000Z",
  "endedAt": "2026-11-02T08:03:00.000Z",
  "durationSeconds": 180,
  "status": "completed"
}
```

Các trạng thái hợp lệ:

```text
completed
cancelled
analysisFailed
```

Ràng buộc:

- `id` không được rỗng và phải duy nhất.
- `userId` phải tham chiếu đến hồ sơ đang tồn tại.
- `exerciseId` không được rỗng.
- `durationSeconds` không được âm.
- `endedAt` không được trước `startedAt`.
- Phiên `completed` phải có thời lượng lớn hơn 0.
- Phiên `completed` bắt buộc có kết quả phát âm.
- Phiên `cancelled` và `analysisFailed` không được có kết quả phát âm.
- Tất cả thời gian được chuẩn hóa sang UTC.

## 9. Kết quả phát âm

Cấu trúc `PronunciationResult`:

```json
{
  "id": "result-khanh-001",
  "sessionId": "session-khanh-001",
  "referenceText": "Hello world",
  "recognizedText": "Hello world",
  "overallScore": 92.0,
  "provider": "demo-provider",
  "modelVersion": "demo-v1",
  "analyzedAt": "2026-11-02T08:04:00.000Z",
  "phonemes": []
}
```

Ràng buộc:

- `id` không được rỗng và phải duy nhất.
- `sessionId` phải khớp với ID phiên luyện tập.
- Mỗi phiên có tối đa một kết quả cuối.
- `overallScore` phải là số hữu hạn trong khoảng từ 0 đến 100.
- `provider` và `modelVersion` không được rỗng.
- Trường hợp lỗi API, audio không hợp lệ hoặc không đủ bằng chứng không được lưu dưới dạng kết quả điểm 0 hợp lệ.

## 10. Phản hồi âm vị

Cấu trúc `PhonemeFeedback`:

```json
{
  "word": "Hello",
  "expectedIpa": "həˈloʊ",
  "recognizedIpa": "həˈloʊ",
  "score": 95.0,
  "status": "correct",
  "startMilliseconds": 0,
  "endMilliseconds": 600,
  "suggestion": "Phát âm rõ và ổn định."
}
```

Các trạng thái hợp lệ:

```text
correct
needsPractice
notAssessed
```

Ràng buộc:

- `word`, `expectedIpa` và `suggestion` không được rỗng.
- `score` có thể là `null`.
- Nếu có `score`, giá trị phải nằm trong khoảng từ 0 đến 100.
- `recognizedIpa` có thể là `null`.
- `startMilliseconds` và `endMilliseconds` phải cùng tồn tại hoặc cùng bằng `null`.
- Thời điểm bắt đầu không được âm.
- Thời điểm kết thúc không được nhỏ hơn thời điểm bắt đầu.
- Trạng thái `notAssessed` được dùng khi không đủ bằng chứng để đánh giá.

## 11. Idempotency

`savePractice` là thao tác ghi nguyên tử và idempotent theo `session.id`.

Quy tắc:

- Cùng session ID và cùng nội dung: không tạo bản ghi mới.
- Cùng session ID nhưng nội dung khác: trả về `AppFailureCode.storage`.
- `result.sessionId` phải khớp `session.id`.
- Session và result được kiểm tra đầy đủ trước khi ghi.
- Store chỉ được gọi ghi sau khi toàn bộ validation thành công.
- Không được lưu session thành công nhưng result thất bại hoặc ngược lại.

## 12. Truy vấn lịch sử

`listSessions` áp dụng khoảng thời gian:

```text
[fromUtc, toUtc)
```

Trong đó:

- `fromUtc` được bao gồm.
- `toUtc` không được bao gồm.
- `fromUtc` phải nhỏ hơn `toUtc`.
- Chỉ trả phiên có `userId` đúng với hồ sơ yêu cầu.
- Kết quả được sắp theo `startedAt` mới nhất trước.

`getResult` phải kiểm tra quyền sở hữu phiên trước khi trả kết quả.

Một hồ sơ không được đọc kết quả thuộc hồ sơ khác.

## 13. Chuẩn hóa thời gian

Tất cả thời gian được lưu dưới dạng UTC ISO-8601.

Ví dụ:

```text
2026-11-02T08:00:00.000Z
```

Khi hiển thị, giao diện chuyển thời gian sang múi giờ cục bộ.

Ngày học và streak được xác định theo múi giờ của hồ sơ, mặc định:

```text
Asia/Ho_Chi_Minh
```

## 14. Serializer

`UserDataSerializers` chịu trách nhiệm chuyển đổi hai chiều cho:

- `UserProfile`
- `LearningSettings`
- `PracticeSession`
- `PronunciationResult`
- `PhonemeFeedback`

Enum được lưu bằng thuộc tính `.name`.

Dữ liệu thiếu trường, sai kiểu, enum không hợp lệ hoặc thời gian không hợp lệ được chuyển thành `AppFailureCode.storage`.

## 15. Migration

Schema hiện tại mới có version 1.

Quy trình dự kiến khi có phiên bản mới:

1. Đọc `schemaVersion`.
2. Chạy migration theo từng phiên bản liên tiếp.
3. Kiểm tra dữ liệu sau migration.
4. Chỉ ghi dữ liệu mới khi migration hoàn tất.
5. Không tự xóa dữ liệu khi migration thất bại.

Dữ liệu JSON bị hỏng sẽ tạo lỗi lưu trữ để giao diện thông báo cho người dùng.

## 16. Bảo mật và giới hạn

- Hồ sơ là hồ sơ cục bộ, không phải tài khoản đăng nhập.
- Module không triển khai xác thực người dùng.
- Không lưu khóa API hoặc token bí mật.
- Không đưa audio cá nhân hoặc dữ liệu người thử lên Git.
- Store JSON phù hợp với phạm vi bài tập và dữ liệu nhỏ.
- Nếu dữ liệu tăng lớn, cần cân nhắc chuyển sang hệ quản trị dữ liệu phù hợp hơn.
