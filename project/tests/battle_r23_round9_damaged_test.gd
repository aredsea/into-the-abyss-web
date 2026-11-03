extends "res://tests/battle_r23_round9_core_test.gd"
func run():
	var manifest=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/battle-round9-damaged-oracle.json'))
	for part in manifest.parts:
		var source=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/'+part.file))
		for i in range(source.rows.size()):
			var row=source.rows[i];var c=row.input;c.op=row.op;var prepared=c.duplicate(true)
			# Lua slots are identities. Give equal character IDs distinct native UIDs.
			for j in range(4):prepared.defs[j].cid='slot_'+str(j+1)
			var b=setup_nine(prepared);var a=b.data.allies[0]
			for j in range(4):b.data.allies[j].character_id=c.defs[j].cid
			b.x(a).rescue=c.state.u[0].x.emg;b.x(a).erase('emg')
			var got='API unavailable'
			if b.PersonalRules.new().has_method('damaged_dispatch'):
				b.PersonalRules.damaged_dispatch(b,b.data.allies[1],10,b.data.enemies[0],c.at)
				got=project_nine(b,c)
				got.units[0].x.emg=b.x(a).get('rescue',0);got.units[0].x.erase('rescue')
			check(same(got,row.expected),'round9/damaged/%d'%i,got,row.expected)
	var suffix=OS.get_environment('R23_ROUND9_OUTPUT');if suffix.is_empty():suffix='latest'
	var f=FileAccess.open('res://../verification/parity-r23/battle-round9-damaged-'+suffix+'.json',FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows}));f.close()
	print('R23 ROUND9 DAMAGED ',checks,' checks / failures ',failures.size());quit(0 if failures.is_empty() else 1)
