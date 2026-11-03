"""Verify asset invariants and the worktree-only appearance boundary."""
from pathlib import Path
import json,hashlib,sys
R=Path(__file__).resolve().parents[1];O=R/'verification/look-r24'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
before=json.loads((O/'baseline.json').read_text(encoding='utf-8'))
after={p.relative_to(R).as_posix():sha(p) for d in ['project','docs','server','tools'] for p in (R/d).rglob('*') if p.is_file() and not any(x in p.parts for x in ['.godot','node_modules','__pycache__'])}
changed=[p for p in sorted(before.keys()|after.keys()) if before.get(p)!=after.get(p)]
forbidden=[p for p in changed if p.startswith(('project/game/','server/','docs/','project/data/','project/assets/')) or Path(p).name in ['town_screen_r21.gd','facilities_screen_r22.gd','expedition_screen_r22.gd']]
assets=json.loads((R/'ASSET-HASHES.json').read_text(encoding='utf-8'))
mismatch=[v['path'] for v in assets if sha(R/v['path'])!=v['sha256']]
def luminance(s):
 values=[int(s[i:i+2],16)/255 for i in [0,2,4]]
 return sum(a*(v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4) for a,v in zip([.2126,.7152,.0722],values))
def contrast(a,b):
 x,y=sorted([luminance(a),luminance(b)]);return round((y+.05)/(x+.05),2)
result={'changed':changed,'forbidden_changed':forbidden,'original_assets':len(assets),'asset_mismatches':mismatch,'contrast_on_paper':{key:contrast(color,'f4efe3') for key,color in [('ink','111715'),('muted','62665d'),('action_red','c62b15')]}}
(O/'boundaries.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(result,ensure_ascii=True,indent=2));sys.exit(bool(forbidden or mismatch))
