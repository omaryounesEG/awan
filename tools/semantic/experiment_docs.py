"""Which document shape retrieves meaning best: ayah, tafsir, or both?

    python tools/semantic/experiment_docs.py
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_index import MODEL_NAME, load_docs, normalise  # noqa: E402

CASES = [
    ("الصبر عند فقدان العمل", [(2, 155), (2, 156), (94, 5), (3, 146)]),
    ("دعاء عند القلق والخوف", [(13, 28), (9, 40), (2, 286), (3, 173)]),
    ("أجر من ينفق على الفقراء", [(2, 261), (2, 274), (76, 8), (2, 177)]),
    ("بر الوالدين", [(17, 23), (31, 14), (46, 15), (29, 8)]),
    ("العدل بين الناس", [(4, 58), (5, 8), (16, 90), (49, 9)]),
    ("الاستغفار بعد الذنب", [(3, 135), (39, 53), (11, 3), (20, 82)]),
    ("الرزق بيد الله", [(13, 26), (29, 62), (51, 58), (11, 6)]),
]


def rank_of(matrix: np.ndarray, query_vec: np.ndarray, key: tuple[int, int], docs) -> int:
    scores = matrix @ query_vec
    order = np.argsort(-scores)
    target = next(
        (i for i, d in enumerate(docs) if (d["surah"], d["ayah"]) == key), None
    )
    if target is None:
        return -1
    return int(np.where(order == target)[0][0]) + 1


def main() -> int:
    from sentence_transformers import SentenceTransformer

    docs = load_docs()
    model = SentenceTransformer(MODEL_NAME)
    model.max_seq_length = 256

    shapes = {
        "ayah": [d["text"] for d in docs],
        "tafsir": [d["tafsir"] for d in docs],
        "joined": [f"{d['text']} {d['tafsir']}".strip() for d in docs],
    }
    # Keep one row per ayah so ranks are comparable.
    matrices: dict[str, np.ndarray] = {}
    for name, texts in shapes.items():
        vectors = model.encode(
            texts,
            batch_size=64,
            convert_to_numpy=True,
            normalize_embeddings=True,
            show_progress_bar=False,
        )
        matrices[name] = vectors.astype(np.float32)

    for query, gold in CASES:
        vector = model.encode(
            [normalise(query)], normalize_embeddings=True, convert_to_numpy=True
        )[0]
        print(f"\n» {query}")
        for name, matrix in matrices.items():
            ranks = [rank_of(matrix, vector, key, docs) for key in gold]
            hits = [r for r in ranks if 0 < r <= 10]
            mrr = sum(1.0 / r for r in ranks if r > 0) / len(ranks)
            print(f"   {name:7s} ranks={ranks} hits@10={len(hits)} MRR={mrr:.3f}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
