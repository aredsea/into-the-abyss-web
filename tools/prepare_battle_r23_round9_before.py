"""Replay the eight preserved product modules with the final boundary inputs.

This is a module-combination replay, not a reconstruction of an entire old build.
Never rewrite the raw snapshots or the canonical oracle files.
"""
from pathlib import Path
import hashlib,json
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23';D=O/'battle-round9-before';P=D/'replay';P.mkdir(exist_ok=True)
names=['battle_v3.gd','combat_events_r22.gd','personal_rules_r22.gd','persona_combat_r22.gd','trait_rules_r22.gd','battle_source_state_r23.gd','battle_stats_r23.gd','dungeon_enemy_r21.gd']
prefix='res://../verification/parity-r23/battle-round9-before/replay/battle-'
hashes={}
for name in names:
    raw=D/('battle-'+name);text=raw.read_text(encoding='utf-8')
    hashes[raw.name]=hashlib.sha256(raw.read_bytes()).hexdigest()
    for target in names:text=text.replace('res://game/'+target,prefix+target)
    (P/('battle-'+name)).write_text(text,encoding='utf-8')
(P/'battle-fixture.gd').write_text('extends "'+prefix+'battle_v3.gd"\nvar freeze_finish=true\nvar forced_evade: Variant=null\nfunc _finish_turn(scale: float=1) -> void:\n\tif not freeze_finish:super(scale)\nfunc _enemy_evade(e: Dictionary,a: Dictionary) -> bool:\n\treturn forced_evade if forced_evade!=null else super(e,a)\n',encoding='utf-8')
seven=(R/'project/tests/battle_r23_round7_test.gd').read_text(encoding='utf-8')
setup=seven.split('func setup_seven(c: Dictionary):',1)[1].split('func project_seven(',1)[0]
setup=setup.replace('SevenFixture.new(seven_data)','load("'+prefix+'fixture.gd").new(seven_data)')
test=(R/'project/tests/battle_r23_round9_core_test.gd').read_text(encoding='utf-8')
test+='\nfunc setup_seven(c: Dictionary):'+setup
(D/'battle-core-test.gd').write_text(test,encoding='utf-8')
(D/'battle-before-sha256.json').write_text(json.dumps({'module_sha256':hashes,'test':hashlib.sha256(test.encode()).hexdigest(),'scope':'Eight original modules, final fixture adapter and identical final core oracle inputs. API-unavailable results are reported separately from observed semantic differences.'},indent=2),encoding='utf-8')
print('prepared',len(names),'unchanged source snapshots')
