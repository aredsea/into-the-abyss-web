extends "res://tests/combat_a6_r22_test.gd"
const StateBattle=preload("res://tests/battle_r23_state_fixture.gd")
const World=preload("res://game/dungeon_world_r21.gd")
func view(b):
	var out=[]
	for u in b.data.allies:
		out.append({"hp":u.hp,"mhp":u.mhp,"mp":u.mp,"mmp":u.mmp,"g":u.remaining,"sp":u.base.spd,"cs":u.base[u.line],"de":u.base.def,"ag":u.get("combat_ag",u.base.agi),"cr":u.base.crit,"row":u.row,"element":u.element,"cls":u.class_id})
	return out
func run():
	var source=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/state-oracle.json"))
	for row in source.rows:
		var w=World.new();w.s.party=row.ids.slice(0,int(row.n));w.s.equipment={}
		for id in w.s.party:w.s.members[id].level=row.level
		w.depart_dungeon(1,12345);w.s.run.phase="battle"
		for i in range(w.s.party.size()):
			var u=w.s.members[w.s.party[i]]
			if row.variant==1:u.hp=1;u.mp=0
			if (row.variant==2 and i==row.n-1) or row.variant==3:u.hp=0;u.mp=0
		var d=w.battle_data();var plan=d.encounter_r21.duplicate(true)
		plan.enc.merge({"fl":["apprentice_doll"],"fg":[""],"ne":1,"raid":false,"star":1,"dk":0,"dc":0},true)
		plan.enc.erase("floor");plan.enc.erase("dn");plan.el=1;plan.star=1;d.encounter_r21=plan;d.enemies=w.make_enemies(plan,d.allies)
		var b=StateBattle.new(d);var got=view(b)
		check(same(got,row.initial),"state initial/%d/%d/%d"%[row.n,row.level,row.variant],got,row.initial)
		b.ctb_tick=0;b._felice_scan();b.ctb_tick=200;b.ctb_round=2;b._felice_scan();got=view(b)
		check(same(got,row.later),"state carry revive/%d/%d/%d"%[row.n,row.level,row.variant],got,row.later)
		var loaded=StateBattle.new(d);var saved=JSON.parse_string(JSON.stringify(b.snapshot()))
		check(loaded.restore(saved) and same(view(loaded),view(b)),"state JSON resume/%d/%d/%d"%[row.n,row.level,row.variant])
		# The new carry sentinel is accepted only for downed allies. Older
		# finite gauges are retained exactly when the same schema-3 save loads.
		if b.data.allies[0].hp>0:
			var invalid=saved.duplicate(true);invalid.units[b.data.allies[0].id].remaining=1000000000
			var before=JSON.stringify(loaded.snapshot())
			check(not loaded.restore(invalid) and JSON.stringify(loaded.snapshot())==before,"living carry sentinel rejected atomically")
		for u in b.data.allies:
			if u.hp>0:continue
			var old=saved.duplicate(true);old.units[u.id].remaining=10000
			check(loaded.restore(old) and loaded.unit(u.id).remaining==10000,"old downed gauge preserved")
			var invalid=saved.duplicate(true);invalid.units[u.id].remaining=1000000001
			var before=JSON.stringify(loaded.snapshot())
			check(not loaded.restore(invalid) and JSON.stringify(loaded.snapshot())==before,"invalid downed sentinel rejected atomically")
	var f=FileAccess.open("res://../verification/parity-r23/state-latest.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows},"\t"));f.close()
	print("R23 STATE ",checks," checks / failures ",failures.size());quit(0 if failures.is_empty() else 1)
