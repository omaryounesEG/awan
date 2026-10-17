"""Quality check for the built index: does meaning search actually find meaning?

    python tools/semantic/evaluate_index.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "semantic"

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_index import MODEL_NAME, load_docs, normalise  # noqa: E402

QUERIES = [
    "الصبر عند فقدان العمل",
    "ماذا أقول إذا أصابني القلق",
    "أجر من ينفق على الفقراء",
    "بر الوالدين",
    "آيات عن العدل بين الناس",
    "الاستغفار بعد الذنب",
    "الرزق بيد الله",
]


def main() -> int:
    from sentence_transformers import SentenceTransformer

    docs = load_docs()
    manifest = json.loads((OUT / "quran_index.json").read_text("utf-8"))
    vectors = np.fromfile(OUT / "quran_vecs.i8", dtype=np.int8).reshape(
        manifest["count"], manifest["dim"]
    )
    scales = np.fromfile(OUT / "quran_scales.f32", dtype=np.float32)
    matrix = vectors.astype(np.float32) * scales[:, None]
    matrix /= np.linalg.norm(matrix, axis=1, keepdims=True)

    model = SentenceTransformer(MODEL_NAME)
    model.max_seq_length = 256

    for query in QUERIES:
        vector = model.encode(
            [normalise(query)], normalize_embeddings=True, convert_to_numpy=True
        )[0]
        scores = matrix @ vector
        top = np.argsort(-scores)[:5]
        print(f"\n» {query}")
        for index in top:
            doc = docs[int(index)]
            print(
                f"   {scores[index]:.3f}  {doc['surah']}:{doc['ayah']}  {doc['text'][:70]}"
            )
    return 0


if __name__ == "__main__":
    sys.exit(main())
