# Dictation Plugin — Development Guide (v0.2.0)

## Architecture

```
BarWidget / TranscriptOverlay / Panel
        ↕ Main.qml (IPC)
        ↕ dictation_backend.py
        ├─ asr_sherpa.py   ← default: two-pass (Zipformer + Whisper/SenseVoice)
        ├─ asr_whisper.py  ← fallback: faster-whisper LocalAgreement
        └─ asr_common.py   ← wtype injection, clipboard, IPC
```

## STT engines

### Primary: sherpa-onnx two-pass

Based on [sherpa-onnx two-pass microphone example](https://github.com/k2-fsa/sherpa-onnx/blob/master/python-api-examples/two-pass-speech-recognition-from-microphone.py):

1. **Streaming Zipformer** — partial results every ~100ms → `partialTranscript` in UI
2. **Endpoint detection** — phrase boundary (not session stop) triggers second pass
3. **Offline Whisper/SenseVoice** — refined segment → `wtype` + `liveTranscript`

Models in `<pluginDir>/models/`, downloaded via `download_models.sh`.

| Profile | 1st pass | 2nd pass |
|---------|----------|----------|
| english | streaming-zipformer-en-20M | whisper-tiny.en |
| multilingual | streaming-zipformer-bilingual-zh-en | sense-voice int8 |

### Fallback: faster-whisper

Used when `engine=faster_whisper`, sherpa-onnx missing, or models not downloaded. LocalAgreement commit policy (~1s chunks).

## IPC

- Signal file: `$XDG_RUNTIME_DIR/noctalia-dictation-signal`
- Status: `qs ipc -c noctalia-shell call plugin:dictation setStatus '<json>'`
- JSON fields: `state`, `message`, `liveTranscript`, `partialTranscript`, `text`, `engine`

## Deploy paths

- Live: `~/.config/noctalia/plugins/dictation/`
- Chezmoi: `~/.local/share/chezmoi/private_dot_config/noctalia/plugins/dictation/`
