"""HTTP smoke check using local synthetic WAVs. Does not assert human accuracy."""
import base64
import hashlib
import json
import os
from pathlib import Path
import urllib.request

root = Path(__file__).resolve().parents[1]
runtime = root / 'backend/pronunciation/.runtime'
endpoint = os.environ.get('PRONUNCIATION_API_URL', 'http://127.0.0.1:8080/api/pronounce/analyze')
cases = [
    ('reference', 'I think this method is great'),
    ('substitution', 'I sink this method is great'),
    ('different', 'We go home slowly in the cold snow'),
]
report = {'syntheticAudioOnly': True, 'realHumanEvaluation': False, 'cases': []}
for name, spoken in cases:
    audio = (runtime / (name + '-tts.wav')).read_bytes()
    payload = {'sessionId': 'verify-' + name, 'exerciseId': 'ex-01-dental-fricative-unvoiced',
        'audioBase64': base64.b64encode(audio).decode(), 'mimeType': 'audio/wav',
        'clientTranscript': 'I think this method is great'}
    request = urllib.request.Request(endpoint, data=json.dumps(payload).encode(), headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(request, timeout=120) as response:
        result = json.load(response)
    assert result['provider'] == 'wav2vec2-phoneme-edit-similarity'
    assert result['phonemes'] and result['recognizedText']
    report['cases'].append({'case': name, 'syntheticText': spoken, 'audioSha256': hashlib.sha256(audio).hexdigest(),
        **{key: result[key] for key in ['referenceText', 'recognizedText', 'overallScore', 'recognizedPhonemes',
            'comparison', 'modelVersion', 'modelRevisions', 'processingSeconds', 'analyzedAt']}})
    print(name, result['overallScore'], result['recognizedText'], flush=True)
(runtime / 'latest-model-check.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
print('Results saved in ignored .runtime/latest-model-check.json; review all cases, including model errors.')
