"""Read the named merge's loose objects directly. No git commands or writes."""
from pathlib import Path
import zlib,json,hashlib
R=Path(__file__).resolve().parents[1]
meta=Path((R/'.git').read_text().strip().split(': ',1)[1])
repo=(meta/(meta/'commondir').read_text().strip()).resolve()
def obj(oid):
 raw=zlib.decompress((repo/'objects'/oid[:2]/oid[2:]).read_bytes())
 return raw.split(b'\0',1)[1]
commits=list((repo/'objects'/'97').glob('3a146*'))
assert len(commits)==1,commits
commit='97'+commits[0].name
tree=obj(commit).splitlines()[0].decode().split()[1]
def lookup(tree,name):
 data=obj(tree); pos=0
 while pos<len(data):
  end=data.index(b'\0',pos); label=data[pos:end].decode().split(' ',1)[1]; oid=data[end+1:end+21].hex(); pos=end+21
  if label==name:return oid
 raise KeyError(name)
def blob(path):
 oid=tree
 for part in path.split('/'):oid=lookup(oid,part)
 return oid,obj(oid).decode('utf-8')
provenance={'commit':commit,'files':{}}
for name in ['battle_v3','trait_rules_r22','personal_rules_r22','dungeon_enemy_r21']:
 path='project/game/'+name+'.gd'; oid,text=blob(path)
 provenance['files'][path]={'blob':oid,'sha256':hashlib.sha256(text.encode()).hexdigest()}
 for module in ['trait_rules_r22','personal_rules_r22','dungeon_enemy_r21']:
  text=text.replace('res://game/'+module+'.gd','res://tests/a7_baseline_'+module+'.gd')
 (R/'project/tests'/('a7_baseline_'+name+'.gd')).write_text(text,encoding='utf-8')
(R/'project/tests/a7_baseline_fixture.gd').write_text('extends "res://tests/a7_baseline_battle_v3.gd"\nvar freeze_finish=false\nfunc _finish_turn(scale: float=1) -> void:\n\tif not freeze_finish: super(scale)\n',encoding='utf-8')
src=(R/'project/tests/combat_a6_r22_test.gd').read_text(encoding='utf-8')
src=src[:src.index('func _init():')]
src=src.replace('res://tests/combat_a6_r22_fixture.gd','res://tests/a7_baseline_fixture.gd')
(R/'project/tests/a7_baseline_helper.gd').write_text(src,encoding='utf-8')
src=(R/'project/tests/combat_a7_r22_test.gd').read_text(encoding='utf-8').replace('res://tests/combat_a6_r22_test.gd','res://tests/a7_baseline_helper.gd').replace('a7-part1-latest.json','a7-part1-pinned-before.json')
begin=src.index('\tvar start_data=')
end=src.index('\ta.class_id=',begin)
src=src[:begin]+src[end:]
src+='\nfunc _init(): call_deferred("run")\n'
(R/'project/tests/combat_a7_baseline.gd').write_text(src,encoding='utf-8')
src=(R/'project/tests/combat_p2_r22_trace_fixture.gd').read_text(encoding='utf-8').replace('res://game/battle_v3.gd','res://tests/a7_baseline_battle_v3.gd')
(R/'project/tests/a7_baseline_trace.gd').write_text(src,encoding='utf-8')
src=(R/'project/tests/combat_p2_r22_trace.gd').read_text(encoding='utf-8')
src=src[:src.index('func run():')].replace('res://tests/combat_p2_r22_trace_fixture.gd','res://tests/a7_baseline_trace.gd')
(R/'project/tests/a7_baseline_audit_helper.gd').write_text(src,encoding='utf-8')
src=(R/'project/tests/combat_a7_gear_audit.gd').read_text(encoding='utf-8').replace('res://tests/combat_p2_r22_trace.gd','res://tests/a7_baseline_audit_helper.gd').replace('a7-gear-audit.json','a7-gear-pinned-before.json')
(R/'project/tests/combat_a7_gear_baseline.gd').write_text(src,encoding='utf-8')
(R/'verification/data-r21/a7-baseline-provenance.json').write_text(json.dumps(provenance,indent=2),encoding='utf-8')
print(commit)
