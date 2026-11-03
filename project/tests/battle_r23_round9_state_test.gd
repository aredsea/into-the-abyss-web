extends "res://tests/battle_r23_round9_core_test.gd"
func run():
	var manifest=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/battle-round9-state-oracle.json'))
	var api=preload('res://game/battle_source_state_r23.gd').new()
	for part in manifest.parts:
		var source=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/'+part.file))
		for i in range(source.rows.size()):
			var row=source.rows[i];var c=row.input;var got
			if row.op=='persona_ratio':got=api.Stats.persona_ratio(c.base,c.value)
			else:api.bind(c.state);got={"unit":api.blank_unit(c.state,int(c.slot)),"state":c.state}
			check(same(got,row.expected),'round9/%s/%d'%[row.op,i],got,row.expected)
	var f=FileAccess.open('res://../verification/parity-r23/battle-round9-state-latest.json',FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows}));f.close()
	print('R23 ROUND9 STATE ',checks,' checks / failures ',failures.size());quit(0 if failures.is_empty() else 1)
