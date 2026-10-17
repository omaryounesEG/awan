"""Prove the shrunken decoder still recites the same ayah.

A model that is 61% smaller and says something different is not an optimisation,
it is a bug. This decodes the same sample through the original decoder and the
shrunken one and compares the transcripts word for word.
"""
from __future__ import annotations

import sys
import wave
from pathlib import Path

import numpy as np
import sherpa_onnx

ROOT = Path(__file__).resolve().parents[1]
ENCODER = ROOT / "build" / "recitation" / "base-ar-quran-encoder.int8.onnx"
ORIGINAL = ROOT / "build" / "recitation" / "base-ar-quran-decoder.int8.onnx"
SHRUNK = ROOT / "build" / "recitation_shrink" / "base-ar-quran-decoder.i8emb.onnx"
TOKENS = ROOT / "build" / "recitation" / "base-ar-quran-tokens.txt"
WAV = ROOT / "assets" / "recitation" / "sample.wav"


def load() -> np.ndarray:
    with wave.open(str(WAV)) as w:
        raw = w.readframes(w.getnframes())
    return np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0


def transcribe(decoder: Path, samples: np.ndarray) -> str:
    rec = sherpa_onnx.OfflineRecognizer.from_whisper(
        encoder=str(ENCODER),
        decoder=str(decoder),
        tokens=str(TOKENS),
        language="ar",
        task="transcribe",
        tail_paddings=1000,
        num_threads=2,
    )
    s = rec.create_stream()
    s.accept_waveform(16000, samples)
    rec.decode_streams([s])
    return s.result.text.strip()


def main() -> int:
    samples = load()
    a = transcribe(ORIGINAL, samples)
    b = transcribe(SHRUNK, samples)
    print(f"original ({ORIGINAL.stat().st_size / 1e6:.1f} MB): {a}")
    print(f"shrunk   ({SHRUNK.stat().st_size / 1e6:.1f} MB): {b}")
    same = a.replace(" ", "") == b.replace(" ", "")
    print("MATCH" if same else "DIFFERENT")
    return 0 if same else 1


if __name__ == "__main__":
    sys.exit(main())
