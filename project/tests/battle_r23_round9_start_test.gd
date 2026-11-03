extends "res://tests/battle_r23_round9_core_test.gd"
const Party=preload('res://game/combat_party_r23.gd')
func run():
	var manifest=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/battle-round9-start-oracle.json'))
	for part in manifest.parts:
		var source=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/'+part.file))
		for i in range(source.rows.size()):
			var row=source.rows[i];var c=row.input;var world=c.world.duplicate(true);var got
			if row.op=='battle_pm':got={"party":Party.battle_pm(world),"world":world}
			else:
				var enc=Party.quest_compose(world,c.quest,c.party);got={"enc":false if enc==null else enc,"world":world}
			check(same(got,row.expected),'round9/%s/%d'%[row.op,i],got,row.expected)
	var f=FileAccess.open('res://../verification/parity-r23/battle-round9-start-latest.json',FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows}));f.close()
	print('R23 ROUND9 START ',checks,' checks / failures ',failures.size());quit(0 if failures.is_empty() else 1)
