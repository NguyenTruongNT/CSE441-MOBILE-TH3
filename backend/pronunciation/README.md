# Pronunciation AI Backend Proxy Server

> Phụ trách: **Vũ Hải Đăng** (`dang-feature/pronunciation-ai`)

Máy chủ Proxy phục vụ module Phân tích phát âm AI. Máy chủ này đóng vai trò:
1. Che giấu khóa bí mật (API Key) của dịch vụ nhận dạng và chấm điểm phát âm từ phía client Flutter/Web.
2. Kiểm tra tính hợp lệ của tín hiệu âm thanh (kích thước, định dạng MIME, phát hiện im lặng RMS).
3. Cung cấp API chuẩn hóa `PronunciationResult` với tính toán âm vị GOP (Goodness of Pronunciation).

## Cách khởi động máy chủ

Chạy trực tiếp bằng Dart SDK (không cần cài đặt Node.js hay Python):

```bash
# Khởi động ở chế độ mặc định (Port 8080)
dart run backend/pronunciation/bin/server.dart

# Hoặc thiết lập cổng tùy chỉnh:
PORT=8080 dart run backend/pronunciation/bin/server.dart
```

## Kiểm tra sức khỏe máy chủ (Health check)

```bash
curl http://localhost:8080/health
```

Phản hồi:
```json
{
  "status": "ok",
  "service": "pronunciation-ai-proxy",
  "version": "1.0.0",
  "provider": "local-acoustic-gop",
  "timestamp": "2026-11-02T08:30:00.000Z"
}
```

## Gọi API chấm điểm phát âm

- **Endpoint**: `POST /api/pronounce/analyze`
- **Headers**: `Content-Type: application/json`
- **Body**:
```json
{
  "sessionId": "sess-test-01",
  "exerciseId": "ex-01-dental-fricative-unvoiced",
  "referenceText": "I think this method is great",
  "referenceIpa": "/aɪ θɪŋk ðɪs ˈmeθəd ɪz ɡreɪt/",
  "targetPhonemes": ["θ", "ð", "ŋk"],
  "audioBase64": "UklGRi...",
  "mimeType": "audio/wav"
}
```
