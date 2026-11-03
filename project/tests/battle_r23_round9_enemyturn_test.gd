extends "res://tests/battle_r23_round9_core_test.gd"
func run():
	var manifest=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/battle-round9-enemyturn-oracle.json'))
	for part in manifest.parts:
		var source=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/'+part.file))
		for i in range(source.rows.size()):
			var row=source.rows[i];var c=row.input;c.op=row.op;var b=setup_nine(c);var e=b.data.enemies[0]
			b.data.seed=c.state.seed;e.acts=c.defs[4].acts.duplicate(true);e.grade=c.defs[4].grade;b.current_id=e.id
			for j in range(4):
				var w=b.data.allies[j];w.skills={};w.row=c.defs[j].row
				for sk in c.skills[j]:
					var id='personal' if sk.get('pv',false) else {'atk':'attack','df':'defend','guard2':'guard','shield':'pshield' if w.class_id=='paladin' else 'shield','pshield':'hshield','taunt':'ptaunt' if w.class_id=='paladin' else 'taunt','defdn':'acid','wave':'chaoswave'}.get(sk.id,sk.id)
					w.skills[id]={"name":sk.name,"mp":sk.mp,"source_id":sk.id}
			b.dungeon_enemy_r21.source_enemy_turn(e)
			var value={"n":b.turn_count,"tn":b.x(e).get('foe_turns',0),"pt":idx(b,b.unit(b.x(e).get('protect',''))),"hid":1 if b.x(e).get('hidden',false) else 0,"cq":1 if e.charged else 0}
			var got=project_nine(b,c,value);got.units[4].x.erase('foe_turns')
			for j in range(c.state.u.size()):
				var w=(b.data.allies+b.data.enemies)[j]
				for key in got.units[j].bf:
					var effect=w.effects.get(BF7.get(key,key),{})
					if effect.has('source'):got.units[j].bf[key].src=idx(b,b.unit(effect.source))
					if effect.get('turns')==99 and effect.has('source'):got.units[j].bf[key].au=1
				if w.effects.has('silence'):
					var id=b.x(w).silenced_id;got.units[j].sil=w.skills.get(id,{}).get('source_id',id)
			check(same(got,row.expected),'round9/enemy_turn/%d'%i,got,row.expected)
	var f=FileAccess.open('res://../verification/parity-r23/battle-round9-enemyturn-latest.json',FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows}));f.close()
	print('R23 ROUND9 ENEMYTURN ',checks,' checks / failures ',failures.size());quit(0 if failures.is_empty() else 1)
