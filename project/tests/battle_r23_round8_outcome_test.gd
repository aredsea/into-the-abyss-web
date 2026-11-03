extends "res://tests/battle_r23_round7_test.gd"
func run():
	var api=preload('res://game/combat_outcome_r23.gd').new()
	var manifest=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/battle-round8-outcome-oracle.json'))
	for part in manifest.parts:
		var source=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/'+part.file))
		for i in range(source.rows.size()):
			var row=source.rows[i];var c=row.input;var st=c.state.duplicate(true);api.lang=c.get('lang','ko');api.definitions=c.defs
			var value=false
			match row.op:
				'experience':value=api.experience(st)
				'finish':api.finish(st,c.result)
				'check_end':value=api.check_end(st)
			check(same({"state":st,"value":value},row.expected),'round8/%s/%d'%[row.op,i],{"state":st,"value":value},row.expected)
	var world=preload('res://game/dungeon_world_r21.gd').new();world.depart_dungeon(1,12345);world.s.run.phase='battle'
	var data=world.battle_data();var b=preload('res://game/battle_v3.gd').new(data);var clone=preload('res://game/battle_v3.gd').new(data)
	var actor=b.data.allies[0];actor.shield=20;actor.effects.shield={"amount":0,"turns":1};b.dungeon_enemy_r21.end_effects(actor)
	check(not actor.effects.has('shield') and clone.restore(b.snapshot()),'round8/shield_expiry_save',actor.effects,actor.effects)
	var f=FileAccess.open('res://../verification/parity-r23/battle-round8-outcome-latest.json',FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows}));f.close()
	print('R23 ROUND8 OUTCOME ',checks,' checks / failures ',failures.size());quit(0 if failures.is_empty() else 1)
