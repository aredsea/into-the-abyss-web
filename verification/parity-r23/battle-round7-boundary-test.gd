extends "res://tests/battle_r23_round7_test.gd"
func run():
	var manifest=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/battle-round7-boundary-oracle.json'))
	for part in manifest.parts:
		var source=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/'+part.file))
		for index in range(source.rows.size()):
			var row=source.rows[index];var c=row.input;c.op=row.op;var b=setup_seven(c);var value=false
			if c.has('forced_roll'):
				b.dungeon_enemy_r21=CountingRandom.new(b);b.dungeon_enemy_r21.forced=c.forced_roll
			if row.op=='phase':value=b.dungeon_enemy_r21.phase_check()
			else:b.dungeon_enemy_r21.dispatch(b.data.enemies[0],c.action)
			var got=project_seven(b,c,value)
			check(same(got,row.expected),'round7/boundary/%s/%d'%[row.op,index],got,row.expected)
	var f=FileAccess.open('res://../verification/parity-r23/battle-round7-boundary-latest.json',FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows}));f.close()
	print('R23 ROUND7 BOUNDARY ',checks,' checks / failures ',failures.size());quit(0 if failures.is_empty() else 1)
