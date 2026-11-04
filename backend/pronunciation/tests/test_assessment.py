import base64
import io
import json
from pathlib import Path
import sys
import unittest
import wave

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from phoneme_comparison import ObservedPhone, ReferencePhone, split_ipa, reference_phones, expand_observed, compare_phones
from engine import AssessmentError, ModelEngine
from server import create_app
from fastapi.testclient import TestClient


def observed(symbols):
    return [ObservedPhone(p, 0.95, i * 100, (i + 1) * 100) for i, p in enumerate(symbols)]


class ComparisonTests(unittest.TestCase):
    def test_target_ipa_is_segmented_without_stress_or_text_guessing(self):
        self.assertEqual(split_ipa('/ˈθɪŋk/'), ['θ', 'ɪ', 'ŋ', 'k'])
        self.assertEqual([p.word for p in reference_phones('thirty-three', '/ˈθɜːti θriː/')],
                         ['thirty'] * 4 + ['three'] * 3)

    def test_correct_phones_score_one_hundred(self):
        result = compare_phones(reference_phones('think', '/θɪŋk/'), observed(['θ', 'ɪ', 'ŋ', 'k']))
        self.assertEqual(result['overallScore'], 100)
        self.assertTrue(all(p['status'] == 'correct' for p in result['phonemes']))

    def test_audio_decoded_substitution_is_flagged(self):
        result = compare_phones(reference_phones('think', '/θɪŋk/'), observed(['s', 'ɪ', 'ŋ', 'k']))
        self.assertEqual(result['overallScore'], 75)
        self.assertEqual(result['phonemes'][0]['recognizedIpa'], 's')
        self.assertEqual(result['phonemes'][0]['status'], 'needsPractice')

    def test_missing_phone_has_no_invented_time_or_recognized_ipa(self):
        result = compare_phones(reference_phones('think', '/θɪŋk/'), observed(['θ', 'ɪ', 'ŋ']))
        last = result['phonemes'][-1]
        self.assertIsNone(last['startMilliseconds'])
        self.assertIsNone(last['endMilliseconds'])
        self.assertIsNone(last['recognizedIpa'])
        self.assertEqual(last['status'], 'needsPractice')

    def test_inserted_phone_reduces_score(self):
        result = compare_phones(reference_phones('think', '/θɪŋk/'), observed(['θ', 'ɪ', 'ŋ', 'k', 'ə']))
        self.assertEqual(result['overallScore'], 80)
        self.assertIn('∅', [p['expectedIpa'] for p in result['phonemes']])

    def test_notation_variants_are_normalized(self):
        result = compare_phones(reference_phones('red', '/red/'), observed(['ɹ', 'ɛ', 'd']))
        self.assertEqual(result['overallScore'], 100)

    def test_composite_model_labels_keep_the_observed_span(self):
        phones = expand_observed([ObservedPhone('ɑːɹ', 0.9, 120, 240)])
        self.assertEqual([p.symbol for p in phones], ['ɑː', 'ɹ'])
        self.assertTrue(all(p.start_ms == 120 and p.end_ms == 240 for p in phones))

    def test_uncertain_phone_is_not_claimed_as_an_error(self):
        result = compare_phones([ReferencePhone('θ', 'think')], [ObservedPhone('s', 0.1, 0, 100)])
        self.assertEqual(result['phonemes'][0]['status'], 'notAssessed')
        self.assertIsNone(result['phonemes'][0]['score'])

    def test_empty_evidence_is_rejected(self):
        with self.assertRaises(ValueError): compare_phones([ReferencePhone('s', 'sea')], [])


class AudioTests(unittest.TestCase):
    def test_silence_rejected_after_real_decoding(self):
        stream = io.BytesIO()
        with wave.open(stream, 'wb') as wav:
            wav.setparams((1, 2, 16000, 0, 'NONE', 'not compressed'))
            wav.writeframes(b'\x00\x00' * 16000)
        with self.assertRaises(AssessmentError) as error:
            ModelEngine.decode_audio(base64.b64encode(stream.getvalue()).decode())
        self.assertEqual(error.exception.code, 'insufficientEvidence')

    def test_corrupted_audio_rejected(self):
        with self.assertRaises(AssessmentError) as error:
            ModelEngine.decode_audio(base64.b64encode(b'garbage' * 100).decode())
        self.assertEqual(error.exception.code, 'invalidAudio')


class StubEngine:
    ready = True
    manifest = {'test': 'fixture-only'}
    def analyze(self, payload, exercise):
        return {'referenceText': exercise['referenceText'], 'ignoredTranscript': 'clientTranscript' not in payload}


class ApiTests(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(create_app(StubEngine(), load_models=False))
        self.payload = dict(sessionId='test-session', exerciseId='ex-01-dental-fricative-unvoiced',
                            audioBase64='A' * 256, mimeType='audio/wav')

    def test_client_text_cannot_replace_reference_or_create_phone_evidence(self):
        response = self.client.post('/api/pronounce/analyze', json={**self.payload,
            'referenceText': 'tampered', 'clientTranscript': 'perfect speech'})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()['referenceText'], 'I think this method is great')
        self.assertTrue(response.json()['ignoredTranscript'])

    def test_missing_request_fields(self):
        self.assertEqual(self.client.post('/api/pronounce/analyze', json={}).status_code, 400)

    def test_unknown_exercise(self):
        self.assertEqual(self.client.post('/api/pronounce/analyze', json={**self.payload, 'exerciseId': 'missing'}).status_code, 400)

    def test_unready_model_does_not_return_a_score(self):
        stub = StubEngine(); stub.ready = False
        client = TestClient(create_app(stub, load_models=False))
        response = client.post('/api/pronounce/analyze', json=self.payload)
        self.assertEqual(response.status_code, 503)
        self.assertNotIn('overallScore', response.json())


if __name__ == '__main__': unittest.main()
