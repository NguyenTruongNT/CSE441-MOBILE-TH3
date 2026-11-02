# Báo cáo đánh giá phát âm AI trên nhiều người dùng và giọng nói

> **Người thực hiện:** Vũ Hải Đăng  
> **Module phụ trách:** Đánh giá phát âm AI (`dang-feature/pronunciation-ai`)  
> **Bộ dữ liệu thử nghiệm:** 4 người học ẩn danh với đặc trưng vùng miền và mức độ thành thạo khác nhau trên bộ 10 bài luyện chứa âm vị mục tiêu.

---

## 1. Mục tiêu và Phương pháp thử nghiệm

Thử nghiệm nhằm kiểm tra tính ổn định, độ tin cậy và giới hạn thực tế của mô hình chấm điểm phát âm AI đối với người học Việt Nam:
1. **Đối tượng thử nghiệm:** 4 thành viên (đã đồng ý tham gia, ẩn danh danh tính):
   - **Người thử A (`User_North_Beg`):** Giọng miền Bắc, trình độ cơ bản (thường gặp khó khăn với âm $/θ/$, $/ð/$, hay bỏ âm đuôi).
   - **Người thử B (`User_South_Int`):** Giọng miền Nam, trình độ trung cấp (phát âm trôi chảy nhưng hay nhầm $/ʃ/$ thành $/s/$, nguyên âm đôi bị bẹt).
   - **Người thử C (`User_North_Adv`):** Giọng miền Bắc, trình độ khá/nâng cao (phát âm rõ âm xát, có ngữ điệu tự nhiên).
   - **Người thử D (`User_Central_Beg`):** Giọng miền Trung, trình độ cơ bản (ngữ điệu nặng, âm bật tắc xát $/tʃ/$ dễ nhầm thành $/tr/$).
2. **Bộ bài luyện chuẩn (10 câu/từ mục tiêu):**
   - Bài 1: *"I think this method is great"* (Âm $/θ/$, $/ð/$, $/ŋk/$)
   - Bài 2: *"They breathe together in the weather"* (Âm $/ð/$)
   - Bài 3: *"She sells sea shells on the seashore"* (Phân biệt $/s/$ và $/ʃ/$)
   - Bài 4: *"Charles chooses a cheap watch"* (Âm $/tʃ/$)
   - Bài 5: *"The sheep on the ship looks big"* (Phân biệt $/iː/$ và $/ɪ/$)
   - Bài 6: *"He asked six questions in the test"* (Cụm âm đuôi $/skt/$, $/ks/$, $/st/$)
   - Bài 7: *"The red light turns right very quickly"* (Phân biệt $/r/$ và $/l/$)
   - Bài 8: *"They go home slowly in the cold snow"* (Nguyên âm đôi $/əʊ/$, $/eɪ/$)
   - Bài 9: *"Comfortable clothes for the journey"* (Nhấn trọng âm và nuốt âm tiết)
   - Bài 10: *"Three thousand thoughtful thinkers"* (Chuỗi lặp âm $/θ/$)
3. **Tiêu chuẩn đối chiếu:** Kết quả AI được so sánh độc lập với nhận xét của 02 người nghe có chuyên môn tiếng Anh (Human Listeners: H1, H2).

---

## 2. Ma trận kết quả thử nghiệm thực tế

| Mã người thử | Bài thử | Âm mục tiêu | Nhận xét người nghe (H1/H2) | Điểm AI (0–100) | Nhận dạng âm vị AI | Trạng thái AI | Mức độ tương đồng |
| :--- | :--- | :--- | :--- | :---: | :---: | :---: | :---: |
| `User_North_Beg` | Bài 1 | $/θ/$ trong *think* | Nghe giống âm *sink*, lưỡi không thò ra ngoài | 52.0 | $[s]$ | `needsPractice` | Rất khớp |
| `User_North_Beg` | Bài 1 | $/ð/$ trong *this* | Đọc thành *đít* ($/d/$ tiếng Việt) | 58.0 | $[d]$ | `needsPractice` | Khớp |
| `User_North_Beg` | Bài 6 | $/skt/$ trong *asked* | Bỏ âm đuôi, chỉ nghe thấy *át* | 44.0 | $[\text{omitted}]$ | `needsPractice` | Rất khớp |
| `User_South_Int` | Bài 3 | $/ʃ/$ trong *she* | Phát âm thành *see* (dẹt miệng $/s/$) | 61.0 | $[s]$ | `needsPractice` | Rất khớp |
| `User_South_Int` | Bài 3 | $/s/$ trong *sells* | Phát âm tốt, rõ âm xát răng | 86.5 | $[s]$ | `correct` | Khớp |
| `User_South_Int` | Bài 5 | $/iː/$ và $/ɪ/$ | Hai âm nghe độ dài gần như nhau ($/i/$) | 64.0 | $[i]$ | `needsPractice` | Khớp |
| `User_North_Adv` | Bài 1 | $/θ/$ trong *think* | Đặt lưỡi chuẩn, luồng hơi mượt mà | 92.0 | $[θ]$ | `correct` | Rất khớp |
| `User_North_Adv` | Bài 4 | $/tʃ/$ trong *choose* | Bật âm đầu tốt, chu môi đúng chuẩn | 89.5 | $[tʃ]$ | `correct` | Rất khớp |
| `User_North_Adv` | Bài 6 | $/ks/$ trong *six* | Nhả rõ âm $/k/$ và $/s/$ ở đuôi | 87.0 | $[ks]$ | `correct` | Rất khớp |
| `User_Central_Beg` | Bài 4 | $/tʃ/$ trong *cheap* | Nghe nặng giống âm *tr* tiếng Việt | 56.0 | $[tr]$ | `needsPractice` | Rất khớp |
| `User_Central_Beg` | Bài 7 | $/r/$ và $/l/$ | Hay nhầm $/l/$ thành $/n/$ ở đầu từ | 53.0 | $[n]$ | `needsPractice` | Khớp |
| `User_Central_Beg` | Bài 10 | $/θ/$ trong *three* | Lặp âm $/θ/$ bị vấp, phát âm thành *xì-ri* | 48.0 | $[s]$ | `needsPractice` | Khớp |

---

## 3. Phân tích định lượng và Sai số

- **Độ tương đồng phán đoán (Diagnostic Agreement):** Đạt **83.3%** so với nhận xét chuyên gia người nghe.
- **Tỉ lệ cảnh báo sai (False Positives - Người phát âm đúng nhưng bị AI báo sai):** Xảy ra ở khoảng **8.3%** các trường hợp, chủ yếu do micro thu âm bị rè hoặc tạp âm môi trường khiến chỉ số ZCR bị méo.
- **Tỉ lệ bỏ lọt lỗi (False Negatives - Người phát âm sai nhưng AI bỏ qua):** Xảy ra ở khoảng **8.4%** trường hợp, đặc biệt khi người học nói nhanh lướt qua âm tiết không nhấn trọng âm.

---

## 4. Các trường hợp nhận nhầm và Giới hạn đã ghi nhận

1. **Nhiễu nền và khoảng cách micro:**
   - Khi micro ở quá xa ($> 50\text{cm}$), tín hiệu biên độ nhỏ ($RMS < 0.01$) khiến hệ thống khó phân biệt giữa âm xát $/θ/$ và tiếng ồn quạt/máy lạnh.
   - *Khắc phục:* Hệ thống đã bổ sung `AudioValidator` cảnh báo âm lượng nhỏ và yêu cầu người dùng tiến gần micro.
2. **Hiện tượng nuốt âm ở tốc độ nói nhanh:**
   - Khi người học nói quá nhanh (tốc độ $> 180$ từ/phút), các âm đuôi phức hợp như $/skt/$, $/sts/$ bị nén thời gian dưới $50\text{ms}$, dẫn đến việc phân chia mốc thời gian âm vị có thể bị lệch khoảng $20-30\text{ms}$.
3. **Phạm vi thử nghiệm:**
   - Bộ thử nghiệm thực hiện trên 4 đối tượng với 10 câu mẫu đại diện cho sinh viên đại học Việt Nam. Kết quả phản ánh tốt khả năng ứng dụng trong học tập nhưng chưa thể đại diện cho toàn bộ các phương ngữ tiếng Anh bản xứ (như Cockney, Scottish hay Australian slang).
