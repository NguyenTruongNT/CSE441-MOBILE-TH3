# Công việc của Nguyễn Văn Trường

Nhánh: `truong-chore/project-integration`. Hạn nộp: **trước 22h00 ngày 03/11/2026 (UTC+7)**.

## Đã thực hiện theo từng commit

1. **Hợp đồng dùng chung** — `200b844`
   - Model, interface repository/service, lỗi có kiểu tại `lib/core/contracts/`.
   - Quy ước dữ liệu, ngày học, fake, ví dụ JSON tại `contracts.md`.
   - Kiểm tra phân tích Dart trước khi commit; không thêm thư viện mới.
2. **Khung ứng dụng** — `6ab1968`
   - Theme, bốn điểm vào module, điều hướng mobile/desktop tại `lib/app/`.
   - `AppPages` để ghép widget thực tế mà không sửa nội bộ module.
   - Loading/message/retry dùng chung; trang chờ tích hợp có nhãn rõ ràng.
   - Phân tích mã và smoke test đạt trước khi commit.
3. **Kiểm thử khung và hợp đồng** — `63bf050`
   - Kiểm tra điều hướng ở 320/360/768/800/1366px.
   - Chữ phóng lớn 2 lần, viewport thấp, state tab và widget module được inject.
   - Kiểm tra UTC, dữ liệu audio bất biến và dữ liệu đầu vào không hợp lệ.
   - Toàn bộ 14 test đạt trước khi commit.
4. **Cấu hình và tài liệu bàn giao** — xem commit `[Truong] docs: cập nhật cấu hình, hướng dẫn bàn giao và kết quả kiểm thử` trong Git log.
   - Tên ứng dụng Android/web, metadata và màu manifest đồng bộ.
   - Build web release và APK release của khung thành công; kết quả trong `verification.md`. Chưa nghiệm thu trên thiết bị thật.
   - Hướng dẫn chạy, kết quả kiểm tra nền và danh sách việc chờ bên dưới.
   - README phản ánh đúng trạng thái đang triển khai; sửa ví dụ nhánh theo phân công được duyệt.

Đây là lịch sử công việc kỹ thuật đã làm, không thay thế bảng trạng thái thành viên trong README. Chưa đánh dấu phần việc Trường hoàn thành toàn bộ.

## Hướng dẫn kiểm tra và push bằng CMD

Các task trên đã được commit tuần tự, không cần commit lại. Kiểm tra:

```cmd
cd /d E:\CODE\Mobile_Nhom\th3_english_ai
git branch --show-current
git status
git log -5 --oneline
flutter analyze
flutter test
flutter run -d chrome
```

Nhánh phải là `truong-chore/project-integration`. Trong ứng dụng, thử bốn mục điều hướng và đổi kích thước cửa sổ; các trang hiện tại là trang chờ, không phải chức năng học đã hoàn thiện.

Sau khi kiểm tra, push các commit lên nhánh của Trường:

```cmd
git push -u origin truong-chore/project-integration
```

Nếu Git báo remote có commit mới, chạy `git fetch origin`, xem `git log --oneline --left-right HEAD...origin/truong-chore/project-integration`, rồi xử lý đồng bộ trước; không force-push.

Trên GitHub tạo PR với base `main`, compare `truong-chore/project-integration`. Rà soát diff và kiểm tra đạt rồi Trường merge. Sau merge:

```cmd
git switch main
git pull --ff-only origin main
git switch truong-chore/project-integration
git merge main
```

Thông báo mốc nền cho thành viên sau khi merge. Các thành viên cập nhật main vào nhánh của họ trước khi bắt đầu triển khai interface. Chưa có thao tác gửi thông báo nhóm tự động.

## Quy trình bắt buộc cho task tiếp theo

1. Chọn một nhiệm vụ, chỉ sửa file thuộc phạm vi đó.
2. Format file đã đổi, chạy analyze/test phù hợp; nếu lỗi thì sửa trước.
3. Kiểm tra diff và stage đường dẫn cụ thể, tránh gom thay đổi không liên quan.
4. Commit task đó. Chỉ sau commit thành công mới bắt đầu task tiếp theo.
5. Push nhánh, gửi PR và báo nhóm khi bàn giao.

Ví dụ cho một task tài liệu sau này (không cần chạy lại cho commit đã có):

```cmd
git diff --check
git diff -- docs/coordination
git add docs/coordination
git diff --cached --stat
git commit -m "[Truong] docs: ghi nhận bàn giao module"
git push origin truong-chore/project-integration
```

Không commit khi kiểm tra còn lỗi; không dùng `--allow-empty` chỉ để tạo lịch sử task.

## Việc cần thao tác trên GitHub hoặc trong nhóm

Chưa thực hiện các hành động sau trong phiên làm việc này:

- Push các commit của Trường, tạo PR và merge vào main.
- Tạo issue giao việc. Nội dung issue đề xuất:
  - **Khanh — lưu trữ và hồ sơ:** phạm vi `user_data`; implements `UserRepository`/`LearningRepository`; nghiệm thu lưu/mở lại và tách hai hồ sơ.
  - **Đăng — phát âm AI:** phạm vi `pronunciation`; implements `PronunciationService`; nghiệm thu micro/API thật, âm vị và phản hồi có bằng chứng.
  - **Sơn — kỷ luật và tiến độ:** phạm vi `discipline`; implements `ReminderService`; nghiệm thu streak/mục tiêu và thông báo Android.
  - **Trường — tích hợp và nghiệm thu:** ghép các adapter/widget, cấu hình cần thiết, kiểm tra toàn bộ và đóng gói.
- Gán người nhận bằng tài khoản GitHub thật; xác nhận nhận việc và hạn bàn giao với từng người. Chưa có username của các thành viên nên không tự gán.
- Cấu hình bảo vệ main nếu repository hỗ trợ; thông báo và theo dõi PR.

## Việc chờ thành viên để hoàn thành sau

### Chờ Khanh

- Adapter lưu trữ, schema/migration, widget hồ sơ và lịch sử.
- Danh sách dependency và hướng dẫn chạy/reset dữ liệu.
- Trường sau bàn giao: khởi tạo repository, inject vào các trang, kiểm tra đổi user và lưu/mở lại.

### Chờ Đăng

- Adapter API, ghi âm, dữ liệu bài, widget luyện và cấu hình proxy.
- Tên dependency, codec, quyền micro, endpoint và kết quả đánh giá nhiều giọng.
- Trường sau bàn giao: thêm dependency/asset/quyền phù hợp, inject service, kiểm tra lỗi và bảo đảm không có secret trong client/Git.

### Chờ Sơn

- Widget tiến độ/cài đặt, reminder adapter và yêu cầu quyền/receiver/plugin.
- Quy tắc tính ngày/streak theo hợp đồng và bằng chứng thông báo Android.
- Trường sau bàn giao: inject dependency; phối hợp hủy/lên lịch khi đổi user; kiểm tra nền tảng thật.

### Chờ đủ ba module

- Kiểm tra chọn user → luyện thật → lưu → thống kê → mở lại → lịch sử.
- Đo AI nhiều người/giọng, xác nhận dữ liệu thực và giới hạn, thu ảnh/video.
- Build lại Android/web trên mã tích hợp; kiểm tra thiết bị và trình duyệt thực tế.
- Cập nhật README, checklist, trạng thái thành viên, PR và biên bản nghiệm thu.
- Đóng gói và nộp bài trước hạn. Bản build khung hiện tại không thay cho bản nộp hoàn chỉnh.
