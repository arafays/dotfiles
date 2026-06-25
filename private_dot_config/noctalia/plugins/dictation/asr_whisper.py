"""faster-whisper streaming fallback (LocalAgreement commit policy)."""

from __future__ import annotations

import queue
import subprocess
import threading
import time
from typing import Any

import numpy as np
import sounddevice as sd
from faster_whisper import WhisperModel

from asr_common import copy_to_clipboard, send_live, send_status, type_committed

SAMPLE_RATE = 16000
MIN_RECORDING_SEC = 0.5


class StreamingASR:
    sep = " "

    def __init__(self, model: WhisperModel, language: str):
        self.model = model
        self.language = language

    def transcribe(self, audio: np.ndarray, init_prompt: str = "") -> list:
        opts: dict[str, Any] = {
            "beam_size": 5,
            "word_timestamps": True,
            "condition_on_previous_text": True,
        }
        if init_prompt:
            opts["initial_prompt"] = init_prompt
        if self.language and self.language != "auto":
            opts["language"] = self.language
        segments, _info = self.model.transcribe(audio, **opts)
        return list(segments)

    def ts_words(self, segments: list) -> list[tuple[float, float, str]]:
        out: list[tuple[float, float, str]] = []
        for segment in segments:
            for word in segment.words:
                if segment.no_speech_prob > 0.9:
                    continue
                out.append((word.start, word.end, word.word))
        return out

    def segments_end_ts(self, res: list) -> list[float]:
        return [s.end for s in res]


class HypothesisBuffer:
    def __init__(self) -> None:
        self.commited_in_buffer: list[tuple[float, float, str]] = []
        self.buffer: list[tuple[float, float, str]] = []
        self.new: list[tuple[float, float, str]] = []
        self.last_commited_time = 0.0

    def insert(self, new: list[tuple[float, float, str]], offset: float) -> None:
        new = [(a + offset, b + offset, t) for a, b, t in new]
        self.new = [(a, b, t) for a, b, t in new if a > self.last_commited_time - 0.1]
        if len(self.new) >= 1 and self.commited_in_buffer:
            for i in range(1, min(min(len(self.commited_in_buffer), len(self.new)), 5) + 1):
                c = " ".join(self.commited_in_buffer[-j][2] for j in range(1, i + 1)[::-1])
                tail = " ".join(self.new[j - 1][2] for j in range(1, i + 1))
                if c == tail:
                    for _ in range(i):
                        self.new.pop(0)
                    break

    def flush(self) -> list[tuple[float, float, str]]:
        commit: list[tuple[float, float, str]] = []
        while self.new:
            if not self.buffer or self.new[0][2] != self.buffer[0][2]:
                break
            na, nb, nt = self.new[0]
            commit.append((na, nb, nt))
            self.last_commited_time = nb
            self.buffer.pop(0)
            self.new.pop(0)
        self.buffer = self.new
        self.new = []
        self.commited_in_buffer.extend(commit)
        return commit

    def pop_commited(self, t: float) -> None:
        while self.commited_in_buffer and self.commited_in_buffer[0][1] <= t:
            self.commited_in_buffer.pop(0)

    def complete(self) -> list[tuple[float, float, str]]:
        return self.buffer


class OnlineASRProcessor:
    SAMPLING_RATE = 16000

    def __init__(self, asr: StreamingASR):
        self.asr = asr
        self.init()

    def init(self) -> None:
        self.audio_buffer = np.array([], dtype=np.float32)
        self.transcript_buffer = HypothesisBuffer()
        self.buffer_time_offset = 0.0
        self.commited: list[tuple[float, float, str]] = []

    def insert_audio_chunk(self, audio: np.ndarray) -> None:
        self.audio_buffer = np.append(self.audio_buffer, audio)

    def prompt(self) -> str:
        k = max(0, len(self.commited) - 1)
        while k > 0 and self.commited[k - 1][1] > self.buffer_time_offset:
            k -= 1
        words = [t for _, _, t in self.commited[:k]]
        prompt: list[str] = []
        length = 0
        while words and length < 200:
            w = words.pop()
            length += len(w) + 1
            prompt.append(w)
        return self.asr.sep.join(prompt[::-1])

    def process_iter(self) -> str:
        res = self.asr.transcribe(self.audio_buffer, init_prompt=self.prompt())
        tsw = self.asr.ts_words(res)
        self.transcript_buffer.insert(tsw, self.buffer_time_offset)
        committed = self.transcript_buffer.flush()
        self.commited.extend(committed)
        if len(self.audio_buffer) / self.SAMPLING_RATE > 15:
            self._trim(res)
        return self.asr.sep.join(w[2] for w in committed)

    def _trim(self, res: list) -> None:
        if not self.commited:
            return
        ends = self.asr.segments_end_ts(res)
        t = self.commited[-1][1]
        if len(ends) > 1:
            e = ends[-2] + self.buffer_time_offset
            while len(ends) > 2 and e > t:
                ends.pop(-1)
                e = ends[-2] + self.buffer_time_offset
            if e <= t:
                self.transcript_buffer.pop_commited(e)
                cut = int((e - self.buffer_time_offset) * self.SAMPLING_RATE)
                self.audio_buffer = self.audio_buffer[cut:]
                self.buffer_time_offset = e

    def finish(self) -> str:
        return self.asr.sep.join(w[2] for w in self.transcript_buffer.complete())

    def partial_text(self, committed: str) -> str:
        pending = [w[2] for w in self.transcript_buffer.buffer]
        partial = self.asr.sep.join(pending)
        if committed and partial:
            return partial
        return partial


def _has_cuda() -> bool:
    try:
        return subprocess.run(
            ["nvidia-smi", "--query-gpu=name", "--format=csv,noheader"],
            capture_output=True, timeout=2, check=False,
        ).returncode == 0
    except Exception:
        return False


def create_model(model_size: str, device: str, compute_type: str) -> WhisperModel:
    if device == "auto":
        device = "cuda" if _has_cuda() else "cpu"
    if device == "cpu" and compute_type == "float16":
        compute_type = "int8"
    return WhisperModel(model_size, device=device, compute_type=compute_type)


def describe(model_size: str, device: str, compute_type: str) -> str:
    if device == "auto":
        device = "cuda" if _has_cuda() else "cpu"
    return f"faster-whisper ({model_size} on {device}, {compute_type})"


def record_session(
    model: WhisperModel,
    language: str,
    stop_event: threading.Event,
    timeout: float,
    engine_label: str,
) -> None:
    asr = StreamingASR(model, language)
    online = OnlineASRProcessor(asr)
    audio_queue: queue.Queue[np.ndarray] = queue.Queue()
    process_interval = 1.0
    full_text = ""

    def callback(indata, frames, time_info, status):
        audio_queue.put(indata.copy().flatten())

    try:
        with sd.InputStream(samplerate=SAMPLE_RATE, channels=1, dtype="float32", callback=callback):
            start = time.monotonic()
            send_status("recording", "", live_transcript="", partial_transcript="", engine=engine_label)
            accumulated = np.array([], dtype=np.float32)
            while not stop_event.is_set():
                if timeout > 0 and time.monotonic() - start >= timeout:
                    break
                try:
                    chunk = audio_queue.get(timeout=0.1)
                    accumulated = np.append(accumulated, chunk)
                except queue.Empty:
                    continue
                if len(accumulated) < SAMPLE_RATE * process_interval:
                    continue
                online.insert_audio_chunk(accumulated)
                accumulated = np.array([], dtype=np.float32)
                text = online.process_iter()
                if text:
                    type_committed(text)
                    full_text += text
                send_live(full_text, online.partial_text(full_text))

            if len(accumulated) > 0:
                online.insert_audio_chunk(accumulated)
            tail = online.finish()
            if tail:
                type_committed(tail)
                full_text += tail

        if time.monotonic() - start < MIN_RECORDING_SEC:
            send_status("idle", "cancelled", live_transcript="", partial_transcript="")
            return
        if full_text:
            copy_to_clipboard(full_text)
            send_status("idle", "copied", full_text, live_transcript="", partial_transcript="", engine=engine_label)
        else:
            send_status("idle", "silence", live_transcript="", partial_transcript="", engine=engine_label)
    except Exception as exc:
        send_status("error", f"{exc!r}", live_transcript="", partial_transcript="")
