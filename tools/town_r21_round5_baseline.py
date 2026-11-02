"""Capture pass-five inputs without Git; never read or write user saves."""
from pathlib import Path
import hashlib,json
R=Path(__file__).resolve().parents[1]
V=R/'verification/town-r21/round5';V.mkdir(parents=True,exist_ok=True)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
p=V/'baseline.json'
if not p.exists():
    files={x.relative_to(R).as_posix():sha(x) for folder in ['project','tools'] for x in (R/folder).rglob('*') if x.is_file() and '.godot' not in x.parts and x.suffix not in ['.pyc','.import']}
    p.write_text(json.dumps({'files':files,'pck_bytes':(R/'docs/index.pck').stat().st_size,'pck_sha256':sha(R/'docs/index.pck')},indent=2),encoding='utf-8')
print(p)
