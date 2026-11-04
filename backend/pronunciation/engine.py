"""CPU inference for open-source ASR and audio-to-phoneme models."""
from datetime import datetime, timezone
from pathlib import Path
import base64
import json
import math
import os
import subprocess
import time

ROOT = Path(__file__).resolve().parent
os.environ.setdefault("HF_HOME", str(ROOT / ".models"))
os.environ.setdefault("HF_HUB_DISABLE_TELEMETRY", "1")
os.environ.setdefault("HF_HUB_DISABLE_XET", "1")
os.environ.setdefault("HF_HUB_DOWNLOAD_TIMEOUT", "120")

from phoneme_comparison import ObservedPhone, expand_observed, reference_phones, compare_phones


class AssessmentError(Exception):
    def __init__(self, code: str, message: str, status: int = 400):
        self.code, self.message, self.status = code, message, status
        super().__init__(message)


class ModelEngine:
    def __init__(self):
        self.manifest = json.loads((ROOT / "models.json").read_text(encoding="utf-8-sig"))
        self.ready = False

    @staticmethod
    def model_directory(model):
        from huggingface_hub import hf_hub_download
        from huggingface_hub.errors import LocalEntryNotFoundError
        # Use pinned, complete local files without network metadata probes.
        # Only missing files require a download during first-time setup.
        directory = None
        for filename in ("config.json", "preprocessor_config.json", "vocab.json"):
            try:
                path = hf_hub_download(model["id"], filename, revision=model["revision"], local_files_only=True)
            except LocalEntryNotFoundError:
                path = hf_hub_download(model["id"], filename, revision=model["revision"])
            directory = Path(path).parent
        if not any((directory / filename).is_file() for filename in ("model.safetensors", "pytorch_model.bin")):
            hf_hub_download(model["id"], "pytorch_model.bin", revision=model["revision"])
        return directory

    def load(self):
        import torch
        from transformers import AutoModelForCTC, AutoProcessor, Wav2Vec2FeatureExtractor
        torch.set_num_threads(min(4, os.cpu_count() or 1))
        self.torch = torch
        phoneme, asr = self.manifest["phoneme"], self.manifest["asr"]
        print("Loading phoneme model (CPU, pinned revision)...", flush=True)
        phoneme_directory = self.model_directory(phoneme)
        self.phoneme_features = Wav2Vec2FeatureExtractor.from_pretrained(phoneme_directory, local_files_only=True)
        self.phoneme_model = AutoModelForCTC.from_pretrained(phoneme_directory, local_files_only=True, trust_remote_code=False).eval()
        self.phone_labels = {value: key for key, value in json.loads((phoneme_directory / "vocab.json").read_text(encoding="utf-8")).items()}
        print("Loading English ASR model (CPU, pinned revision)...", flush=True)
        asr_directory = self.model_directory(asr)
        self.asr_processor = AutoProcessor.from_pretrained(asr_directory, local_files_only=True)
        self.asr_model = AutoModelForCTC.from_pretrained(asr_directory, local_files_only=True, trust_remote_code=False).eval()
        self.ready = True
        print("Both assessment models ready.", flush=True)

    @staticmethod
    def decode_audio(encoded: str):
        import numpy as np
        import imageio_ffmpeg
        try:
            data = base64.b64decode(encoded, validate=True)
        except (ValueError, TypeError):
            raise AssessmentError("invalidAudio", "Audio base64 không hợp lệ.")
        if not 128 <= len(data) <= 8 * 1024 * 1024:
            raise AssessmentError("invalidAudio", "Audio phải có dữ liệu và không vượt quá 8 MB.")
        try:
            decoded = subprocess.run([
                imageio_ffmpeg.get_ffmpeg_exe(), "-v", "error", "-i", "pipe:0",
                "-t", "61", "-f", "f32le", "-ac", "1", "-ar", "16000", "pipe:1",
            ], input=data, capture_output=True, timeout=20, check=True)
            samples = np.frombuffer(decoded.stdout, dtype="<f4").copy()
        except (subprocess.SubprocessError, OSError, ValueError):
            raise AssessmentError("invalidAudio", "Không giải mã được audio. Hãy ghi âm lại.")
        duration = len(samples) / 16000
        if not 0.4 <= duration <= 60:
            raise AssessmentError("insufficientEvidence", "Bản ghi cần dài từ 0,4 đến 60 giây.", 422)
        if not np.isfinite(samples).all():
            raise AssessmentError("invalidAudio", "Tín hiệu audio không hợp lệ.")
        energy = float(np.sqrt(np.mean(samples * samples)))
        if energy < 0.003:
            raise AssessmentError("insufficientEvidence", "Bản ghi im lặng hoặc quá nhỏ. Hãy nói gần micro hơn.", 422)
        return samples

    def analyze(self, payload: dict, exercise: dict):
        if not self.ready:
            raise AssessmentError("insufficientEvidence", "Mô hình chưa sẵn sàng.", 503)
        samples = self.decode_audio(payload["audioBase64"])
        expected = reference_phones(exercise["referenceText"], exercise["referenceIpa"])
        phones, texts = [], []
        started = time.monotonic()
        with self.torch.inference_mode():
            for offset in range(0, len(samples), 15 * 16000):
                chunk = samples[offset:offset + 15 * 16000]
                if len(chunk) < 400:
                    continue
                inputs = self.phoneme_features(chunk, sampling_rate=16000, return_tensors="pt")
                logits = self.phoneme_model(**inputs).logits[0]
                probabilities, ids = logits.softmax(-1).max(-1)
                ids, probabilities = ids.tolist(), probabilities.tolist()
                hop = math.prod(self.phoneme_model.config.conv_stride) / 16
                index = 0
                while index < len(ids):
                    end = index + 1
                    while end < len(ids) and ids[end] == ids[index]: end += 1
                    label = self.phone_labels[ids[index]]
                    if not label.startswith("<"):
                        phones.append(ObservedPhone(label, sum(probabilities[index:end]) / (end-index),
                            round(offset / 16 + index * hop),
                            round(min(len(samples) / 16, offset / 16 + end * hop))))
                    index = end
                asr_inputs = self.asr_processor(chunk, sampling_rate=16000, return_tensors="pt")
                predicted_ids = self.asr_model(**asr_inputs).logits.argmax(-1)
                texts.append(self.asr_processor.batch_decode(predicted_ids)[0].strip())
        transcript = " ".join(text for text in texts if text).strip()
        observed = expand_observed(phones)
        if not transcript or len(observed) < 2 or not phones:
            raise AssessmentError("insufficientEvidence", "Chưa nhận được đủ giọng nói để đánh giá. Hãy đọc rõ cả câu.", 422)
        mean_confidence = sum(phone.confidence for phone in phones) / len(phones)
        if mean_confidence < 0.25:
            raise AssessmentError("insufficientEvidence", "Mô hình chưa nhận dạng âm vị đủ rõ. Hãy ghi âm lại ở nơi yên tĩnh.", 422)
        result = compare_phones(expected, observed)
        return {
            **result, "id": f"res-{payload['sessionId']}", "sessionId": payload["sessionId"],
            "referenceText": exercise["referenceText"], "recognizedText": transcript,
            "provider": "wav2vec2-phoneme-edit-similarity",
            "modelVersion": f"phoneme:{self.manifest['phoneme']['revision'][:12]};asr:{self.manifest['asr']['revision'][:12]};comparison:v1",
            "analyzedAt": datetime.now(timezone.utc).isoformat(),
            "processingSeconds": round(time.monotonic() - started, 3),
            "recognizedPhonemes": " ".join(phone.symbol for phone in observed),
            "modelRevisions": self.manifest,
            "limitations": ["Chỉ số so sánh âm vị, chưa hiệu chuẩn với chuyên gia.",
                            "Model có thể nhận nhầm giọng, tiếng ồn và biến thể phát âm.",
                            "Mốc thời gian là khung CTC quan sát, không phải ranh giới âm vị được chuyên gia gán."],
        }


if __name__ == "__main__":
    engine = ModelEngine()
    engine.load()
    print(json.dumps({"ready": engine.ready, "models": engine.manifest}))
