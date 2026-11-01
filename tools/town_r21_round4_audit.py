"""Byte invariants and allowed-scope audit, independent of Git."""
from pathlib import Path
import hashlib,json
R=Path(__file__).resolve().parents[1];V=R/'verification/town-r21/round4'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
base=read(V/'baseline.json')['files']
changed=[p for p,h in base.items() if not (R/p).exists() or sha(R/p)!=h]
added=[p.relative_to(R).as_posix() for f in ['project','tools'] for p in (R/f).rglob('*') if p.is_file() and '.godot' not in p.parts and p.suffix not in ['.pyc','.import'] and p.relative_to(R).as_posix() not in base]
protected=[]
for p in changed:
 name=Path(p).name
 if name.startswith(('battle_','combat_','signature_')) or name in ['dungeon_rules_r21.gd','dungeon_enemy_r21.gd','dungeon_world_r21.gd','dungeon_view_r21.gd'] or name.endswith('-r21.json') or p.startswith(('project/assets/enemies-r21/','project/assets/portraits-r21/','project/assets/portraits-r21-web/','project/assets/portraits-r10/','project/assets/src/')):protected.append(p)
hashes=read(R/'ASSET-HASHES.json');asset_changes=[x['path'] for x in hashes if sha(R/x['path'])!=x['sha256']]
backgrounds=list((R/'project/assets/ui-r21').glob('bg-*.webp'));total=sum(p.stat().st_size for p in backgrounds)
assert not protected and not asset_changes,(protected,asset_changes)
assert total<=10000000,total
results=read(R/'verification/town-r21/common-results.json')
failed=[x['name'] for x in results if x['exit_code'] or x['errors']]
report={'checks_groups':len(results),'failed_groups':failed,'original_assets':len(hashes),'original_asset_changes':asset_changes,'protected_changes':protected,'changed':changed,'added':added,'backgrounds':len(backgrounds),'background_bytes':total,'fixed_title_svgs':len(list((R/'project/assets/ui-r21').glob('title-*.svg')))}
(V/'audit.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
assert not failed,failed
print(json.dumps({k:v for k,v in report.items() if k not in ['changed','added']},ensure_ascii=False))
