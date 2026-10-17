"""Build the offline semantic index for Awan (architecture §1).

One-off on the workstation — never on the phone:

    python tools/semantic/build_index.py

It produces, under `assets/semantic/`:

  * `quran_vecs.i8`      int8 vectors, row-major, `n * dim` bytes
  * `quran_scales.f32`   one float32 per row (dequantisation factor)
  * `quran_index.json`   row -> {surah, ayah, kind} so the UI can look the text up
  * `tokenizer.json`     the SentencePiece unigram vocabulary + scores, for Dart
  * `model/model_int8.onnx`  the query encoder, quantised for on-device use

The document for each ayah is the ayah joined with its Muyassar tafsir, because
the ayah alone is often too terse to match a feeling ("الصبر عند فقدان العمل")
while the tafsir carries the emotional vocabulary.
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "assets"
# Heavy intermediates (the fp32 cache, the fp32 graph) stay out of `assets/`:
# everything under `assets/semantic/` ships inside the APK, and a 9.5 MB cache
# file that only the build needs is 9.5 MB of the user's download.
BUILD = ROOT / "build" / "semantic"
BUILD.mkdir(parents=True, exist_ok=True)
OUT = ASSETS / "semantic"
# Chosen on evidence, not reputation: see `compare_models.py`. Over the same
# 8 meaning queries the e5 small model scores MRR 0.152 against 0.058 for
# paraphrase-multilingual-MiniLM-L12-v2, at the same 384 dimensions and the same
# 118 MB int8 footprint. E5 is trained with "query:"/"passage:" prefixes, and the
# app must send "query: " with every search.
MODEL_NAME = "intfloat/multilingual-e5-small"

# Arabic input is normalised on both sides (here and in Dart) before the
# tokenizer sees it: diacritics carry no retrieval signal and they differ
# between the Uthmani text and anything the reader types.
TASHKEEL = dict.fromkeys(
    [ord(c) for c in "\u0610\u0611\u0612\u0613\u0614\u0615\u0616\u0617\u0618"
     "\u0619\u061a\u064b\u064c\u064d\u064e\u064f\u0650\u0651\u0652\u0653"
     "\u0654\u0655\u0656\u0657\u0658\u0670\u06d6\u06d7\u06d8\u06d9\u06da"
     "\u06db\u06dc\u06df\u06e0\u06e1\u06e2\u06e3\u06e4\u06e7\u06e8\u06ea"
     "\u06eb\u06ec\u06ed"],
    None,
)


def normalise(text: str) -> str:
    """Fold the text to the shape the index was built with.

    Kept deliberately small: strip tashkeel and tatweel, unify the alef and ya
    forms, collapse whitespace. Anything more aggressive starts deleting the
    distinctions the reader is searching for.
    """
    import unicodedata

    text = unicodedata.normalize("NFKC", text)
    # The dagger alef is dropped, not turned into an alef: in Tanzil's simple
    # spelling the word already carries its alef, and «عَلَىٰ» must fold to
    # «علي» — mapping it to an alef would produce «عليا».
    text = text.translate(TASHKEEL)
    text = text.replace("\u0640", "")          # tatweel
    text = text.replace("\u0622", "\u0627").replace("\u0623", "\u0627")
    text = text.replace("\u0625", "\u0627").replace("\u0649", "\u064a")
    text = text.replace("\u06cc", "\u064a").replace("\u06a9", "\u0643")
    text = " ".join(text.split())
    return text.strip()


def load_docs() -> list[dict]:
    quran = json.loads((ASSETS / "data" / "quran_uthmani.json").read_text("utf-8"))
    tafsir = json.loads(
        (ASSETS / "addons" / "tafsir_muyassar.json").read_text("utf-8")
    )["ayahs"]

    # The Mushaf text is Uthmani: «ٱلصَّلَوٰة» carries a dagger alef, and stripping
    # its diacritics yields «الصلوة», which no embedding model reads as «الصلاة».
    # The index is therefore built from Tanzil's *simple* text (standard
    # spelling, canonical order) while the reader keeps the Mushaf copy.
    simple_path = Path(__file__).resolve().parent / "data" / "quran-simple.txt"
    simple_lines: list[str] = []
    if simple_path.exists():
        simple_lines = [
            line.strip()
            for line in simple_path.read_text("utf-8").splitlines()
            if line.strip() and not line.startswith("#")
        ]
    expected = sum(len(v) for v in quran["ayahs"].values())
    if len(simple_lines) != expected:
        print(f"  (simple text has {len(simple_lines)} lines, expected {expected})")
        simple_lines = []

    docs: list[dict] = []
    cursor = 0
    for surah_id, ayahs in quran["ayahs"].items():
        for index, uthmani in enumerate(ayahs, start=1):
            key = f"{surah_id}:{index}"
            text = simple_lines[cursor] if simple_lines else uthmani
            cursor += 1
            docs.append(
                {
                    "surah": int(surah_id),
                    "ayah": index,
                    "kind": "quran",
                    "text": normalise(text),
                    "tafsir": normalise(tafsir.get(key, "")),
                }
            )
    return docs


def export_tokenizer(tokenizer, path: Path) -> None:
    """The unigram vocabulary with the scores Dart needs for Viterbi.

    The fast tokenizer (Rust) exposes the unigram model directly: `get_vocab()`
    carries the log-probability of each piece, and `get_vocab()` on the tokenizer
    wrapper carries its id. They are merged here so Dart can run the same Viterbi
    with the same numbers.
    """
    backend = tokenizer.backend_tokenizer
    state = json.loads(backend.to_str())
    # The serialised unigram model is `[[piece, log_prob], …]` **in id order**;
    # using that order is what keeps piece ids and the graph's embedding rows
    # aligned. `get_vocab()` is not used: for fast tokenizers it also carries
    # added tokens, and the two id spaces are not guaranteed to line up.
    vocab_pairs = state["model"]["vocab"]
    pieces = [piece for piece, _ in vocab_pairs]
    scores = [float(score) for _, score in vocab_pairs]
    size = len(pieces)
    payload = {
        "model": "unigram",
        "unk_id": int(tokenizer.unk_token_id),
        "pieces": pieces,
        "scores": scores,
    }
    path.write_text(json.dumps(payload, ensure_ascii=False), "utf-8")
    print(f"  tokenizer: {len(pieces)} pieces")


def main() -> int:
    import torch
    from sentence_transformers import SentenceTransformer

    OUT.mkdir(parents=True, exist_ok=True)
    # The graphs go to `build/`: the quantised one is 118 MB and is downloaded
    # once by the app, never bundled. `assets/semantic/` stays at ~11 MB.
    (BUILD / "model").mkdir(parents=True, exist_ok=True)

    print("loading corpus…")
    docs = load_docs()
    print(f"  {len(docs)} ayat")

    print(f"loading {MODEL_NAME}…")
    model = SentenceTransformer(MODEL_NAME)
    model.max_seq_length = 256
    dim = model.get_sentence_embedding_dimension()
    print(f"  dim={dim}")

    # Ayah + tafsir, separated so the model sees two coherent spans.
    texts = [f"passage: {d['text']} {d['tafsir']}".strip() for d in docs]

    cache = BUILD / "quran_vecs.f32.npy"
    print("encoding…")
    if cache.exists() and "--reuse" in sys.argv:
        vectors = np.load(cache).astype(np.float32)
        print("  reused cached vectors")
    else:
        vectors = model.encode(
            texts,
            batch_size=64,
            show_progress_bar=True,
            convert_to_numpy=True,
            normalize_embeddings=True,
        ).astype(np.float32)
        np.save(cache, vectors)

    # Scalar quantisation, one scale per row: a global scale would crush the
    # short ayat whose vector is dominated by a few large components.
    scales = np.abs(vectors).max(axis=1) / 127.0
    scales[scales == 0] = 1.0
    quantised = np.clip(np.round(vectors / scales[:, None]), -127, 127).astype(np.int8)

    (OUT / "quran_vecs.i8").write_bytes(quantised.tobytes())
    (OUT / "quran_scales.f32").write_bytes(scales.astype(np.float32).tobytes())
    (OUT / "quran_index.json").write_text(
        json.dumps(
            {
                "dim": dim,
                "count": len(docs),
                "model": MODEL_NAME,
                "rows": [
                    {"s": d["surah"], "a": d["ayah"], "k": d["kind"]} for d in docs
                ],
            },
            ensure_ascii=False,
        ),
        "utf-8",
    )
    print(f"  vectors: {quantised.nbytes / 1e6:.1f} MB")

    print("exporting ONNX…")
    export_tokenizer(model.tokenizer, OUT / "tokenizer.json")

    class Encoder(torch.nn.Module):
        """Mean pooling + L2 normalisation, so the app ships one graph."""

        def __init__(self, transformer) -> None:
            super().__init__()
            self.transformer = transformer

        def forward(self, input_ids, attention_mask):
            out = self.transformer(
                input_ids=input_ids, attention_mask=attention_mask
            ).last_hidden_state
            mask = attention_mask.unsqueeze(-1).float()
            summed = (out * mask).sum(dim=1)
            counts = mask.sum(dim=1).clamp(min=1e-9)
            return torch.nn.functional.normalize(summed / counts, p=2, dim=1)

    # The workstation has a GPU and sentence-transformers used it; the export
    # must happen on CPU so the dummy tensors and the weights share a device.
    encoder = Encoder(model[0].auto_model).to("cpu").eval()
    # transformers 5 traces SDPA attention through a helper that assumes a 4-D
    # mask during ONNX export; eager attention is the supported export path.
    encoder.transformer.config._attn_implementation = "eager"

    # transformers 5's mask factory branches on a traced length that is a scalar
    # during export. The 2-D mask BERT was trained with is a pure additive
    # (1 - mask) * -inf in the last dimension, so build that directly: the graph
    # stays standard and no transformers internals are shipped to the phone.
    import transformers.models.bert.modeling_bert as bert_module

    def _additive_mask(*, config=None, inputs_embeds=None, attention_mask=None, **kwargs):
        if attention_mask is None:
            return None
        if attention_mask.dim() == 2:
            neg = torch.finfo(inputs_embeds.dtype).min
            return (1.0 - attention_mask[:, None, None, :].to(inputs_embeds.dtype)) * neg
        return attention_mask

    bert_module.create_bidirectional_mask = _additive_mask
    dummy_ids = torch.ones((1, 128), dtype=torch.long)
    dummy_mask = torch.ones((1, 128), dtype=torch.long)
    fp32_path = BUILD / "model" / "model_fp32.onnx"
    torch.onnx.export(
        encoder,
        (dummy_ids, dummy_mask),
        str(fp32_path),
        input_names=["input_ids", "attention_mask"],
        output_names=["sentence_embedding"],
        dynamic_axes={
            "input_ids": {1: "seq"},
            "attention_mask": {1: "seq"},
            "sentence_embedding": {0: "batch"},
        },
        opset_version=17,
        do_constant_folding=True,
    )
    print(f"  fp32: {fp32_path.stat().st_size / 1e6:.1f} MB")

    from onnxruntime.quantization import QuantType, quantize_dynamic

    int8_path = BUILD / "model" / "model_int8.onnx"
    quantize_dynamic(
        str(fp32_path),
        str(int8_path),
        weight_type=QuantType.QInt8,
        per_channel=True,
    )
    print(f"  int8: {int8_path.stat().st_size / 1e6:.1f} MB")

    # Sanity: the exported graph must agree with sentence-transformers.
    import onnxruntime as ort

    session = ort.InferenceSession(str(int8_path), providers=["CPUExecutionProvider"])
    encoded = model.tokenizer(
        [normalise("الصبر عند فقدان العمل")],
        padding="max_length",
        max_length=128,
        truncation=True,
        return_tensors="np",
    )
    onnx_vec = session.run(
        None,
        {
            "input_ids": encoded["input_ids"].astype(np.int64),
            "attention_mask": encoded["attention_mask"].astype(np.int64),
        },
    )[0][0]
    st_vec = model.encode(["الصبر عند فقدان العمل"], normalize_embeddings=True)[0]
    cosine = float(np.dot(onnx_vec, st_vec))
    print(f"  onnx vs sentence-transformers cosine: {cosine:.4f}")

    scores = quantised.astype(np.float32) * scales[:, None]
    scores /= np.linalg.norm(scores, axis=1, keepdims=True)
    probe = st_vec @ scores.T
    best = int(np.argmax(probe))
    print(
        "  probe 'الصبر عند فقدان العمل' -> "
        f"{docs[best]['surah']}:{docs[best]['ayah']} ({probe[best]:.3f})"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
