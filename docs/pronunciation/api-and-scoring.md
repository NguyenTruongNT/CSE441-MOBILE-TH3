# Báo cáo kỹ thuật: API nhận dạng và Thuật toán chấm điểm âm vị AI

> **Tài liệu thiết kế cũ, chưa đạt nghiệm thu.** Backend heuristic dựa transcript đã bị chặn trả điểm; client không còn fallback sang engine này. Các mô tả GOP/căn chỉnh và chất lượng bên dưới không phải minh chứng mô hình âm vị thật. Xem [trạng thái hiện tại](../doi-chieu-th3.md).

> **Người thực hiện:** Vũ Hải Đăng  
> **Module phụ trách:** Luyện phát âm AI (`lib/features/pronunciation/`, `backend/pronunciation/`, `test/pronunciation/`)  
> **Nhánh Git:** `dang-feature/pronunciation-ai`  
> **Hạn nộp:** Trước 22h00 ngày 03/11/2026

---

## 1. Tổng quan kiến trúc Module

Module **Phát âm AI** cung cấp giải pháp toàn diện cho người học tiếng Anh (đặc biệt là người học Việt Nam) với chu trình khép kín:

```
[Chọn bài / Nghe mẫu]
       │
       ▼
[Thu âm giọng nói] ──(Kiểm định tín hiệu / RMS)──► [Hủy nếu im lặng / lỗi]
       │ (Hợp lệ)
       ▼
[Gọi API / Proxy AI] ──► [Phân tích âm học GOP & Căn chỉnh âm vị IPA]
       │
       ▼
[Chuẩn hóa điểm 0–100 + Phản hồi lỗi chi tiết ngoài màu sắc]
       │
       ▼
[Gợi ý bài tập cải thiện theo âm yếu] ──► [Lưu phiên & kết quả vào LearningRepository]
```

Module tuân thủ tuyệt đối hợp đồng dữ liệu chuẩn tại `lib/core/contracts/contracts.dart`:
- Triển khai interface `PronunciationService`.
- Trả về đối tượng `PronunciationResult` với danh sách `PhonemeFeedback`.
- Lưu trữ kết quả thông qua `LearningRepository.savePractice(...)`.

---

## 2. Kiểm định âm thanh và lọc nhiễu (Audio Validation)

Trước khi gửi dữ liệu âm thanh đến máy chủ hoặc bộ phân tích, lớp `AudioValidator` kiểm tra:
1. **Kiểm tra dữ liệu rỗng:** Đảm bảo byte mảng `AudioSample.bytes` không rỗng và có dung lượng tối thiểu 128 bytes.
2. **Kiểm tra định dạng (MIME):** Chấp nhận `audio/wav`, `audio/webm`, `audio/ogg`, `audio/aac`, `audio/mp4`.
3. **Ước tính thời lượng:**
   - Từ chối các bản ghi $< 0.4\text{s}$ (`insufficientEvidence`) vì không đủ mẫu âm học để phân tích âm vị.
   - Từ chối các bản ghi $> 60\text{s}$ (`invalidAudio`).
4. **Phát hiện im lặng (RMS Energy Check):**
   Tính giá trị Root Mean Square (RMS) của tín hiệu PCM 16-bit:
   $$RMS = \sqrt{\frac{1}{N} \sum_{i=1}^{N} \left(\frac{x_i}{32768}\right)^2}$$
   Nếu $RMS < 0.008$, hệ thống xác định người dùng im lặng hoặc tắt micro, từ chối chấm điểm và ném ngoại lệ `AppFailure(AppFailureCode.insufficientEvidence, ...)` thay vì trả về điểm 0 giả mạo.

---

## 3. Thuật toán chấm điểm âm vị GOP (Goodness of Pronunciation)

### 3.1. Nguyên lý phân tích
Hệ thống kết hợp mô hình âm học với bảng đặc trưng phát âm (Phonetic Features) chuẩn quốc tế IPA:
- **Tần số cắt ngang số 0 (Zero-Crossing Rate - ZCR):** Xác định các âm xát vô thanh như $/s/$, $/ʃ/$, $/θ/$, $/f/$ (ZCR cao) đối chiếu với các nguyên âm hoặc âm hữu thanh (ZCR thấp).
- **Phổ năng lượng RMS:** Đo độ duy trì độ dài của nguyên âm dài ($/iː/$) so với nguyên âm ngắn ($/ɪ/$).
- **Căn chỉnh thời gian:** Tính toán chính xác cặp mốc thời gian `startMilliseconds` và `endMilliseconds` cho từng âm vị trong chuỗi âm tiết.

### 3.2. Công thức tính điểm GOP âm vị
Đối với từng âm vị mục tiêu $p$:
$$\text{Score}(p) = \text{clamp}\left(30.0, 98.0, \text{Base} + \Delta_{\text{ZCR}}(p) + \Delta_{\text{RMS}}(p) + \Delta_{\text{Duration}}(p) + \text{Bias}\right)$$

Trong đó:
- $\text{Base} = 82.0$ (điểm chuẩn cơ sở).
- $\Delta_{\text{ZCR}}(p)$: Độ khớp tần số xát vô thanh. Nếu phát âm nhầm $/θ/$ thành $/s/$ (quá xát dẹt) hoặc $/t/$ (ngắt hơi đột ngột), điểm bị trừ.
- $\Delta_{\text{Duration}}(p)$: Phạt nặng đối với cụm phụ âm đuôi (như $/skt/$, $/ks/$, $/st/$) nếu thời lượng ngắt từ quá ngắn (người Việt hay nuốt âm đuôi).

### 3.3. Phân loại trạng thái âm vị
- $\text{Score}(p) \ge 75.0$: `PhonemeStatus.correct` (Âm vị đạt chuẩn).
- $\text{Score}(p) < 75.0$: `PhonemeStatus.needsPractice` (Âm vị cần luyện lại).
- Thiếu bằng chứng / âm lượng quá nhỏ: `PhonemeStatus.notAssessed`.

### 3.4. Điểm tổng thể (Overall Score)
Điểm tổng thể được tính theo bình quân trọng số các âm vị, áp dụng hệ số phạt nếu người học phát âm sai các **âm mục tiêu trọng tâm** của bài học:
$$\text{OverallScore} = \text{clamp}\left(20.0, 98.0, \overline{\text{Score}_{\text{phonemes}}} - 2.5 \times N_{\text{missed\_critical}}\right)$$

---

## 4. Chú giải lỗi trợ năng ngoài màu sắc (Non-color Cues)

Tuân thủ nghiêm ngặt nguyên tắc trợ năng WCAG và yêu cầu đề tài, giao diện không chỉ dùng màu xanh/đỏ:
1. **Biểu tượng trực quan:**
   - Chuẩn ($\ge 80$): Icon `check_circle_rounded`.
   - Khá ($60 - 79$): Icon `warning_amber_rounded`.
   - Cần luyện thêm ($< 60$): Icon `error_outline_rounded`.
2. **Nhãn chữ rõ ràng:** "Rất tốt", "Khá - Cần lưu ý", "Cần luyện thêm".
3. **Phân tích âm học hiển thị:** Tỉ lệ % GOP, mốc thời gian `120ms – 340ms`, phiên âm nhận dạng đối chiếu (ví dụ: mong đợi $/θ/ \rightarrow$ nhận dạng $[s]$).
4. **Hướng dẫn khẩu hình bằng tiếng Việt:** Hướng dẫn chi tiết vị trí đặt đầu lưỡi, độ mở khóe miệng, luồng hơi và độ rung dây thanh quản.

---

## 5. Đề xuất bài tập cải thiện tự động

Sau mỗi phiên đánh giá, engine tự động quét qua danh sách âm vị gắn nhãn `needsPractice`. Dựa vào tập hợp các âm yếu, hệ thống tra cứu trong giáo trình `DefaultExercises.catalog` và đề xuất các bài học mục tiêu trực tiếp cho âm vị đó:
- Ví dụ: Người học phát âm sai âm $/θ/$ trong *"I think this method is great"* $\rightarrow$ Hệ thống đề xuất bài luyện *"They breathe together in the weather"* hoặc các bài chuyên sâu về âm xát răng.
- Nút bấm **"Luyện ngay bài tập này"** cho phép học viên chuyển sang bài mới ngay tức thì.

---

## 6. Hướng dẫn chạy Máy chủ Proxy (`backend/pronunciation/`)

Khi kết nối với các API dịch vụ phát âm đám mây (SpeechACE, Azure Speech Pronunciation Assessment, Google Cloud Speech, OpenAI Whisper), khóa API bí mật được bảo vệ tại máy chủ proxy, **tuyệt đối không đưa vào mã nguồn Flutter hay Git**.

### 6.1. Khởi động Proxy bằng Dart SDK
```bash
# Di chuyển vào thư mục gốc dự án
cd CSE441-MOBILE-TH3

# Chạy server proxy trực tiếp
dart run backend/pronunciation/bin/server.dart
```

### 6.2. Cấu hình biến môi trường
File mẫu tại `backend/pronunciation/.env.example`:
```ini
PORT=8080
SPEECH_PROVIDER=local-acoustic-gop
SPEECH_API_KEY=your_upstream_secret_key_here
PHONEME_CORRECT_THRESHOLD=75.0
```

### 6.3. API Endpoints
- `GET /health`: Kiểm tra trạng thái máy chủ.
- `POST /api/pronounce/analyze`: Nhận JSON kèm `audioBase64` và trả về kết quả cấu trúc `PronunciationResult`.

---

## 7. Bảng mã lỗi có kiểu (`AppFailureCode`)

| Mã lỗi (`AppFailureCode`) | Nguyên nhân kích hoạt | Phản ứng của hệ thống trên giao diện |
| :--- | :--- | :--- |
| `permissionDenied` | Người dùng từ chối quyền micro | Hiển thị thẻ thông báo lỗi quyền kèm nút "Cấp quyền" |
| `insufficientEvidence` | Ghi âm $< 0.4\text{s}$ hoặc âm lượng im lặng ($RMS < 0.008$) | Báo rõ: *"Không phát hiện tín hiệu giọng nói"*, cho phép thu âm lại |
| `invalidAudio` | File âm thanh hỏng, định dạng không hỗ trợ | Báo lỗi định dạng và hủy phiên |
| `network` | Mất kết nối tới Proxy/API | Báo lỗi mạng; kích hoạt cơ chế Fallback phân tích cục bộ |
| `timeout` | Quá thời gian phản hồi ($> 12\text{s}$) | Thông báo timeout và nút thử lại |

---

## 8. Hướng dẫn Nhóm trưởng (Trường) ghép nối

Tại composition root `lib/main.dart` hoặc `lib/app/app.dart`:
```dart
import 'package:th3_english_ai/features/pronunciation/pronunciation.dart';

// Khởi tạo service
final pronunciationService = RemotePronunciationService(
  endpoint: Uri.parse('http://127.0.0.1:8080/api/pronounce/analyze'),
  enableLocalFallbackWhenUnreachable: true, // Tự động fallback nếu proxy tắt
);

// Hoặc dùng fake service khi chạy thử nghiệm:
// final pronunciationService = FakePronunciationService();

// Ghép vào AppPages:
PronunciationPage(
  userRepository: users,
  learningRepository: learning,
  pronunciationService: pronunciationService,
)
```
Màn hình có sẵn cơ chế nội suy fallback tự động, có thể chạy hoàn toàn độc lập nếu không truyền đối số constructor.

