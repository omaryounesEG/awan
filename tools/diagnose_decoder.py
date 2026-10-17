"""Load the shrunken decoder in ONNX Runtime and print the real error.

sherpa-onnx swallows inference failures and returns an empty string, which is
useless for diagnosis. This opens the model directly so a broken graph says why.
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import onnxruntime as ort

ROOT = Path(__file__).resolve().parents[1]
MODEL = ROOT / "build" / "recitation_shrink" / "base-ar-quran-decoder.i8emb.onnx"


def main() -> int:
    so = ort.SessionOptions()
    so.log_severity_level = 1
    try:
        sess = ort.InferenceSession(str(MODEL), so, providers=["CPUExecutionProvider"])
    except Exception as e:  # noqa: BLE001 — this is the diagnosis
        print("LOAD FAILED:", type(e).__name__, str(e)[:800])
        return 1

    print("inputs:", [(i.name, i.shape, i.type) for i in sess.get_inputs()])
    feeds = {}
    for i in sess.get_inputs():
        dtype = np.int64 if "int64" in i.type else np.float32
        shape = [d if isinstance(d, int) else 1 for d in i.shape]
        feeds[i.name] = np.zeros(shape, dtype=dtype)
    try:
        out = sess.run(None, feeds)
        print("OK, outputs:", len(out), [o.shape for o in out][:3])
        return 0
    except Exception as e:  # noqa: BLE001
        print("RUN FAILED:", type(e).__name__, str(e)[:800])
        return 1


if __name__ == "__main__":
    sys.exit(main())
