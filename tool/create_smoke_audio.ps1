# Synthetic audio for integration checks; never a substitute for human evaluation.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Speech
$fixtureRoot = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'backend/pronunciation/.runtime'
New-Item -ItemType Directory -Path $fixtureRoot -Force | Out-Null
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
try {
    $englishVoice = $synth.GetInstalledVoices() | Where-Object { $_.Enabled -and $_.VoiceInfo.Culture.Name -like 'en-*' } | Select-Object -First 1
    if (-not $englishVoice) { throw 'Install a Windows English TTS voice first.' }
    $synth.SelectVoice($englishVoice.VoiceInfo.Name)
    $format = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(16000, [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen, [System.Speech.AudioFormat.AudioChannel]::Mono)
    $sentences = @{
        'reference-tts' = 'I think this method is great'
        'substitution-tts' = 'I sink this method is great'
        'different-tts' = 'We go home slowly in the cold snow'
    }
    foreach ($name in $sentences.Keys) {
        $synth.SetOutputToWaveFile((Join-Path $fixtureRoot ($name + '.wav')), $format)
        $synth.Speak($sentences[$name])
        $synth.SetOutputToNull()
    }
    Write-Output ('Synthetic fixtures created with voice: ' + $englishVoice.VoiceInfo.Name)
} finally { $synth.Dispose() }
