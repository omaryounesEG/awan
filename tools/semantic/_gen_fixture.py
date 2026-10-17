
import json, sys
sys.path.insert(0, r"H:\Awan_pro\Awan_Pro\tools\semantic")
from build_index import normalise
from transformers import AutoTokenizer

tok = AutoTokenizer.from_pretrained("intfloat/multilingual-e5-small", use_fast=True)
SAMPLES = [
  "الصبر عند فقدان العمل",
  "الحمد لله رب العالمين",
  "يا أيها الذين آمنوا استعينوا بالصبر والصلاة",
  "ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة",
  "اللهم إني أسألك العفو والعافية",
  "زكاة المال على الفقير والمسكين",
]
out = []
for s in SAMPLES:
    n = normalise(s)
    ids = tok(n, add_special_tokens=False)["input_ids"]
    ids2 = tok("query: " + n, add_special_tokens=False)["input_ids"]
    out.append({"text": n, "ids": ids, "ids_with_prefix": ids2})
path = r"H:\Awan_pro\Awan_Pro\test\fixtures\sentencepiece_samples.json"
import os
os.makedirs(os.path.dirname(path), exist_ok=True)
json.dump({"model": "intfloat/multilingual-e5-small", "samples": out}, open(path,"w",encoding="utf-8"), ensure_ascii=False, indent=1)
print("wrote", path)
for o in out: print(o["text"], "->", len(o["ids"]))
