"""Quantise the Quran Whisper decoder further and prove it still transcribes.

The published decoder is 130 MB of int8 transformer weights *plus* a float32
token-embedding matrix (51k x 512), which is where most of the bytes live. The
embedding is a Gather lookup: quantising it to int8 should cut the file to
roughly a third without touching accuracy in any way a listener can hear.

This script is deliberately paranoid: it does not just quantise, it decodes the
bundled sample with both models and prints both transcripts side by side. A
smaller model that recites differently is not a win.
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import onnx
import sherpa_onnx
from onnxruntime.quantization import QuantType, quantize_dynamic

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "build" / "recitation"
OUT = ROOT / "build" / "recitation_quant"
WAV = ROOT / "assets" / "recitation" / "sample.wav"


def load_wav() -> np.ndarray:
    import wave

    with wave.open(str(WAV)) as w:
        if w.getframerate() != 16000 or w.getnchannels() != 1:
            raise SystemExit(
                f"sample is {w.getframerate()} Hz / {w.getnchannels()} ch, expected 16 kHz mono"
            )
        raw = w.readframes(w.getnframes())
    return np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0


def decode(encoder: Path, decoder: Path, samples: np.ndarray) -> str:
    rec = sherpa_onnx.OfflineRecognizer.from_whisper(
        encoder=str(encoder),
        decoder=str(decoder),
        tokens=str(SRC / "base-ar-quran-tokens.txt"),
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
    OUT.mkdir(parents=True, exist_ok=True)
    samples = load_wav()

    src_decoder = SRC / "base-ar-quran-decoder.int8.onnx"
    q_decoder = OUT / "base-ar-quran-decoder.int8q.onnx"

    if not q_decoder.exists():
        print("quantising decoder (MatMul + Gather -> int8)…", flush=True)
        quantize_dynamic(
            model_input=str(src_decoder),
            model_output=str(q_decoder),
            weight_type=QuantType.QInt8,
            op_types_to_quantize=["MatMul", "Gather"],
            per_channel=True,
            reduce_range=False,
        )
        onnx.checker.check_model(str(q_decoder))

    base_mb = src_decoder.stat().st_size / 1e6
    q_mb = q_decoder.stat().st_size / 1e6
    print(f"decoder: {base_mb:.1f} MB -> {q_mb:.1f} MB "
          f"({100 - q_mb / base_mb * 100:.0f}% smaller)")

    encoder = SRC / "base-ar-quran-encoder.int8.onnx"
    a = decode(encoder, src_decoder, samples)
    b = decode(encoder, q_decoder, samples)
    print(f"original : {a}")
    print(f"quantised: {b}")

    same = a.replace(" ", "") == b.replace(" ", "")
    print("MATCH" if same else "DIFFERENT")
    return 0 if same else 1


if __name__ == "__main__":
    sys.exit(main())
