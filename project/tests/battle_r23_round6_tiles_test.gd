extends "res://tests/battle_r23_round6_test.gd"
func run():
	var source=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/battle-round6-tiles-oracle.json"))
	var api=load('res://game/combat_tiles_r23.gd').new();var b=fixture()
	for index in range(source.rows.size()):
		var row=source.rows[index];var c=row.input
		api.definitions=c.defs;api.skills=c.skills;api.lang=c.lang
		var got
		match row.op:
			'enemy_tile':got=api.enemy_tile(c.state,int(c.slot),c.L,c.K,c.visible)
			'boss_tile':got=api.enemy_tile(c.state,int(c.slot),c.L,c.K,c.visible,true)
			'ally_tile':got=api.ally_tile(c.state,int(c.slot),c.L,c.K,c.item_ok)
			'raid_field':got=api.raid_field(c.state,c.L,c.K,c.visible,c.target)
		var integrated=c.duplicate(true);integrated.kind={'enemy_tile':'enemy','boss_tile':'boss','ally_tile':'ally','raid_field':'raid'}[row.op]
		check(same(b.combat_display_tile(integrated),row.expected),'round6/integrated/%d'%index)
		check(same(got,row.expected),'round6/%s/%d'%[row.op,index],got,row.expected)
	var f=FileAccess.open('res://../verification/parity-r23/battle-round6-tiles-latest.json',FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows},'\t'));f.close()
	print('R23 ROUND6 TILES ',checks,' checks / failures ',failures.size());quit(0 if failures.is_empty() else 1)
