
import json, sys
sys.path.insert(0, r"H:\Awan_pro\Awan_Pro\tools\semantic")
import numpy as np, onnxruntime as ort
from transformers import AutoTokenizer
from build_index import normalise

tok = AutoTokenizer.from_pretrained("intfloat/multilingual-e5-small")
sess = ort.InferenceSession(r"H:\Awan_pro\Awan_Pro\build\semantic\model_int8.onnx", providers=["CPUExecutionProvider"])
queries = ["الصبر عند فقدان العمل", "دعاء عند القلق والخوف", "أجر من ينفق على الفقراء"]
out = {}
for q in queries:
    text = "query: " + normalise(q)
    enc = tok([text], padding="max_length", max_length=128, truncation=True, return_tensors="np")
    vec = sess.run(None, {"input_ids": enc["input_ids"].astype(np.int64), "attention_mask": enc["attention_mask"].astype(np.int64)})[0][0]
    out[q] = [round(float(v), 6) for v in vec]
json.dump(out, open(r"H:\Awan_pro\Awan_Pro\test\fixtures\query_vectors.json","w",encoding="utf-8"), ensure_ascii=False)
print("ok", len(out), len(next(iter(out.values()))))
