"""Read-only boundary manifest; never invokes git or touches another worktree."""
from pathlib import Path
import hashlib,json,sys
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'verification/parity-r23';OUT.mkdir(parents=True,exist_ok=True)
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def snapshot():
    roots=[ROOT/'project',ROOT/'server',ROOT/'tools',ROOT/'docs']
    return {p.relative_to(ROOT).as_posix():digest(p) for base in roots for p in base.rglob('*') if p.is_file() and not any(x in p.parts for x in ['.godot','node_modules','__pycache__'])}
target=OUT/'before.json'
if sys.argv[1:] == ['before']:
    if target.exists():raise SystemExit('Baseline already exists; refusing to replace it')
    target.write_text(json.dumps(snapshot(),indent=2),encoding='utf-8')
    print('Baseline recorded')
else:
    before=json.loads(target.read_text(encoding='utf-8'));after=snapshot()
    changed=[p for p in sorted(set(before)|set(after)) if before.get(p)!=after.get(p)]
    forbidden=[p for p in changed if p.startswith('docs/') or p.startswith('server/') or (p.startswith('project/game/') and any(x in p for x in ['battle','combat','dungeon','expedition','gear_rules','personal_rules','trait_rules']))]
    result={'baseline_files':len(before),'changed':changed,'forbidden_changed':forbidden}
    (OUT/'write-audit.json').write_text(json.dumps(result,indent=2),encoding='utf-8');print(json.dumps(result,indent=2))
    sys.exit(bool(forbidden))
