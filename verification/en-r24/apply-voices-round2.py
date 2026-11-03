import json
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(root / 'tools'))
from en_r24 import load, write_en

voices = json.loads(Path(__file__).with_name('voices-round2.json').read_text(encoding='utf-8'))
for cid, speech in voices.items():
    path, data = load(cid)
    data['en']['speech'] = speech
    write_en(path, data['en'])
    print(cid, len(data['en']['display']))
