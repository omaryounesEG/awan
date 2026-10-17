
import json, sys
sys.path.insert(0, r"H:\Awan_pro\Awan_Pro\tools\semantic")
from pathlib import Path
from build_index import export_tokenizer, MODEL_NAME
from transformers import AutoTokenizer
tok = AutoTokenizer.from_pretrained(MODEL_NAME, use_fast=True)
out = Path(r"H:\Awan_pro\Awan_Pro\assets\semantic\tokenizer.json")
export_tokenizer(tok, out)
print("ok", out.stat().st_size)
