"""Freeze the fourth-pass starting point without invoking git."""
from pathlib import Path
import json, hashlib
R=Path(__file__).resolve().parents[1]; O=R/'verification/parity-r23'
def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
target=O/'expe-pass4-start.json'
assert not target.exists(), 'Do not replace the starting snapshot'
files={p.relative_to(R).as_posix():digest(p) for folder in ['project','tools','server','docs'] for p in (R/folder).rglob('*') if p.is_file() and not any(x in p.parts for x in ['.godot','node_modules','__pycache__','.wrangler'])}
source=Path('C:/Clauede Code/dungeon-bot/bot')
original={p.relative_to(source).as_posix():digest(p) for folder in ['src','dist'] for p in (source/folder).rglob('*.lua')}
target.write_text(json.dumps({'files':files,'original':original},indent=2),encoding='utf-8')
(O/'expe-pass4-start-ledger.json').write_bytes((O/'expe.json').read_bytes())
print(json.dumps({'protected_files':len(files),'source_files':len(original)}))
