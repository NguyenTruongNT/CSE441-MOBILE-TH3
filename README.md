# TH3: Ứng dụng học tiếng Anh với phân tích phát âm AI

> **CSE441 · Phát triển ứng dụng cho các thiết bị di động**
>
> Lớp **65KTPM** · Nhóm **12** · Flutter · Android & Web

> **Hạn nộp: trước 22h00 ngày 03/11/2026 — giờ Việt Nam (UTC+7).**

> **Trạng thái hiện tại:** Đã có khung ứng dụng và hợp đồng module; chưa tích hợp CSDL, phát âm AI và nhắc học thực tế. Phân công đã được người dùng duyệt; xác nhận nhận việc của từng thành viên được thực hiện trong nhóm.

**Điều hướng nhanh**

[Giới thiệu](#gioi-thieu) · [Phân công & trạng thái](#phan-cong) · [Thư mục & nhiệm vụ](#nhiem-vu) · [Hợp đồng module](#hop-dong) · [CSDL](#csdl) · [Checklist](#checklist) · [Git & bàn giao](#git) · [Cài đặt](#cai-dat) · [Sử dụng](#su-dung) · [Kiểm thử](#kiem-thu) · [Chốt bài nộp](#nop-bai)

---

<a id="gioi-thieu"></a>

## 1. Giới thiệu đề tài

Ứng dụng giúp người học duy trì thói quen luyện tiếng Anh và cải thiện phát âm, gồm hai nhóm chức năng:

- Kỷ luật học tập: nhắc luyện hằng ngày, mục tiêu số phút/ngày, chuỗi ngày luyện liên tiếp (streak), thống kê thời gian và tiến độ.
- Phát âm AI: ghi âm, nhận dạng giọng nói, so sánh âm vị với phiên âm chuẩn, chấm điểm, đánh dấu lỗi và đề xuất bài tập cải thiện.

Ứng dụng lưu hồ sơ, lịch sử luyện tập và kết quả phân tích qua các lần mở lại. Nền tảng hiện có là Flutter. Phạm vi dự kiến: Android và web với giao diện thích ứng màn hình mobile/desktop. Desktop ở đây là web trên máy tính; chưa đặt phạm vi ứng dụng Windows native. Khả năng micro và thông báo phải kiểm tra riêng trên từng nền tảng.

<a id="phan-cong"></a>

## 2. Phân công và trạng thái công việc

Đây là bảng theo dõi công việc chung của nhóm. Nhiệm vụ chi tiết và thư mục thực hiện được trình bày tại mục 3.

| Thành viên | Công việc phụ trách | Sản phẩm bàn giao | Nhánh Git | Trạng thái |
| :--- | :--- | :--- | :--- | :---: |
| **Nguyễn Văn Trường**<br>Nhóm trưởng | Phân chia, điều phối; hợp đồng chung; khung ứng dụng; review, merge và tích hợp | Đã có hợp đồng v1, khung thích ứng, 14 test đạt và tài liệu bàn giao. [Chi tiết & việc chờ](docs/coordination/truong-tasks.md). Chờ ghép module thật, kiểm thử toàn bộ và hồ sơ nộp. | `truong-chore/project-integration` | 🟡 Đang làm |
| **Vũ Tuấn Khanh** | CSDL, lưu trữ, hồ sơ người dùng và lịch sử | Schema/migration, repository, màn hình hồ sơ/lịch sử, kiểm thử dữ liệu | `khanh-feature/user-data` | ⬜ Chưa bắt đầu |
| **Vũ Hải Đăng** | Thu âm, API nhận dạng, phân tích âm vị, chấm điểm và phản hồi | Luồng luyện phát âm, điểm/âm vị sai, bài tập cải thiện, đánh giá nhiều giọng | `dang-feature/pronunciation-ai` | ⬜ Chưa bắt đầu |
| **Lý Đình Sơn** | Mục tiêu, streak, thống kê và nhắc học | Dashboard, cài đặt mục tiêu/nhắc học, kiểm thử quy tắc ngày học | `son-feature/discipline-progress` | ⬜ Chưa bắt đầu |

**Quy ước trạng thái:** ⬜ Chưa bắt đầu · 🟡 Đang làm · 🔴 Bị vướng · 🔵 Chờ review · ✅ Hoàn thành.

Trạng thái phản ánh phần triển khai được giao, không tính riêng việc soạn tài liệu. Thành viên báo thay đổi trong nhóm; Trường cập nhật bảng và chỉ đánh dấu **Hoàn thành** sau khi nghiệm thu, kiểm thử và merge. Khi có PR hoặc minh chứng, bổ sung liên kết tại ô sản phẩm bàn giao.

Mỗi người phụ trách cả giao diện, xử lý và kiểm thử trong module của mình. Không tự sửa phần của người khác. Nhóm trưởng điều phối và tích hợp, không nhận làm thay thường xuyên các chức năng đã giao.

**Độc lập nghĩa là có thể phát triển và kiểm thử bằng dữ liệu giả theo hợp đồng chung.** Ứng dụng hoàn chỉnh vẫn cần ghép các module; không thể bảo đảm mọi chức năng không có phụ thuộc.

<a id="nhiem-vu"></a>

## 3. Thư mục thực hiện của từng thành viên

Đã có `lib/app/`, `lib/core/contracts/`, `test/integration/` và `docs/coordination/` của Trường. Các thư mục module còn lại do thành viên tự tạo theo phân công sau đây:

```text
lib/
  main.dart                      # Trường
  app/                           # Trường: điều hướng, theme, layout, ghép dependency
  core/contracts/                # Trường: model và interface dùng chung
  features/
    user_data/                   # Khanh: CSDL, hồ sơ, lịch sử
    pronunciation/               # Đăng: ghi âm, AI, điểm và phản hồi
    discipline/                  # Sơn: mục tiêu, streak, thống kê, nhắc học
test/
  integration/                   # Trường
  user_data/                     # Khanh
  pronunciation/                 # Đăng
  discipline/                    # Sơn
docs/
  coordination/                  # Trường
  user_data/                     # Khanh
  pronunciation/                 # Đăng
  discipline/                    # Sơn
assets/
  pronunciation/                 # Đăng: bài học, IPA, âm mẫu hợp lệ
backend/
  pronunciation/                 # Đăng: proxy nếu API cần khóa bí mật
```

### Nguyễn Văn Trường — nhóm trưởng

- Tạo/sửa `lib/app/`, `lib/core/contracts/`, `test/integration/`, `docs/coordination/`, `lib/main.dart` và README.
- Chốt chữ ký Dart, model và ví dụ dữ liệu tại `docs/coordination/contracts.md` trước khi các module triển khai; công bố mốc mã nguồn nền cho mọi người.
- Làm khung điều hướng tới Tiến độ, Luyện phát âm, Lịch sử, Hồ sơ; cung cấp theme và layout thích ứng chung.
- Ghép repository/service vào module, quản lý cấu hình môi trường và dependency.
- Theo dõi issue, tháo gỡ vướng mắc, review và là người duy nhất merge nhánh chung.
- Kiểm thử toàn bộ luồng, tổng hợp minh chứng, build và nộp bài đúng hạn.

**Trường quản lý riêng các file dễ xung đột:** `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `.gitignore`, `test/widget_test.dart`, cấu hình `android/`, `ios/`, `web/` và CI nếu có. Thành viên ghi dependency, asset và quyền cần thêm trong tài liệu module; Trường cập nhật. Không tự sửa nội dung nội bộ module khác nếu chưa thống nhất với chủ module.

### Vũ Tuấn Khanh — dữ liệu và người dùng

- Tự tạo/làm trong `lib/features/user_data/`, `test/user_data/`, `docs/user_data/`.
- Thiết kế schema, quan hệ, ràng buộc và migration; chọn lưu trữ bền vững hỗ trợ Android/web, thống nhất với Trường trước khi thêm thư viện.
- Cài đặt repository theo hợp đồng; tạo/chọn/sửa hồ sơ, tách dữ liệu người dùng, xem lịch sử và kết quả đã lưu.
- Lưu phiên và kết quả nhất quán; chống lưu trùng theo ID khi thử lại thao tác.
- Tạo dữ liệu giả trong module để tự phát triển màn hình; không cần chờ module AI.
- Bàn giao `docs/user_data/schema.md`, cách khởi tạo/reset dữ liệu và kết quả test lưu/mở lại với ít nhất hai hồ sơ.
- Phạm vi tối thiểu là hồ sơ cục bộ. Không ghi là đăng nhập an toàn nếu chưa xây dựng xác thực.
- Không sửa module AI, discipline hoặc file dùng chung.

### Vũ Hải Đăng — phát âm AI và phản hồi

- Tự tạo/làm trong `lib/features/pronunciation/`, `test/pronunciation/`, `docs/pronunciation/`, `assets/pronunciation/`, `backend/pronunciation/` nếu cần.
- Làm chọn bài, văn bản/IPA, nghe mẫu, xin quyền micro, ghi âm và gọi API nhận dạng thực tế.
- Dùng dịch vụ đánh giá phát âm có kết quả âm vị hoặc mô hình/thuật toán căn chỉnh âm thanh với âm vị chuẩn để chấm điểm.
- Không lấy riêng độ giống transcript hoặc confidence nhận dạng để kết luận âm vị sai. Nếu API chỉ có transcript, cần bổ sung phân tích âm vị; không tự bịa lỗi âm.
- Chuẩn hóa điểm 0–100; hiển thị điểm tổng, từ/âm cần luyện, phiên âm chuẩn và bài tập theo lỗi. Phân biệt kết quả thật, dữ liệu giả và trường hợp không đủ bằng chứng để chấm.
- Xử lý từ chối micro, im lặng, mất mạng, timeout, audio không hợp lệ và lỗi API.
- Tạo fake service/repository nội bộ để chạy độc lập. Bản nghiệm thu phải chạy được API thật.
- Nếu API cần secret, triển khai proxy trong `backend/pronunciation/`; không đưa khóa vào Flutter/web/Git.
- Bàn giao `docs/pronunciation/api-and-scoring.md` và `evaluation.md`: dịch vụ/mô hình thực dùng, cách tính điểm, biến môi trường mẫu, lệnh chạy proxy nếu có, giới hạn và đánh giá nhiều giọng.
- Không sửa CSDL, discipline hoặc file dùng chung.

### Lý Đình Sơn — kỷ luật và tiến độ

- Tự tạo/làm trong `lib/features/discipline/`, `test/discipline/`, `docs/discipline/`.
- Làm dashboard thời gian học ngày/tuần, mục tiêu số phút/ngày, streak và cấu hình nhắc học.
- Dùng repository qua hợp đồng, tạo fake repository nội bộ để không cần chờ Khanh.
- Xin quyền thông báo, bật/tắt, chọn giờ, hủy/lên lịch lại; tránh tạo thông báo trùng. Nghiệm thu nhắc hằng ngày thực tế trên Android.
- Kiểm tra hỗ trợ thông báo trên web. Nếu chỉ nhắc khi ứng dụng đang mở thì ghi rõ; không tuyên bố nhắc nền khi trình duyệt đóng nếu chưa triển khai được.
- Kiểm thử nhiều phiên cùng ngày, ngày liên tiếp, bỏ ngày, qua nửa đêm, đổi hồ sơ/mục tiêu/giờ nhắc.
- Bàn giao `docs/discipline/rules-and-reminders.md`, công thức và bằng chứng test.
- Không sửa CSDL, AI hoặc file dùng chung.

<a id="hop-dong"></a>

## 4. Hợp đồng để các module làm độc lập

Hợp đồng v1 đã có tại [`lib/core/contracts/contracts.dart`](lib/core/contracts/contracts.dart); chữ ký và quy ước ở [`docs/coordination/contracts.md`](docs/coordination/contracts.md). Các thành viên triển khai interface bên dưới; adapter nghiệp vụ chưa được bàn giao:

| Thành phần | Nội dung tối thiểu | Phụ trách |
| --- | --- | --- |
| `UserProfile` | ID, tên, múi giờ, ngày tạo | Trường định nghĩa; Khanh lưu và làm UI |
| `PracticeSession` | ID, userId, exerciseId, bắt đầu/kết thúc UTC, durationSeconds, trạng thái | Trường định nghĩa; Đăng phát sinh; Khanh lưu |
| `PronunciationResult` | ID, sessionId, văn bản chuẩn/nhận dạng, điểm, nguồn/mô hình, phản hồi âm vị | Trường định nghĩa; Đăng phân tích; Khanh lưu |
| `PhonemeFeedback` | Từ, IPA chuẩn, âm nhận dạng nếu có, điểm/trạng thái, khoảng thời gian nếu có, gợi ý | Trường định nghĩa; Đăng tạo |
| `LearningSettings` | userId, mục tiêu phút/ngày, bật nhắc, giờ/phút, múi giờ | Trường định nghĩa; Sơn xử lý; Khanh lưu |
| `UserRepository` | Tạo/đọc/cập nhật/chọn hồ sơ | Khanh cài đặt |
| `LearningRepository` | Lưu phiên và kết quả; đọc lịch sử theo user/khoảng ngày; đọc/ghi cài đặt | Khanh cài đặt |
| `PronunciationService` | Audio + nội dung chuẩn → kết quả hoặc lỗi có kiểu | Đăng cài đặt |
| `ReminderService` | Xin quyền, đặt lịch và hủy lịch theo hồ sơ | Sơn cài đặt |

Quy tắc kết nối:

- Module chỉ import mã của mình và `core/contracts`, không import trực tiếp module khác. Trường truyền dependency từ `app/` qua constructor.
- Mỗi module có fake để chạy/test riêng; không dùng fake làm bằng chứng AI thật hoặc dữ liệu nghiệm thu.
- Đăng gọi repository lưu khi luyện xong; Khanh thực hiện lưu; Sơn đọc dữ liệu để tính tiến độ. Không viết lại chức năng của nhau.
- Mỗi phiên chỉ lưu một lần theo `sessionId`. Thời gian học là thời gian luyện thực tế, loại thời gian chờ API và để ứng dụng không hoạt động.
- Lưu thời gian UTC, quy đổi ngày theo múi giờ hồ sơ, mặc định `Asia/Ho_Chi_Minh`; không cắt ngày trực tiếp từ chuỗi UTC.
- Ngày có ít nhất một phiên hoàn thành với thời lượng luyện lớn hơn 0 là ngày luyện. Đạt mục tiêu phút/ngày là chỉ số riêng.
- Nhiều phiên cùng ngày chỉ tính một ngày streak. Streak hiện tại kết thúc ở hôm nay hoặc hôm qua; nếu ngày luyện gần nhất cũ hơn hôm qua thì bằng 0.
- API lỗi/không đủ audio phải có trạng thái riêng, không lưu điểm 0 như kết quả AI hợp lệ.
- Thay đổi hợp đồng phải qua Trường và thông báo cả nhóm; chủ module sửa triển khai tương ứng.

<a id="csdl"></a>

## 5. Thiết kế CSDL dự kiến

Khanh hoàn thiện schema vật lý, index, migration và công nghệ lưu trữ sau khi chốt hợp đồng.

| Bảng/thực thể | Nội dung | Ràng buộc chính |
| --- | --- | --- |
| `users` | ID, tên, múi giờ, ngày tạo | ID duy nhất |
| `learning_settings` | User, mục tiêu phút, bật nhắc, giờ nhắc | Một bản ghi/user; mục tiêu dương, giờ hợp lệ |
| `exercises` | Văn bản, IPA, độ khó, âm mẫu/tham chiếu | ID duy nhất; có thể seed từ asset |
| `practice_sessions` | User, bài, thời điểm, thời lượng, trạng thái | Khóa ngoại; thời lượng không âm; chống lưu trùng |
| `pronunciation_results` | Phiên, transcript, điểm, nguồn phân tích | Một kết quả cuối/phiên; điểm 0–100 |
| `phoneme_feedback` | Kết quả, thứ tự từ/âm, IPA, điểm/trạng thái, gợi ý | Nhiều phản hồi/kết quả; giữ thứ tự âm |

Streak/thống kê tính từ phiên học; nếu cache phải tính lại được. Không lưu secret trong CSDL ứng dụng. Chỉ giữ audio khi có nhu cầu và người thử đồng ý; không đưa giọng nói cá nhân lên Git.

<a id="checklist"></a>

## 6. Đối chiếu 7 mục checklist

Chỉ đánh dấu hoàn thành sau khi chạy được và có minh chứng.

| Xong | Yêu cầu | Chủ trì | Điều kiện nghiệm thu |
| --- | --- | --- | --- |
| [ ] | CSDL người dùng, lịch sử, kết quả | Khanh | Có schema, dữ liệu riêng từng user và còn sau mở lại |
| [ ] | Streak, thời gian, mục tiêu | Sơn | Đúng quy tắc ngày; không đếm trùng; lưu mục tiêu |
| [ ] | Thu âm và API nhận dạng | Đăng | Micro thật → API thật → transcript; xử lý lỗi/quyền |
| [ ] | Phân tích âm vị và chấm điểm | Đăng | Có âm vị chuẩn, phân tích audio và cách tính điểm rõ |
| [ ] | Điểm, âm sai, bài tập cải thiện | Đăng | Phản hồi bám kết quả thật; chú giải lỗi ngoài màu sắc |
| [ ] | Nhắc hằng ngày và giao diện tiến độ | Sơn | Nhắc thực tế Android; tiến độ dữ liệu thật; rõ giới hạn web |
| [ ] | Nhiều người dùng và giọng nói | Trường tổng hợp, Đăng đánh giá AI | Có ma trận thử, số liệu thực, lỗi và giới hạn |

Yêu cầu chung: giao diện không tràn ở mobile/desktop, điều hướng hoàn chỉnh, dữ liệu bền vững, không lộ khóa API.

<a id="git"></a>

## 7. Quản lý dự án và Git

Repository: [NguyenTruongNT/CSE441-MOBILE-TH3](https://github.com/NguyenTruongNT/CSE441-MOBILE-TH3). Các task nền của Trường được commit riêng trên `truong-chore/project-integration`; lịch sử và hướng dẫn push/PR ở [tài liệu bàn giao](docs/coordination/truong-tasks.md). Quy trình làm việc:

1. Trường tạo issue với người sở hữu, phạm vi thư mục, sản phẩm, điều kiện nghiệm thu và hạn bàn giao; công bố nhánh nền.
2. Mỗi thành viên làm trên nhánh riêng đã ghi trong bảng phân công tại mục 2.
3. Chỉ commit file thuộc phạm vi. Kiểm tra `git status`; không commit secret, audio cá nhân, dữ liệu người thử, build hoặc cấu hình IDE phát sinh.
4. Thành viên tự push nhánh và mở PR vào `main`, kèm chức năng, cách chạy, kết quả test, lỗi còn lại và cấu hình cần thêm.
5. **Trường là người review và merge.** Không push trực tiếp `main`, không tự merge, không force-push nhánh chung. Bật bảo vệ nhánh nếu cấu hình repository cho phép.
6. Trường thông báo bản tích hợp sau merge; thành viên cập nhật mã nền trước vòng sửa tiếp theo. Lỗi thuộc module nào do chủ module đó sửa.

Ví dụ sau khi remote đã được thiết lập, dành cho Khanh; các thành viên khác thay bằng nhánh/thư mục được giao:

```bash
git switch main
git pull --ff-only origin main
git switch -c khanh-feature/user-data
# Thực hiện và kiểm tra công việc.
git status
git add lib/features/user_data test/user_data docs/user_data
git commit -m "feat(user-data): add user profiles and history"
git push -u origin khanh-feature/user-data
```

Chỉ tạo nhánh lần đầu; các lần sau chuyển về nhánh đã có. Kiểm tra `git remote -v` trước khi push để bảo đảm đúng repository.

### Thông báo bắt buộc trong nhóm

Mỗi người chủ động cập nhật trạng thái khi có thay đổi. **Hoàn thành nhiệm vụ phải thông báo ngay vào nhóm để các thành viên khác nắm được**, không chỉ push code. Nếu vướng mắc có nguy cơ trễ hạn, báo ngay cho Trường.

```text
[BÀN GIAO] Họ tên — Nhiệm vụ
Nhánh/PR/commit: ...
Thư mục đã sửa: ...
Chức năng hoàn thành: ...
Cách chạy và kết quả kiểm thử: ...
Dependency/quyền/cấu hình cần nhóm trưởng thêm: ...
Lỗi còn lại hoặc yêu cầu phối hợp: ...
```

<a id="cai-dat"></a>

## 8. Cài đặt và chạy

### Dự án hiện tại

Cần Flutter SDK kèm Dart thỏa `^3.13.2` trong `pubspec.yaml`, Git, Android SDK/emulator hoặc thiết bị Android; Chrome cho web. Kiểm tra môi trường trước khi thay đổi ràng buộc SDK.

Tại thư mục gốc `th3_english_ai`:

```bash
flutter --version
flutter doctor
flutter pub get
flutter devices
flutter run -d chrome
```

Chạy Android với ID lấy từ `flutter devices`:

```bash
flutter run -d <device-id>
```

**Hiện các lệnh này chạy khung English AI**, gồm Tiến độ, Luyện phát âm, Lịch sử và Hồ sơ. Dưới 800px có điều hướng dưới; từ 800px có thanh bên. Mỗi trang ghi rõ đang chờ tích hợp, chưa thu âm/chấm điểm/lưu dữ liệu/nhắc học. Bản khung không cần khóa API hay backend.

Đã phân tích mã và chạy **14/14 test đạt**. Xem phạm vi kiểm tra và kết quả build tại [verification.md](docs/coordination/verification.md); chưa nghiệm thu thiết bị thật hoặc luồng nghiệp vụ.

### Cấu hình bản hoàn chỉnh

- Khanh ghi khởi tạo, vị trí lưu và reset dữ liệu trong `docs/user_data/`.
- Đăng ghi biến môi trường mẫu, endpoint và lệnh chạy proxy nếu cần trong `docs/pronunciation/`. Khóa thật chỉ đặt ở môi trường máy chủ, không nhúng vào Flutter/web qua `--dart-define`.
- Sơn ghi cấp quyền và kiểm tra thông báo trong `docs/discipline/`.
- Trường cập nhật dependency/asset/quyền, hướng dẫn chạy đầy đủ và kiểm tra trên máy sạch trước nộp.

Các lệnh kiểm tra/build sau triển khai:

```bash
flutter analyze
flutter test
flutter build apk --release
flutter build web --release
```

Kiểm thử cần thiết bị/backend có hướng dẫn riêng do Trường bổ sung. `flutter test` không thay thế kiểm tra micro, API và thông báo thật.

<a id="su-dung"></a>

## 9. Cách sử dụng dự kiến sau hoàn thiện

1. Tạo/chọn hồ sơ và đặt mục tiêu số phút/ngày.
2. Bật nhắc học, chọn giờ, cấp quyền thông báo.
3. Vào Luyện phát âm, chọn bài, xem nội dung/IPA và nghe mẫu.
4. Cấp quyền micro, ghi âm, dừng và gửi phân tích.
5. Xem điểm, âm vị cần cải thiện, làm bài tập gợi ý và luyện lại.
6. Xem Lịch sử và Tiến độ để theo dõi kết quả, thời gian, mục tiêu và streak.
7. Chuyển hồ sơ và mở lại ứng dụng để kiểm tra dữ liệu riêng, lưu trữ bền vững.

Đây là luồng nghiệm thu sau tích hợp, chưa sử dụng được trên bản khung hiện tại. Hiện có thể mở ứng dụng, chuyển bốn mục và kiểm tra bố cục mobile/desktop.

<a id="kiem-thu"></a>

## 10. Kiểm thử và minh chứng

| Nhóm | Ca kiểm thử tối thiểu | Chủ trì | Minh chứng |
| --- | --- | --- | --- |
| Dữ liệu | Hai hồ sơ, chuyển user, mở lại, chống lưu trùng | Khanh | Test và kết quả chạy |
| Thời gian | Cùng ngày, liên tiếp, bỏ ngày, nửa đêm, khác user | Sơn | Test với đồng hồ giả và kết quả kỳ vọng |
| Micro/API | Cho/từ chối quyền, im lặng, audio lỗi, mất mạng, API lỗi | Đăng | Log đã bỏ dữ liệu nhạy cảm và video/ảnh |
| Nhiều giọng | Ít nhất 4 người đồng ý tham gia, giọng/mức phát âm khác nhau, cùng bộ ít nhất 10 từ/câu có âm mục tiêu | Đăng tổ chức, cả nhóm tham gia | Mã người thử ẩn danh, điểm AI, nhận xét người nghe, sai lệch |
| Nhắc học | Cấp/từ chối quyền, đổi giờ, tắt, khởi động lại, tránh lịch trùng | Sơn | Giờ nhận thật, nền tảng và trạng thái ứng dụng |
| Responsive | Web rộng 360px, 768px, 1366px và Android | Trường tổng hợp, chủ module sửa | Ảnh màn hình chính, kiểm tra tràn/thao tác |
| Toàn bộ luồng | Chọn user → luyện thật → lưu → thống kê → mở lại → lịch sử | Trường | Video và biên bản nghiệm thu |

Đánh giá AI phải đối chiếu âm mục tiêu với nhận xét người nghe, ghi trường hợp nhận nhầm/chấm không ổn định và giới hạn. Không điền số liệu hoặc khẳng định độ chính xác khi chưa đo. Bộ thử nhỏ phục vụ bài tập, không đại diện mọi giọng tiếng Anh.

<a id="nop-bai"></a>

## 11. Điều kiện chốt bài nộp

- [x] Người dùng đã duyệt phân công.
- [ ] Từng thành viên xác nhận nhận việc trong nhóm.
- [ ] Chốt hợp đồng, API, dependency; từng module chạy/test được bằng fake riêng.
- [ ] Đủ 7 mục checklist với minh chứng thực tế.
- [ ] Thành viên đã thông báo bàn giao; Trường review và merge.
- [ ] Android và web chạy được; giao diện mobile/desktop sử dụng tốt.
- [ ] Có hướng dẫn cài/chạy thực tế, cấu hình mẫu không có secret, schema và báo cáo test.
- [ ] README cập nhật tiến độ thật và các giới hạn còn lại.
- [ ] Trường kiểm tra gói nộp và nộp **trước 22h00 ngày 03/11/2026**.
