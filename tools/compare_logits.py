"""Compare the decoder's logits, original vs shrunken, on identical inputs."""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import onnxruntime as ort

ROOT = Path(__file__).resolve().parents[1]
ORIG = ROOT / "build" / "recitation" / "base-ar-quran-decoder.int8.onnx"
SHRUNK = ROOT / "build" / "recitation_shrink" / "base-ar-quran-decoder.i8emb.onnx"


def session(path: Path) -> ort.InferenceSession:
    so = ort.SessionOptions()
    so.log_severity_level = 3
    return ort.InferenceSession(str(path), so, providers=["CPUExecutionProvider"])


def feeds_for(sess: ort.InferenceSession, tokens: np.ndarray, t_audio: int, t_text: int) -> dict:
    out = {}
    for i in sess.get_inputs():
        if i.name == "tokens":
            out[i.name] = tokens
        elif i.name == "offset":
            out[i.name] = np.array([0], dtype=np.int64)
        else:
            shape = [d if isinstance(d, int) else None for d in i.shape]
            shape = [t_audio if d is None and 'n_audio' == str(d) else d for d in shape]
            # Fill the two unknown axes explicitly: batch=1, n_audio=1, T or 448.
            shape = [
                t_audio if s == 'n_audio' else (t_text if s == 'T' else s)
                for s in [d if isinstance(d, int) else (str(x)) for d, x in zip(i.shape, i.shape)]
            ]
            shape = [d if isinstance(d, int) else (1 if idx == 0 else (448 if d is None else 1))
                     for idx, d in enumerate(i.shape)]
            out[i.name] = np.zeros(shape, dtype=np.float32)
    return out


def main() -> int:
    tokens = np.array([[50258, 50259, 220, 3000]], dtype=np.int64)
    a, b = session(ORIG), session(SHRUNK)

    def run(sess: ort.InferenceSession) -> np.ndarray:
        feeds = {}
        for i in sess.get_inputs():
            if i.name == "tokens":
                feeds[i.name] = tokens
            elif i.name == "offset":
                feeds[i.name] = np.array([0], dtype=np.int64)
            else:
                shape = [1 if not isinstance(d, int) else d for d in i.shape]
                feeds[i.name] = np.zeros(shape, dtype=np.float32)
        return sess.run(None, feeds)[0]

    x, y = run(a), run(b)
    print("orig  logits:", x.shape, "min/max", float(x.min()), float(x.max()))
    print("shrunk logits:", y.shape, "min/max", float(y.min()), float(y.max()))
    print("argmax equal:", bool(np.array_equal(x.argmax(-1), y.argmax(-1))))
    print("max |diff|:", float(np.abs(x - y).max()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
