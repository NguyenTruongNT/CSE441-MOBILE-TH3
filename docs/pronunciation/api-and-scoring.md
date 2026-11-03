# API và thuật toán chấm điểm hiện tại

Bản Python/model thực thay backend heuristic trước đây; giữ hợp đồng Flutter của module Đăng. Thuật toán ở `backend/pronunciation/phoneme_comparison.py`, nhận dạng ở `engine.py`, API ở `server.py`.

## Luồng xử lý

1. Nhận sessionId, exerciseId, audioBase64, mimeType; lấy câu/IPA từ catalog server.
2. Giải mã bằng FFmpeg thành mono float32, 16 kHz; kiểm tra dung lượng, 0,4–60 giây, tín hiệu hữu hạn và RMS tối thiểu 0,003.
3. Wav2Vec2Phoneme nhận nhãn âm vị trực tiếp từ audio; CTC collapse loại nhãn trống và gộp nhãn lặp.
4. ASR Wav2Vec2 nhận văn bản độc lập từ cùng audio. Transcript client không được dùng làm bằng chứng âm vị hoặc điểm.
5. Tách IPA chuẩn thành đơn vị, bỏ dấu trọng âm để so sánh segmental; căn chỉnh chuỗi chuẩn/nhận dạng bằng edit distance.
6. Trả điểm, phản hồi từng âm và metadata model; Flutter lưu phiên/kết quả bằng giao dịch SQLite.

Audio chia khối tối đa 15 giây để hạn chế RAM CPU; ranh giới khối có thể làm mất/nhận nhầm âm khi nói liên tục. Hai checkpoint và revision nằm ở [models.json](../../backend/pronunciation/models.json).

## Điểm có ý nghĩa gì?

Với N âm chuẩn, M âm nhận dạng và D là số thay/thêm/thiếu tối thiểu (mỗi thao tác chi phí 1):

`overallScore = round(100 × max(0, 1 − D / max(N, M)), 1)`

Ví dụ mẫu /θ ɪ ŋ k/, nhận /s ɪ ŋ k/: D=1, N=M=4, điểm 75. Nhận thêm /ə/ ở cuối: D=1, M=5, điểm 80. Không đủ bằng chứng thì trả lỗi, không trả 0 thay thế.

Chuẩn hóa khác biệt ký hiệu thông dụng như r/ɹ, e/ɛ, əʊ/oʊ, g/ɡ; nhận flap /ɾ/ như biến thể /t,d/. Không chấm trọng âm, ngữ điệu hoặc độ tự nhiên. Điểm là độ giống chuỗi nhãn do model nhận, không phải xác suất phát âm đúng hoặc điểm chuyên gia/GOP.

Phản hồi từng âm:

| Điều kiện | Trạng thái | Điểm chi tiết |
|---|---|---|
| Nhãn khớp sau chuẩn hóa | correct — Khớp mẫu | 100 |
| Thay/thêm/thiếu | needsPractice — Cần luyện | 0 |
| Nhãn quan sát có confidence <0,35 | notAssessed — Chưa đánh giá | null |

Confidence chỉ dùng báo thiếu bằng chứng, không đổi thành điểm phát âm. Điểm tổng vẫn mô tả độ khớp toàn chuỗi nhận dạng, gồm cả nhãn không chắc chắn; không nên kết luận chỉ từ điểm tổng. Trung bình confidence toàn bản ghi <0,25 hoặc không có đủ âm/văn bản thì trả `insufficientEvidence`.

Mốc thời gian là khoảng khung CTC quan sát, không phải forced alignment được chuyên gia gán. Âm thiếu không có mốc; nhãn composite khi tách giữ cùng khoảng đã quan sát, không chia thời gian giả. Âm thừa dùng expectedIpa `∅`; vị trí từ là vị trí gần nhất theo căn chỉnh, có thể lệch khi đọc sai nhiều.

## Hợp đồng API

`POST /api/pronounce/analyze` — JSON chứa `sessionId`, `exerciseId`, `audioBase64`, `mimeType`. Body tối đa 12 MB, audio giải mã base64 tối đa 8 MB. Audio không lưu ở server. Dùng HTTPS khi truy cập qua mạng.

Thành công gồm `id, sessionId, referenceText, recognizedText, overallScore, phonemes, provider, modelVersion, analyzedAt`; thêm `comparison, recognizedPhonemes, processingSeconds, modelRevisions, limitations`. Provider là `wav2vec2-phoneme-edit-similarity`.

Lỗi có `code, message`, không có điểm. 400/413 request/audio sai, 422 thiếu bằng chứng, 429 đang bận, 503 model chưa sẵn sàng, 500 lỗi nội bộ. Client chờ tối đa 120 giây, báo lỗi nếu mất kết nối và không gọi engine mô phỏng thay thế.

## Giới hạn đã biết

Model có thể biến âm sai thành âm chuẩn và bỏ lọt lỗi. Đã gặp ca TTS đọc “sink” nhưng model trả /θ/ và điểm 100; phải giữ ca này trong báo cáo. Hai model chưa fine-tune/hiệu chuẩn cho nhóm người thử Việt Nam. Không thể suy ra độ chính xác từ một câu đúng hoặc từ test thuật toán.

Kế hoạch người nghe đối chiếu: [bộ nghiệm thu](../kiem-thu-nghien-thu.md). Kết quả kỹ thuật hiện có: [báo cáo](evaluation.md).
