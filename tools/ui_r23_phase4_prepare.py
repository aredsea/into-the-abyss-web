from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23/ui-phase4';O.mkdir(exist_ok=True)
def dump(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
if not (O/'ui-before.json').exists():
    (O/'ui-before.json').write_bytes((R/'verification/parity-r23/ui.json').read_bytes())
    (O/'ui-report-before.md').write_bytes((R/'R23-ui.md').read_bytes())
    dump(O/'ui-hashes-before.json',{p.relative_to(R).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for folder in ['project','tools','server','docs'] for p in (R/folder).rglob('*') if p.is_file() and not any(x in p.parts for x in ['.godot','node_modules','__pycache__'])})
print(O)
