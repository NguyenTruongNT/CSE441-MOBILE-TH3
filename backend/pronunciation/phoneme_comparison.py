"""Compare audio-decoded IPA labels with the lesson's reference IPA.

This module never consumes ASR text. Scores are normalized phoneme edit
similarity, not GOP, accent ratings or calibrated expert scores.
"""
from dataclasses import dataclass
import re
import unicodedata


@dataclass(frozen=True)
class ObservedPhone:
    symbol: str
    confidence: float
    start_ms: int
    end_ms: int


@dataclass(frozen=True)
class ReferencePhone:
    symbol: str
    word: str


# Resolve notation/allophonic conventions before token comparison, not from text.
ALIASES = {"ɹ": "r", "ɫ": "l", "g": "ɡ", "e": "ɛ", "əʊ": "oʊ",
           "ɚ": "ər", "ɝ": "ɜːr", "ᵻ": "ɪ"}
MULTI = sorted({"tʃ", "dʒ", "iː", "ɑː", "ɔː", "uː", "ɜː", "eɪ", "aɪ",
               "aʊ", "oʊ", "əʊ", "ɔɪ", "ɪə", "eə", "ʊə"}, key=lambda s: (-len(s), s))


def split_ipa(ipa: str) -> list[str]:
    value = unicodedata.normalize("NFC", ipa).replace(":", "ː")
    value = re.sub(r"[ˈˌ/\[\].\sˑ͡]", "", value)
    result = []
    while value:
        token = next((p for p in MULTI if value.startswith(p)), value[0])
        result.append(token)
        value = value[len(token):]
    return result


def canonical(symbol: str) -> str:
    return ALIASES.get(symbol, symbol)


def equivalent(expected: str, actual: str) -> bool:
    first, second = canonical(expected), canonical(actual)
    return first == second or (second == "ɾ" and first in {"t", "d"})


def reference_phones(text: str, ipa: str) -> list[ReferencePhone]:
    words = re.findall(r"[A-Za-z]+(?:'[A-Za-z]+)?", text)
    groups = ipa.strip(" /[]").split()
    if len(groups) != len(words):
        raise ValueError("Reference text and word-level IPA do not align.")
    return [ReferencePhone(symbol, word) for word, group in zip(words, groups)
            for symbol in split_ipa(group)]


def expand_observed(phones: list[ObservedPhone]) -> list[ObservedPhone]:
    result = []
    for phone in phones:
        # A model label can contain several phones (e.g. əl or ɑːɹ).
        # All retain the observed CTC span; no artificial sub-phone times.
        raw = ALIASES.get(phone.symbol, phone.symbol)
        for symbol in split_ipa(raw):
            result.append(ObservedPhone(symbol, phone.confidence, phone.start_ms, phone.end_ms))
    return result


GUIDANCE = {
    "θ": "Đặt đầu lưỡi nhẹ giữa hai hàm răng, thổi hơi, không rung thanh quản.",
    "ð": "Đặt đầu lưỡi ở mép răng cửa trên và rung thanh quản.",
    "ʃ": "Chu môi nhẹ, nâng thân lưỡi gần vòm miệng và đẩy hơi đều.",
    "s": "Giữ đầu lưỡi gần nướu, để hơi đi qua khe hẹp, tránh chu môi.",
    "tʃ": "Chặn hơi rồi bật ra thành âm xát, chu môi nhẹ.",
    "dʒ": "Chặn rồi nhả hơi như /tʃ/, đồng thời rung thanh quản.",
    "iː": "Căng nhẹ khóe miệng và giữ nguyên âm dài, ổn định.",
    "ɪ": "Thả lỏng hàm, phát âm ngắn; tránh kéo dài thành /iː/.",
    "r": "Lùi đầu lưỡi, không chạm vòm miệng; nghe mẫu rồi luyện chậm.",
    "l": "Đặt đầu lưỡi vào nướu răng trên và cho hơi thoát hai bên.",
    "ŋ": "Nâng cuống lưỡi lên ngạc mềm, cho âm ngân qua mũi.",
    "v": "Răng cửa trên chạm nhẹ môi dưới; rung thanh quản.",
    "w": "Chu tròn môi rồi mở nhanh; không chạm răng vào môi dưới.",
    "æ": "Hạ hàm và mở miệng rộng hơn /e/, giữ lưỡi ở phía trước.",
}


def compare_phones(reference: list[ReferencePhone], observed: list[ObservedPhone]) -> dict:
    if not reference or not observed:
        raise ValueError("No phoneme evidence to compare.")
    n, m = len(reference), len(observed)
    costs = [[0] * (m + 1) for _ in range(n + 1)]
    for i in range(n + 1): costs[i][0] = i
    for j in range(m + 1): costs[0][j] = j
    for i in range(1, n + 1):
        for j in range(1, m + 1):
            mismatch = not equivalent(reference[i - 1].symbol, observed[j - 1].symbol)
            costs[i][j] = min(costs[i-1][j-1] + mismatch, costs[i-1][j] + 1, costs[i][j-1] + 1)
    operations = []
    i, j = n, m
    while i or j:
        if i and j:
            mismatch = not equivalent(reference[i-1].symbol, observed[j-1].symbol)
            if costs[i][j] == costs[i-1][j-1] + mismatch:
                operations.append((reference[i-1], observed[j-1], "substitute" if mismatch else "match"))
                i -= 1; j -= 1
                continue
        if i and costs[i][j] == costs[i-1][j] + 1:
            operations.append((reference[i-1], None, "delete")); i -= 1
        else:
            neighbor = reference[min(i, n - 1)]
            operations.append((ReferencePhone("∅", neighbor.word), observed[j-1], "insert")); j -= 1
    operations.reverse()
    feedback = []
    for expected, actual, operation in operations:
        uncertain = actual is not None and actual.confidence < 0.35
        status = "notAssessed" if uncertain else ("correct" if operation == "match" else "needsPractice")
        if uncertain:
            suggestion = "Mô hình chưa chắc chắn âm này. Ghi âm lại ở nơi yên tĩnh; chưa kết luận âm sai."
        elif operation == "match":
            suggestion = f"Âm nhận dạng khớp /{expected.symbol}/ trong mẫu. Tiếp tục luyện cùng cả câu."
        elif operation == "delete":
            suggestion = f"Chưa tìm được /{expected.symbol}/ gần từ “{expected.word}”. Nghe mẫu và luyện lại; mô hình có thể bỏ sót."
        elif operation == "insert":
            suggestion = f"Mô hình nhận thêm /{actual.symbol}/ gần từ “{expected.word}”. Nghe lại để kiểm tra có thêm âm không."
        else:
            tip = GUIDANCE.get(canonical(expected.symbol), "Nghe mẫu và luyện chậm từng âm trong từ.")
            suggestion = f"Mô hình nhận /{actual.symbol}/ thay cho /{expected.symbol}/. {tip}"
        feedback.append({
            "word": expected.word, "expectedIpa": expected.symbol,
            "recognizedIpa": actual.symbol if actual else None,
            "score": None if uncertain else (100.0 if operation == "match" else 0.0),
            "status": status,
            "startMilliseconds": actual.start_ms if actual else None,
            "endMilliseconds": actual.end_ms if actual else None,
            "suggestion": suggestion,
        })
    distance = costs[n][m]
    return {
        "overallScore": round(max(0.0, 100 * (1 - distance / max(n, m))), 1),
        "phonemes": feedback,
        "comparison": {"distance": distance, "referenceCount": n, "observedCount": m,
                       "method": "normalized-phoneme-edit-similarity-v1"},
    }
