from pathlib import Path
import hashlib,json
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23/ui-phase3';O.mkdir(exist_ok=True)
def dump(p,x):p.write_text(json.dumps(x,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
if not (O/'ui-before.json').exists():
    (O/'ui-before.json').write_bytes((R/'verification/parity-r23/ui.json').read_bytes())
    (O/'ui-report-before.md').write_bytes((R/'R23-ui.md').read_bytes())
    hashes={str(p.relative_to(R)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for folder in ['project','tools','server'] for p in (R/folder).rglob('*') if p.is_file() and not any(x in p.parts for x in ['.godot','node_modules','__pycache__'])}
    dump(O/'ui-hashes-before.json',hashes)
print(O)
