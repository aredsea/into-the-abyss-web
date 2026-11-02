extends "res://tests/combat_a6_r22_test.gd"
const W=preload("res://game/town_world_r21.gd")
const Save=preload("res://game/gear_save_r22.gd")
func run():
	var w=W.new(); var rules=Save.new().rules
	w.s.members.hildegard.level=40
	w.s.dungeon_r21.best=419
	var chosen=0
	for candidate in range(1,1000):
		var reward=w.dungeon_rules.ex_roll(candidate,420,1,0,w.party_classes())
		if reward.kind=="equip" and rules.source.items[rules.gear_parse(reward.code).id].cls in w.party_classes(): chosen=candidate; break
	w.depart_dungeon(420,chosen)
	check(w.advance(),"P5 actual exploration transaction")
	check(w.s.run.loot_gear.size()==1,"P5 actual equipment reward generated",w.s.run.loot_gear,null)
	if w.s.run.loot_gear.is_empty(): print(rows); quit(1); return
	var drop={"code":w.s.run.loot_gear[0]}
	check(not rules.gear_parse(drop.code).is_empty(),"source P5 drop code",drop,null)
	# Reward class follows the deployed party, so select the matching owner.
	var cls=rules.source.items[rules.gear_parse(drop.code).id].cls; var owner=""
	for cid in w.s.party:
		if w.class_def(cid).id==cls: owner=cid; break
	w.s.members[owner].level=40
	check(w.settle("retreat"),"P5 settlement")
	var entry=w.s.gear[-1]
	check(entry.get("source_r21",false) and entry.code==drop.code,"P5 keeps exact source code",entry,drop)
	var rolled=rules.gear_roll(drop.code,40,0)
	check(w.equip(owner,int(entry.uid)),"P7 equip source UID")
	w.depart_dungeon(1,12346); w.s.run.phase="battle"
	var d=w.battle_data(); var b=Battle.new(d); var a=b.ally(owner)
	check(not a.gear_fx.is_empty(),"P7 source equipment enters combat",a.gear_fx,null)
	for key in rolled.fx: check(is_equal_approx(a.gear_fx.get(key,0),rolled.fx[key]),"source roll "+key,a.gear_fx.get(key,0),rolled.fx[key])
	var snapshot=JSON.parse_string(JSON.stringify(b.snapshot())); var restored=Battle.new(d)
	check(restored.restore(snapshot),"actual gear battle snapshot JSON round trip")
	w.s.run.battle=snapshot
	var world_loaded=W.new()
	check(world_loaded.restore(JSON.parse_string(JSON.stringify(w.s))),"source code gear and active battle world JSON restore")
	# Save an active wall and per-action gear state, then continue identically.
	b=fixture(); a=b.data.allies[0]; a.hp=1; a.gear_special=[{"key":"wa_last","v":[20,2,30]},{"key":"wa_scar","v":[50,50]}]
	b._incoming_strike(a,10000,{}, {"name":"test"},false,true)
	snapshot=JSON.parse_string(JSON.stringify(b.snapshot())); restored=Battle.new(b.data)
	# The neutral fixture deliberately enlarges enemies; hydration uses source HP.
	for foe in b.data.enemies: snapshot.units[foe.id].hp=1
	check(restored.restore(snapshot),"gear wall and scar JSON restore")
	for model in [b,restored]: model._incoming_strike(model.data.allies[2],100,{}, {"name":"test"},false,true)
	check(b.data.allies[2].hp==restored.data.allies[2].hp and b.data.allies[2].hp==930,"restored wall continues at 30%",restored.data.allies[2].hp,930)
	snapshot.extra_state[b.data.allies[0].id].gear_gw.who=999
	check(not restored.restore(snapshot),"reject invalid gear owner")
	var f=FileAccess.open("res://../verification/data-r21/a7-flow.json",FileAccess.WRITE); f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows},"\t")); f.close()
	print("A7 flow ",checks," / failures ",failures.size()," ",failures); quit(0 if failures.is_empty() else 1)
