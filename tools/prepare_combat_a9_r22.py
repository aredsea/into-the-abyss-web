from pathlib import Path
import hashlib,json
R=Path(__file__).resolve().parents[1]
out=R/'verification/data-r21';out.mkdir(exist_ok=True)
if (out/'a9-start-manifest.json').exists():
 raise SystemExit('A9 start manifest already exists; preserving the original baseline.')
files={str(p.relative_to(R)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for folder in ['project','tools','docs'] for p in (R/folder).rglob('*') if p.is_file() and '.godot' not in p.parts and '__pycache__' not in p.parts}
(out/'a9-start-manifest.json').write_text(json.dumps(files,indent=2),encoding='utf-8')
print('A9 manifest',len(files))
