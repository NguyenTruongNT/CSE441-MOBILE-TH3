import sys
import json
import os
import subprocess
import speech_recognition as sr

def transcribe_and_evaluate(audio_path, reference_text, target_phonemes_json):
    recognizer = sr.Recognizer()
    
    # Check if file needs ffmpeg conversion (e.g. WebM to WAV)
    wav_path = audio_path
    converted = False
    
    if not audio_path.lower().endswith(".wav"):
        wav_path = audio_path + ".converted.wav"
        try:
            cmd = ["ffmpeg", "-y", "-i", audio_path, "-ar", "16000", "-ac", "1", wav_path]
            subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
            converted = True
        except Exception as e:
            return json.dumps({
                "success": False,
                "error": f"FFmpeg conversion failed: {str(e)}",
                "code": "invalidAudio"
            })

    transcript = ""
    try:
        with sr.AudioFile(wav_path) as source:
            # Adjust for ambient noise slightly
            recognizer.adjust_for_ambient_noise(source, duration=0.2)
            audio_data = recognizer.record(source)
            transcript = recognizer.recognize_google(audio_data, language="en-US")
    except sr.UnknownValueError:
        # Audio was audible but no intelligible English speech could be recognized
        return json.dumps({
            "success": False,
            "error": "Không nhận diện được giọng nói tiếng Anh trong bản ghi âm. Vui lòng nói to, rõ ràng và phát âm theo câu mẫu.",
            "code": "insufficientEvidence",
            "transcript": ""
        })
    except sr.RequestError as e:
        return json.dumps({
            "success": False,
            "error": f"Lỗi kết nối tới dịch vụ nhận dạng giọng nói: {str(e)}",
            "code": "network",
            "transcript": ""
        })
    except Exception as e:
        return json.dumps({
            "success": False,
            "error": f"Lỗi đọc file âm thanh: {str(e)}",
            "code": "invalidAudio",
            "transcript": ""
        })
    finally:
        if converted and os.path.exists(wav_path):
            try:
                os.remove(wav_path)
            except:
                pass

    return json.dumps({
        "success": True,
        "transcript": transcript.strip()
    })

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(json.dumps({"success": False, "error": "Missing arguments"}))
        sys.exit(1)
        
    audio_file = sys.argv[1]
    ref_text = sys.argv[2]
    target_phonemes = sys.argv[3] if len(sys.argv) > 3 else "[]"
    
    print(transcribe_and_evaluate(audio_file, ref_text, target_phonemes))
