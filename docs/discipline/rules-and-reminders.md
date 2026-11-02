# Tài liệu Kỷ luật và Tiến độ (Discipline & Progress) — Nhóm 12

> **CSE441 · Phát triển ứng dụng cho các thiết bị di động**  
> **Người thực hiện:** Lý Đình Sơn (Lớp 65KTPM)  
> **Nhánh Git:** `son-feature/discipline-progress`  
> **Phạm vi module:** `lib/features/discipline/`, `test/discipline/`, `docs/discipline/`

---

## 1. Giới thiệu chức năng

Module **Kỷ luật và tiến độ** giúp người học xây dựng và duy trì thói quen luyện phát âm tiếng Anh hằng ngày, bao gồm 4 nhóm tính năng trọng tâm:

1. **Chuỗi ngày liên tiếp (Streak 🔥):** Theo dõi số ngày luyện tập liên tục, vinh danh sự kiên trì và cảnh báo khi sắp đứt chuỗi.
2. **Vòng tiến độ mục tiêu hôm nay:** Đối chiếu thời gian luyện thực tế với mục tiêu số phút/ngày của người học (mặc định 15 phút/ngày).
3. **Biểu đồ thời lượng 7 ngày qua (*Rolling 7 days*):** Biểu đồ cột trực quan hiển thị số phút học từng ngày, tự động đổi màu khi đạt mục tiêu và 3 thẻ tóm tắt nhanh (*Chuỗi ngày, Tổng phút tuần, Số ngày đạt mục tiêu*).
4. **Cài đặt mục tiêu & Nhắc học (`ReminderService`):** Lựa chọn preset mục tiêu phút/ngày, bật/tắt thông báo và chọn giờ nhắc học với thông báo đẩy native trên Android và fallback trên Web.
5. **Thanh công cụ mô phỏng (Demo Bar):** Cho phép giáo viên / người chấm điểm mô phỏng nhanh các tình huống (+5 phút học, +15 phút đạt mục tiêu, bắn thông báo thử) để nghiệm thu trực tiếp.

---

## 2. Công thức và Quy tắc tính toán

Toàn bộ logic tính toán được đóng gói độc lập trong class `DisciplineCalculator` (`lib/features/discipline/services/discipline_calculator.dart`) với các quy tắc tuân thủ nghiêm ngặt Hợp đồng v1:

### 2.1. Quy tắc tính Ngày học & Lọc phiên hợp lệ
* **Chỉ phiên `PracticeStatus.completed` có `durationSeconds > 0` mới được tính:** Loại bỏ hoàn toàn các phiên bị hủy (`cancelled`), phiên lỗi phân tích (`analysisFailed`) hoặc thời gian chờ mạng/ứng dụng không hoạt động.
* **Thời gian UTC sang Múi giờ địa phương:** Chuyển đổi timestamp UTC của phiên học sang múi giờ người dùng (`Asia/Ho_Chi_Minh` — UTC+7) để xác định ngày dương lịch địa phương (`DateTime.utc(year, month, day)`).
* **Quy tắc phiên qua nửa đêm:** Gán phiên học cho ngày bắt đầu (`startedAt`) theo múi giờ hồ sơ.
* **Tổng hợp nhiều phiên trong ngày:** Nếu người học thực hiện nhiều phiên trong cùng một ngày, tổng thời lượng được cộng dồn, nhưng chỉ tính là **1 ngày** cho chuỗi streak.

### 2.2. Quy tắc tính Chuỗi ngày liên tiếp (Streak)
* **Streak đang tiếp diễn:**
  * Nếu hôm nay đã có ít nhất một phiên luyện hợp lệ: `Streak = 1 + số ngày liên tiếp trước đó`.
  * Nếu hôm nay chưa học, nhưng hôm qua có học: `Streak = số ngày liên tiếp tính đến hôm qua` (người dùng vẫn bảo toàn chuỗi và có hạn đến hết 23:59 hôm nay để tiếp tục).
* **Đứt chuỗi (Streak = 0):** Nếu ngày luyện tập gần nhất cũ hơn hôm qua (cách từ 2 ngày trở lên), chuỗi streak lập tức quay về 0.

### 2.3. Quy tắc Biểu đồ 7 ngày gần nhất
* Cửa sổ 7 ngày trượt: Tính từ `Hôm nay - 6 ngày` đến `Hôm nay`.
* Tỷ lệ hoàn thành ngày: $\text{ratio} = \min\left(1.0, \frac{\text{totalSeconds}}{\text{goalMinutes} \times 60}\right)$.
* Đổi màu trạng thái:
  * Đạt/vượt mục tiêu: Màu xanh lục đậm `#1B8A5A` kèm icon tích xanh.
  * Đã học nhưng chưa đạt: Màu xanh Teal `#12796F` dịu mắt.
  * Chưa học: Màu xám nhạt `#E0E5E3`.

---

## 3. Thiết kế Giao diện Thích ứng (Responsive Design)

Giao diện `ProgressPage` được thiết kế theo phong cách **Modern EdTech Cards**:
* Bo góc mềm mại 20px, bóng đổ nhẹ (`elevation: 2`, `shadowColor: black 8%`), nền thẻ trắng tinh khôi trên nền app sáng `#F5F8F7`.
* Sử dụng `LayoutBuilder` để tự động tối ưu bố cục theo kích thước màn hình:

| Viewport | Bố cục hiển thị | Chi tiết |
| :--- | :--- | :--- |
| **Mobile (< 800px)** | **1 cột cuộn dọc (Single Column)** | Thẻ Streak 🔥 $\rightarrow$ Vòng tiến độ $\rightarrow$ Biểu đồ tuần $\rightarrow$ Cài đặt & Nhắc học $\rightarrow$ Thanh Demo. |
| **Desktop / Web ($\ge$ 800px)** | **2 cột cân đối (Two-Column Grid)** | • **Cột chính (Trái, flex: 3):** Thẻ Streak, Vòng tiến độ, Biểu đồ 7 ngày.<br>• **Cột phụ (Phải, flex: 2):** Cài đặt mục tiêu, Switch & Giờ nhắc học, Thanh Demo nghiệm thu. |

---

## 4. Dịch vụ Thông báo (`ReminderService`) & Khả năng nền tảng

### 4.1. Tích hợp trên Android Native
* Sử dụng thư viện `flutter_local_notifications: ^22.3.3` và `flutter_web_plugins` (SDK Flutter để đăng ký plugin trên Web).
* Các quyền được bổ sung trong `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
  <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
  <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
  <uses-permission android:name="android.permission.USE_EXACT_ALARM" />
  <uses-permission android:name="android.permission.VIBRATE" />
  ```
* Cơ chế: Khi người dùng bật switch và chọn giờ (ví dụ `20:00`), ứng dụng gọi `ReminderService.scheduleDaily(settings)` để lên lịch hẹn giờ hệ thống Android. Khi tắt switch hoặc chuyển tài khoản, ứng dụng gọi `cancel(userId)` theo ID duy nhất.

### 4.2. Giới hạn trên Web (Documented Limitation)
* Khi chạy trên nền tảng Web (`kIsWeb`), thông báo nền khi đóng trình duyệt bị giới hạn bởi chính sách Web Push Service Worker.
* Giao diện hiển thị rõ thông báo lưu ý: *“Lưu ý trên Web: Thông báo chỉ hỗ trợ khi trình duyệt đang mở.”*

---

## 5. Kết quả Kiểm thử & Nghiệm thu (Test Matrix)

Module đã xây dựng bộ test tự động toàn diện tại `test/discipline/`, đạt **18/18 test PASS** (và 32/32 test toàn dự án PASS):

1. **`test/discipline/discipline_calculator_test.dart` (7 tests):**
   * ✅ Chuyển đổi timestamp UTC sang múi giờ `Asia/Ho_Chi_Minh` chính xác.
   * ✅ Bỏ qua các phiên `cancelled`, `analysisFailed` và phiên có thời lượng 0s.
   * ✅ Cộng dồn nhiều phiên cùng ngày thành 1 ngày streak.
   * ✅ Giữ streak nếu hôm qua có học nhưng hôm nay chưa học.
   * ✅ Reset streak về 0 khi bỏ học từ 2 ngày trở lên.
   * ✅ Tính đúng chuỗi 5 ngày liên tiếp xuyên tháng (29/10 đến 02/11).
   * ✅ Xử lý chính xác phiên học kéo dài qua nửa đêm (thuộc ngày bắt đầu).

2. **`test/discipline/reminder_service_test.dart` (5 tests):**
   * ✅ Xin quyền thông báo trả về `ReminderPermission.granted`.
   * ✅ Lên lịch nhắc nhở hằng ngày khi `reminderEnabled = true`.
   * ✅ Tự động hủy lịch khi `reminderEnabled = false`.
   * ✅ Hủy lịch theo ID người dùng.
   * ✅ Kích hoạt thông báo tức thì thành công.

3. **`test/discipline/progress_page_test.dart` (6 tests):**
   * ✅ Render giao diện không lỗi, không tràn pixel (overflow) tại màn hình Mobile hẹp **360px**.
   * ✅ Render mượt mà tại màn hình Tablet **768px**.
   * ✅ Render đúng dạng 2 cột tại Desktop **800px** và **1366px**.
   * ✅ Thao tác chọn chip đổi mục tiêu (5p, 10p, 15p, 20p, 30p) tự động cập nhật và lưu cài đặt.
   * ✅ Nút Demo `+5p học hôm nay` cộng dồn thời gian và cập nhật UI ngay lập tức.

---

## 6. Hướng dẫn chạy và nghiệm thu

### Chạy kiểm thử tự động
```bash
# Kiểm tra riêng module kỷ luật & tiến độ
flutter test test/discipline/

# Kiểm tra toàn bộ dự án
flutter test
```

### Chạy ứng dụng trên Chrome / Android
```bash
# Chạy trên trình duyệt Web (Chrome)
flutter run -d chrome

# Chạy trên thiết bị / máy ảo Android
flutter run -d <android-device-id>
```
Sau khi mở ứng dụng, chọn tab **Tiến độ** ở thanh điều hướng để xem và tương tác với giao diện đã hoàn thiện.

