"""Is the embedding model itself able to tell these Arabic sentences apart?

    python tools/semantic/diagnose_model.py
"""

from __future__ import annotations

import re
import sys

import numpy as np

TASHKEEL = re.compile(r"[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]")

PAIRS = [
    ("الصبر عند فقدان العمل", "إنما يوفى الصابرون أجرهم بغير حساب"),
    ("الصبر عند فقدان العمل", "والنخل باسقات لها طلع نضيد"),
    ("دعاء عند القلق والخوف", "ألا بذكر الله تطمئن القلوب"),
    ("دعاء عند القلق والخوف", "والنخل باسقات لها طلع نضيد"),
    ("بر الوالدين", "وقضى ربك ألا تعبدوا إلا إياه وبالوالدين إحسانا"),
    ("بر الوالدين", "والنخل باسقات لها طلع نضيد"),
    ("العدل بين الناس", "إن الله يأمر بالعدل والإحسان وإيتاء ذي القربى"),
    ("العدل بين الناس", "والنخل باسقات لها طلع نضيد"),
]


def strip(text: str) -> str:
    return " ".join(TASHKEEL.sub("", text).split())


def main() -> int:
    from sentence_transformers import SentenceTransformer

    model = SentenceTransformer("sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2")
    texts = sorted({t for pair in PAIRS for t in pair})
    variants = {
        "raw": texts,
        "stripped": [strip(t) for t in texts],
    }
    for name, batch in variants.items():
        vectors = model.encode(batch, normalize_embeddings=True, convert_to_numpy=True)
        index = {t: i for i, t in enumerate(batch)}
        print(f"\n== {name} ==")
        for a, b in PAIRS:
            source = batch[texts.index(a)]
            target = batch[texts.index(b)]
            cosine = float(np.dot(vectors[index[source]], vectors[index[target]]))
            print(f"  {cosine:+.3f}  {source[:34]:34s} | {target[:34]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
