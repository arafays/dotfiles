# noctalia-dictation

A Noctalia Shell plugin that provides local, offline voice dictation using [faster-whisper](https://github.com/SYSTRAN/faster-whisper).

## Features

- Local, offline speech-to-text — no cloud services
- **Session toggle** — start/stop with the bar mic or hotkey (no silence auto-stop)
- **Live transcript** — bar preview, floating overlay, and panel live session
- **Text injection** — committed words typed into the focused field via `wtype` (clipboard paste fallback)
- **Full-session clipboard** — entire transcript copied when the session ends
- Transcription history panel with copy and re-type actions
- Configurable Whisper model (tiny through large-v3)
- Multi-language support (auto-detect or pick from 20+ languages)

## Installation

### 1. Install the plugin

```bash
git clone https://github.com/arafays/noctalia-dictation.git
cp -r noctalia-dictation ~/.config/noctalia/plugins/dictation
```

### 2. Install Python dependencies (choose one method)

**Option A: System packages (faster startup, recommended)**

If you already have `faster-whisper`, `sounddevice`, and `numpy` installed for your system Python 3, the plugin will detect them and use them directly.

```bash
pip install --user faster-whisper sounddevice numpy
```

**Option B: Automatic (zero setup)**

If the required Python packages are not found on your system, the plugin creates a local virtual environment and installs dependencies on first run.

### 3. Required system tools

- `wtype` — types committed transcript into the focused Wayland window
- `wl-copy` (wl-clipboard) — clipboard integration and paste fallback
- (Optional) `ydotool` — paste fallback if `wtype` is unavailable
- (Optional) NVIDIA GPU + CUDA — faster transcription

### 4. Enable the plugin

Restart Noctalia, then enable the plugin in **Settings > Plugins**.

## Usage

1. Focus any text field (editor, terminal, browser, etc.).
2. Click the microphone icon in the bar, or press your configured hotkey (e.g. `Mod+Shift+D`).
3. Speak — committed text appears in the focused field; live transcript shows in the overlay and bar.
4. Click the mic again or press the hotkey to stop. The full session is copied to the clipboard.

### Hotkey example (Niri)

```kdl
bind=Mod+Shift+D { spawn-sh "qs -c noctalia-shell ipc call plugin:dictation toggle"; }
```

### Reload after updating plugin files

```bash
qs -c noctalia-shell ipc call plugin:dictation status
# Then restart Noctalia, or disable/re-enable the plugin in Settings > Plugins
```

## Settings

| Setting | Default | Description |
|---------|---------|-------------|
| Model | base | Whisper model size (tiny, base, small, medium, large-v3) |
| Language | auto | Auto-detect or specify a language |
| Device | auto | CPU/CUDA compute device |
| Compute type | int8 | Quantization (int8, float16, float32) |

Model, device, and compute type changes require a backend restart (use **Restart** in settings).

## License

MIT
