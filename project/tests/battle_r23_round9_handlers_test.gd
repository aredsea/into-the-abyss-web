extends "res://tests/battle_r23_round9_core_test.gd"
const Controls=preload('res://game/combat_controls_r23.gd')
func run():
	var manifest=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/battle-round9-handlers-oracle.json'))
	for part in manifest.parts:
		var source=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/'+part.file))
		for i in range(source.rows.size()):
			var row=source.rows[i];var c=row.input;var state=c.state.duplicate(true);var world=c.world.duplicate(true);var calls=[];var context={"actor":"before","skill":"old"}
			var b=setup_nine(c)
			for j in range(4):b.data.allies[j].level=c.defs[j].get('lv',1)
			var api={
				"have":func(id):return world.items.get(id,0),
				"bag":func():
					var bag={}
					for id in b.CombatItems.ItemData.ORDER:bag[id]=world.items.get(id,0)
					return bag,
				"any":func(id):return b.CombatItems.any_target(b,id),
				"ok":func(id,target):return b.CombatItems.target_ok(b,id,b.data.allies[target-1]),
				"take":func(id):world.items[id]-=1;if world.items[id]<=0:world.items.erase(id),
				"begin":func(s):calls.append(['begin']);s.ev={"fresh":true},
				"rbegin":func(s):calls.append(['rbegin',s.n]),
				"apply":func(s,id,target):calls.append(['apply',id,target,is_same(context.actor,s.u[int(s.cur)-1]),context.skill if context.skill!=null else false]),
				"end_turn":func(_s,cur,cost):calls.append(['end_turn',cur,cost]),
				"run":func(_s):calls.append(['run']),
				"send":func(_s):calls.append(['send']),
				"save":func(_s):calls.append(['save'])}
			Controls.item(state,c.arg,api,context,world.scene)
			var got={"state":state,"world":world,"calls":calls,"actor":'nil' if context.actor==null else context.actor,"skill":'nil' if context.skill==null else context.skill}
			check(same(got,row.expected),'round9/item_handler/%d'%i,got,row.expected)
	var f=FileAccess.open('res://../verification/parity-r23/battle-round9-handlers-latest.json',FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows}));f.close()
	print('R23 ROUND9 HANDLERS ',checks,' checks / failures ',failures.size());quit(0 if failures.is_empty() else 1)
