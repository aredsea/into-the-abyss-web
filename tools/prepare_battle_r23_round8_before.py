"""Replay final adapters/inputs against the preserved pre-edit battle modules."""
from pathlib import Path
import hashlib,json
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23';D=O/'battle-round8-before'
for p in list(D.glob('*.gd')):
 if not p.name.startswith('battle-'):p.rename(D/('battle-round8-before-'+p.name))
for name in ['battle_v3','personal_rules_r22','dungeon_enemy_r21']:
 p=D/('battle-round8-before-'+name+'.gd');s=p.read_text(encoding='utf-8')
 for dep in ['personal_rules_r22','dungeon_enemy_r21']:
  s=s.replace('res://game/'+dep+'.gd','res://../verification/parity-r23/battle-round8-before/battle-round8-before-'+dep+'.gd')
 (O/('battle-round8-before-runtime-'+name+'.gd')).write_text(s,encoding='utf-8')
# The two dependent preloads must point at the rewritten runtime copies.
p=O/'battle-round8-before-runtime-battle_v3.gd';s=p.read_text(encoding='utf-8')
for dep in ['personal_rules_r22','dungeon_enemy_r21']:s=s.replace('battle-round8-before/battle-round8-before-'+dep+'.gd','battle-round8-before-runtime-'+dep+'.gd')
p.write_text(s,encoding='utf-8')
(O/'battle-round8-before-fixture.gd').write_text('''extends "res://../verification/parity-r23/battle-round8-before-runtime-battle_v3.gd"
var freeze_finish=false
var forced_evade: Variant=null
func _finish_turn(scale: float=1) -> void:
 if not freeze_finish:super(scale)
func _enemy_evade(e: Dictionary,a: Dictionary) -> bool:
 return forced_evade if forced_evade!=null else super(e,a)
''',encoding='utf-8')
seven=(R/'project/tests/battle_r23_round7_test.gd').read_text(encoding='utf-8')
setup='func setup_seven(c: Dictionary):'+seven.split('func setup_seven(c: Dictionary):',1)[1].split('func project_seven(',1)[0]
setup=setup.replace('SevenFixture.new','BeforeFixture.new')
script='extends "res://tests/battle_r23_round8_test.gd"\nconst BeforeFixture=preload("res://../verification/parity-r23/battle-round8-before-fixture.gd")\n'+setup
(O/'battle-round8-before-test.gd').write_text(script,encoding='utf-8')
old=O/'battle-round8-prior.json'
if not old.exists():old.write_bytes((O/'battle.json').read_bytes())
print(json.dumps({'saved_modules':len(list(D.glob('*.gd'))),'adapter_sha256':hashlib.sha256(script.encode()).hexdigest()}))
