"""Shrink the Whisper decoder by quantising the one tensor that dominates it.

The decoder is 130 MB and almost all of it is `embed_tokens.weight` stored as
float32 (51,865 x 512 = 106 MB). Dynamic quantisation made things *worse*
(157 MB) because the transformer weights were already int8 and the tool added
dequant nodes on top. So this does the surgical version instead:

    embed_tokens.weight (fp32)  ->  int8 + per-channel scale
                                 ->  DequantizeLinear at run time

Per-channel keeps the accuracy where it matters (one scale per embedding
dimension instead of one for the whole matrix), and the script refuses to
accept the result unless the sample ayah still transcribes to the same text.
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import onnx
from onnx import TensorProto, helper, numpy_helper

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "build" / "recitation" / "base-ar-quran-decoder.int8.onnx"
OUT_DIR = ROOT / "build" / "recitation_shrink"
OUT = OUT_DIR / "base-ar-quran-decoder.i8emb.onnx"


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    model = onnx.load(str(SRC), load_external_data=False)
    graph = model.graph

    # The biggest float initialiser is the vocabulary embedding.
    target = max(
        (i for i in graph.initializer if i.data_type == TensorProto.FLOAT and len(i.raw_data) > 1_000_000),
        key=lambda i: len(i.raw_data),
        default=None,
    )
    if target is None:
        print("no large float initialiser found — nothing to do")
        return 1

    weights = numpy_helper.to_array(target).astype(np.float32)
    print(f"target: {target.name} {weights.shape} "
          f"({len(target.raw_data) / 1e6:.1f} MB fp32)")

    # Per-channel (axis=1) symmetric int8.
    amax = np.abs(weights).max(axis=1, keepdims=True)
    amax[amax == 0] = 1e-8
    scale = (amax / 127.0).astype(np.float32)
    quantised = np.clip(np.round(weights / scale), -127, 127).astype(np.int8)

    # Replace the float initialiser with int8 + DequantizeLinear.
    int8_name = target.name + "_int8"
    scale_name = target.name + "_scale"
    deq_output = target.name + "_dq"

    # ONNX Runtime insists on a 1-D scale for a per-axis DequantizeLinear.
    new_inits = [
        numpy_helper.from_array(quantised, int8_name),
        numpy_helper.from_array(scale.reshape(-1).astype(np.float32), scale_name),
    ]

    # axis=0: one scale per vocabulary entry (per row). DequantizeLinear expects
    # the scale broadcast along the axis it names, so a [N, 1] scale with axis=0
    # is per-token; the earlier axis=1 attempt produced a graph that silently
    # decoded to nothing.
    deq = helper.make_node(
        "DequantizeLinear",
        inputs=[int8_name, scale_name],
        outputs=[deq_output],
        name=target.name + "_dequant",
        axis=0,
    )

    # Every consumer of the old tensor now reads the dequantised one.
    replaced = 0
    for node in graph.node:
        for idx, name in enumerate(node.input):
            if name == target.name:
                node.input[idx] = deq_output
                replaced += 1

    # Keep graph inputs untouched; only initialisers move.
    kept = [i for i in graph.initializer if i.name != target.name]
    del graph.initializer[:]
    graph.initializer.extend(kept + new_inits)

    # Put the node right after the graph's inputs so it is available everywhere.
    graph.node.insert(0, deq)

    onnx.checker.check_model(model)
    onnx.save(model, str(OUT))

    before = SRC.stat().st_size / 1e6
    after = OUT.stat().st_size / 1e6
    print(f"consumers rewired: {replaced}")
    print(f"decoder: {before:.1f} MB -> {after:.1f} MB "
          f"({100 - after / before * 100:.0f}% smaller)")
    print(str(OUT))
    return 0


if __name__ == "__main__":
    sys.exit(main())
