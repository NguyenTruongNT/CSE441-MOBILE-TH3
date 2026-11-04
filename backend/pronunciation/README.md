# Backend nhận dạng và so sánh âm vị

Kế thừa hợp đồng API của module Đăng, thay bộ chấm heuristic cũ bằng Python/FastAPI và hai mô hình CPU. Không cần API key hay dịch vụ trả phí.

## Cài và chạy Windows

Từ thư mục gốc dự án, Python 3.11+ 64-bit:

```powershell
powershell -ExecutionPolicy Bypass -File backend/pronunciation/setup_backend.ps1
.\run_backend.bat
```

Script tạo `.venv`, cài PyTorch CPU cùng dependencies đã khóa, tải và thử nạp cả hai model. Mạng/tài nguyên thiếu sẽ báo lỗi; không trả điểm thay thế. Đã kiểm tra trên Windows CPU/RAM 16 GB; đây là cấu hình thử, không phải cam kết tối thiểu.

Dữ liệu model nằm ở `backend/pronunciation/.models/`, được Git bỏ qua. Giữ cache để chạy lại khi không có mạng. Không cần cài espeak/phonemizer: backend giải mã nhãn âm vị trực tiếp bằng vocab đã tải.

```powershell
Invoke-RestMethod http://127.0.0.1:8080/health
```

Chỉ phân tích khi `assessmentReady` là `true`. Lần nạp đầu mất lâu hơn các yêu cầu sau. Mỗi tiến trình chỉ nhận một yêu cầu phân tích; yêu cầu đồng thời nhận 429 để tránh hết RAM. Không tăng số worker tùy tiện vì mỗi worker tải riêng model.

Lệnh tương đương:

```powershell
.venv/Scripts/python.exe -m uvicorn server:app --app-dir backend/pronunciation --host 127.0.0.1 --port 8080
```

Lệnh Dart cũ `dart run backend/pronunciation/bin/server.dart` được giữ làm launcher Python; cần cài backend trước. `.env.example` là mẫu cấu hình, không tự động được nạp; dùng biến môi trường PowerShell. `HOST`/`PORT` được launcher đọc; khi gọi uvicorn trực tiếp dùng `--host`/`--port`.

## Model đã khóa

| Vai trò | Model | Revision |
|---|---|---|
| Âm vị từ audio | facebook/wav2vec2-lv-60-espeak-cv-ft | ae45363bf3413b374fecd9dc8bc1df0e24c3b7f4 |
| Văn bản từ audio | facebook/wav2vec2-base-960h | 22aad52d435eb6dbaf354bdad9b0da84ce7d6156 |

Model card: [âm vị](https://huggingface.co/facebook/wav2vec2-lv-60-espeak-cv-ft), [ASR](https://huggingface.co/facebook/wav2vec2-base-960h); [tài liệu Transformers](https://huggingface.co/docs/transformers/model_doc/wav2vec2_phoneme). Dùng checkpoint công bố sẵn, không tuyên bố nhóm đã huấn luyện/hiệu chuẩn bằng giọng sinh viên Việt Nam.

Manifest nằm trong `models.json`; dependencies chính ở `requirements.txt`, bản môi trường đã chạy ở `requirements.lock.txt`. Setup cài torch từ kho CPU chính thức trước khi cài lock.

## API

`POST /api/pronounce/analyze`, `Content-Type: application/json`:

```json
{
  "sessionId": "sess-example-01",
  "exerciseId": "ex-01-dental-fricative-unvoiced",
  "audioBase64": "<base64 của file audio>",
  "mimeType": "audio/wav"
}
```

Câu/IPA lấy từ catalog server, không tin tham chiếu hoặc transcript phía client. Audio gửi trong bộ nhớ, không lưu trên backend. Giới hạn audio 8 MB, request 12 MB, thời lượng 0,4–60 giây. FFmpeg đóng gói chuyển WAV/WebM/Opus và các định dạng được hỗ trợ sang PCM mono 16 kHz; kiểm tra im lặng sau giải mã.

Kết quả giữ các trường `PronunciationResult` của Flutter, thêm `comparison`, `recognizedPhonemes`, `processingSeconds`, `modelRevisions`, `limitations`. Điểm là edit similarity chuỗi âm vị, không phải GOP. Xem [đặc tả](../../docs/pronunciation/api-and-scoring.md).

Lỗi 400/413 cho request/audio không hợp lệ; 422 cho audio không đủ bằng chứng; 429 khi bận; 503 khi chưa sẵn sàng; 500 khi lỗi nội bộ. Body có `code` và `message`, không kèm điểm giả.

## Kết nối và kiểm thử

Mặc định chỉ cho origin localhost/127.0.0.1. Có thể đặt `CORS_ORIGINS` là danh sách origin HTTPS phân cách bằng dấu phẩy. Backend demo chưa có xác thực/quota cho Internet; triển khai mạng cần reverse proxy HTTPS và kiểm soát truy cập.

```powershell
.venv/Scripts/python.exe -m unittest discover -s backend/pronunciation/tests -v
```

Test tự động kiểm tra giải mã, im lặng, thay/thừa/thiếu âm, thiếu bằng chứng và API. [Đánh giá hiện tại](../../docs/pronunciation/evaluation.md) có cả ví dụ mô hình bỏ lọt lỗi; còn chờ thử người thật.
