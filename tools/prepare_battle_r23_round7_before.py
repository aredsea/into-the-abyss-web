"""Use identical final inputs/adapter with the saved pre-edit battle/enemy pair."""
from pathlib import Path
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23'
test=(R/'project/tests/battle_r23_round7_test.gd').read_text(encoding='utf-8')
setup=test.split('func setup_seven(c: Dictionary):',1)[1].split('func project_seven(',1)[0]
setup='func setup_seven(c: Dictionary):'+setup.replace('SevenFixture.new','BeforeFixture.new')
script='''extends "res://tests/battle_r23_round7_test.gd"
const BeforeFixture=preload('res://../verification/parity-r23/battle-round7-before-fixture.gd')
'''+setup+'''
func run():
	var manifest=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/battle-round7-oracle.json'))
	for part in manifest.parts:
		var source=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/'+part.file))
		for index in range(source.rows.size()):
			var row=source.rows[index]
			if not row.op in ['counter','foe_hit_after','summon','phase']:continue
			var c=row.input;c.op=row.op;var b=setup_seven(c)
			b.dungeon_enemy_r21=load('res://../verification/parity-r23/battle-round7-before-dungeon_enemy_r21.gd').new(b)
			var e=b.data.enemies[0];var a=b.data.allies[0];var value=false
			match row.op:
				'counter':b._enemy_hit(e,a,{"kind":"atk","name":"test","m":c.counter.get('m',.6),"counter":true})
				'foe_hit_after':b.dungeon_enemy_r21.after_hit(a,e,c.element)
				'summon':b.dungeon_enemy_r21.summon(e,c.action)
				'phase':value=b.dungeon_enemy_r21.phase_check()
			var got=project_seven(b,c,value)
			check(same(got,row.expected),'round7/before/%s/%d'%[row.op,index],got,row.expected)
	var f=FileAccess.open('res://../verification/parity-r23/battle-round7-before-replay.json',FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows}));f.close()
	print('R23 ROUND7 BEFORE ',checks,' checks / differences ',failures.size());quit(0)
'''
(O/'battle-round7-before-test.gd').write_text(script,encoding='utf-8')
