"""Shared dictation helpers: IPC status, typing, clipboard."""

from __future__ import annotations

import json
import shutil
import subprocess
import threading
import time

_typing_lock = threading.Lock()
_last_live_sent = 0.0
_WTYPE_CHUNK = 256


def send_status(
    state: str,
    message: str = "",
    text: str = "",
    live_transcript: str = "",
    partial_transcript: str = "",
    engine: str = "",
) -> None:
    payload: dict[str, str] = {"state": state, "message": message}
    if text:
        payload["text"] = text
    if live_transcript or partial_transcript or state == "recording":
        payload["liveTranscript"] = live_transcript
        payload["partialTranscript"] = partial_transcript
    if engine:
        payload["engine"] = engine
    try:
        subprocess.run(
            ["qs", "ipc", "-c", "noctalia-shell", "call", "plugin:dictation", "setStatus", json.dumps(payload)],
            capture_output=True, timeout=2, check=False,
        )
    except Exception:
        pass


def send_live(live_transcript: str, partial_transcript: str) -> None:
    global _last_live_sent
    now = time.monotonic()
    if now - _last_live_sent < 0.25:
        return
    _last_live_sent = now
    send_status("recording", "live", live_transcript=live_transcript, partial_transcript=partial_transcript)


def _needs_paste(text: str) -> bool:
    if not text.isascii():
        return True
    return any(ord(c) < 32 or ord(c) == 127 for c in text)


def _type_text_paste(text: str) -> None:
    try:
        subprocess.run(["wl-copy"], input=text.encode(), check=True, timeout=2)
    except Exception:
        return
    time.sleep(0.12)
    for cmd in [
        ["wtype", "-M", "ctrl", "v", "-m", "ctrl"],
        ["ydotool", "key", "29:1", "47:1", "47:0", "29:0"],
    ]:
        try:
            if subprocess.run(cmd, capture_output=True, timeout=5, check=False).returncode == 0:
                break
        except Exception:
            continue


def _type_with_wtype(text: str) -> bool:
    if not shutil.which("wtype") or not text:
        return False
    try:
        for i in range(0, len(text), _WTYPE_CHUNK):
            chunk = text[i:i + _WTYPE_CHUNK]
            args = ["wtype"]
            if chunk.startswith("-"):
                args.extend(["--", chunk])
            else:
                args.append(chunk)
            if subprocess.run(args, capture_output=True, timeout=10, check=False).returncode != 0:
                return False
            if i + _WTYPE_CHUNK < len(text):
                time.sleep(0.02)
        return True
    except Exception:
        return False


def type_committed(text: str) -> None:
    if not text:
        return
    with _typing_lock:
        if _needs_paste(text):
            _type_text_paste(text)
        elif not _type_with_wtype(text):
            _type_text_paste(text)


def copy_to_clipboard(text: str) -> None:
    try:
        subprocess.run(["wl-copy"], input=text.encode(), check=True, timeout=2)
    except Exception:
        pass


def check_injection_tools() -> list[str]:
    missing = [t for t in ["wl-copy", "wtype"] if not shutil.which(t)]
    if not missing:
        return []
    if shutil.which("ydotool"):
        return []
    return missing
