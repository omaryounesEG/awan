"""Pick the query encoder on evidence, not on reputation.

    python tools/semantic/compare_models.py

Both candidates are 384-d multilingual sentence-transformers small enough to run
on a phone; the winner is chosen by MRR@10 over a handful of meaning queries
whose verses a reader would expect to see.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_index import load_docs, normalise  # noqa: E402

CASES = [
    ("الصبر عند فقدان العمل", [(2, 155), (2, 156), (94, 5), (3, 146)]),
    ("دعاء عند القلق والخوف", [(13, 28), (9, 40), (2, 286), (3, 173)]),
    ("أجر من ينفق على الفقراء", [(2, 261), (2, 274), (76, 8), (2, 177)]),
    ("بر الوالدين", [(17, 23), (31, 14), (46, 15), (29, 8)]),
    ("العدل بين الناس", [(4, 58), (5, 8), (16, 90), (49, 9)]),
    ("الاستغفار بعد الذنب", [(3, 135), (39, 53), (11, 3), (20, 82)]),
    ("الرزق بيد الله", [(13, 26), (29, 62), (51, 58), (11, 6)]),
    ("اليتيم وحقه", [(93, 9), (89, 17), (2, 220), (4, 6)]),
]

MODELS = [
    ("sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2", ""),
    ("intfloat/multilingual-e5-small", "e5"),
]


def evaluate(model_name: str, flavour: str, docs, texts) -> None:
    from sentence_transformers import SentenceTransformer

    model = SentenceTransformer(model_name)
    model.max_seq_length = 256

    def encode(batch: list[str]) -> np.ndarray:
        return model.encode(
            batch,
            batch_size=64,
            convert_to_numpy=True,
            normalize_embeddings=True,
            show_progress_bar=False,
        ).astype(np.float32)

    matrix = encode([f"passage: {t}" for t in texts] if flavour else texts)
    keys = [(d["surah"], d["ayah"]) for d in docs]
    position = {key: i for i, key in enumerate(keys)}

    reciprocal: list[float] = []
    hits = 0
    total = 0
    for query, gold in CASES:
        needle = f"query: {normalise(query)}" if flavour else normalise(query)
        vector = encode([needle])[0]
        order = np.argsort(-(matrix @ vector))
        ranks = [int(np.where(order == position[key])[0][0]) + 1 for key in gold if key in position]
        reciprocal.extend(1.0 / r for r in ranks)
        hits += sum(1 for r in ranks if r <= 10)
        total += len(ranks)

    print(
        f"{model_name.split('/')[-1]:52s} MRR={np.mean(reciprocal):.3f} "
        f"hits@10={hits}/{total}"
    )


def main() -> int:
    docs = load_docs()
    variants = {
        "ayah": [d["text"] for d in docs],
        "ayah+tafsir": [f"{d['text']} {d['tafsir']}".strip() for d in docs],
    }
    for name, flavour in MODELS:
        for label, texts in variants.items():
            evaluate(name, flavour, docs, texts)
            print(f"    ({label})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
