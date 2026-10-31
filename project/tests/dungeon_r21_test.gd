extends SceneTree
const World=preload("res://game/dungeon_world_r21.gd")
const Battle=preload("res://game/battle_v3.gd")
const Legacy=preload("res://game/expansion_world.gd")
var checks=0
var failures=[]
var outcomes={"victory":0,"defeat":0,"natural_victory":0,"natural_defeat":0}
func check(ok: bool,msg: String):
	checks+=1
	if not ok:
		failures.append(msg)
		if failures.size()<=20: push_error(msg)
func _init(): call_deferred("run")
func same_state(a,b) -> bool:
	# JSON has one number type; GDScript has int/float and String/StringName keys.
	# Compare numeric values exactly, rather than Variant storage types.
	if a is Dictionary:
		if not b is Dictionary or a.size()!=b.size(): return false
		for key in a:
			if not b.has(key) or not same_state(a[key],b[key]): return false
		return true
	if a is Array:
		if not b is Array or a.size()!=b.size(): return false
		for i in range(a.size()):
			if not same_state(a[i],b[i]): return false
		return true
	if a is int or a is float: return (b is int or b is float) and float(a)==float(b)
	if a is String or a is StringName: return str(a)==str(b)
	return a==b
func auto(b,limit=1500):
	var turns=0
	while b.result.is_empty() and turns<limit:
		if b.player_turn() and not b.ally(b.current_id).charging:
			b.choose_enemy(b.living(false)[0].id); b.act("attack")
		else: b.automatic_turn()
		turns+=1
	return turns
func run():
	var w=World.new()
	check(w.dungeon_max()==1 and not w.depart_dungeon(2),"fresh floor lock")
	var old=Legacy.new(); old.depart(); old.travel("patrol")
	var old_battle=Battle.new(old.battle_data()); old.record_battle(old_battle.snapshot())
	check(w.restore(JSON.parse_string(JSON.stringify(old.s))) and not w.r21(),"schema2 legacy active fight migration preserves old data")
	check(Battle.new(w.battle_data()).restore(w.s.run.battle),"legacy battle resumes")
	w=World.new(); w.s.dungeon_r21.best=419
	var legacy1=load("res://game/world_state.gd").new()
	legacy1.config.items=legacy1.config.items.filter(func(i):return i.id in ["hp_s","mp_s","bandage"])
	check(World.new().restore(legacy1.s),"schema1 migration")
	for f in range(1,421):
		for result in ["victory","defeat"]:
			w=World.new(); w.s.dungeon_r21.best=419
			check(w.depart_dungeon(f,7919*f+13),"entry %d"%f)
			w.s.run.phase="battle"; w.s.run.kind="boss"; w.s.run.final=true
			var d=w.battle_data()
			# Controlled damage establishes both terminal paths on every source floor.
			if result=="victory":
				for a in d.allies: a.base[a.line]=1e12
			else:
				for e in d.enemies: e.attack=1e9
				for a in d.allies: a.hp=1; a.base[a.line]=.00001
			var b=Battle.new(d); auto(b)
			check(b.result==result,"terminal %d/%s"%[f,result]); outcomes[result]+=1
			if result=="victory":
				# Snapshots carry roster/phase, not the controlled attack fixture.
				w.record_battle(b.snapshot()); check(w.finish_battle(),"settle %d"%f)
				check(w.s.dungeon_r21.best>=f,"progress %d"%f)
		if f%30==0: print("DUNGEON_R21 floors tested "+str(f))
	for f in range(1,61):
		w=World.new(); w.s.dungeon_r21.best=419
		for id in w.s.party:
			w.s.members[id].level=clampi(int(round(f*1.5)),1,40)
		w.depart_dungeon(f,313*f+17)
		var steps=0
		while w.active() and steps<20:
			if w.s.run.phase=="explore": w.advance()
			elif w.s.run.phase=="rest": w.final_battle()
			elif w.s.run.phase=="battle":
				var b=Battle.new(w.battle_data()); auto(b)
				check(not b.result.is_empty(),"natural battle terminates %d"%f)
				outcomes["natural_"+b.result]=outcomes.get("natural_"+b.result,0)+1
				w.record_battle(b.snapshot()); check(w.finish_battle(),"natural completion %d"%f)
			steps+=1
		check(not w.active(),"whole floor terminates %d"%f)
	for r in w.dungeon_rules.config.rifts:
		for star in range(int(r.star_min),int(r.star_max)+1):
			w=World.new(); check(w.depart_dungeon(1,117,r.id,star),"rift entry "+r.id)
			w.s.run.phase="battle"; w.s.run.final=true; w.s.run.kind="boss"
			var b=Battle.new(w.battle_data()); auto(b)
			check(not b.result.is_empty(),"rift terminates "+r.id)
	for spec in [["낮음","구조"],["중간","회수"],["높음","토벌"],["엘리트","토벌"]]:
		w=World.new()
		var q={"id":"source_q_test","rift":"남서 설산 균열","kind":spec[1],"stars":1 if spec[0]=="낮음" else 2,"lv":10,"gold":100,"reward_v":2,"difficulty":spec[0],"cmp":1,"strength":1.7}
		check(w.depart_rift_quest(q,117),"source quest API "+spec[0])
		var expected_kind=w.dungeon_rules.quest_fight(q)
		var plan=w.encounter_plan()
		check(plan.enc.kind==("rift_core" if expected_kind=="core" else expected_kind) and plan.el==10,"source quest kind and level")
		var qb=Battle.new(w.battle_data()); w.record_battle(qb.snapshot())
		var qr=World.new(); check(qr.restore(JSON.parse_string(JSON.stringify(w.s))),"source quest + power JSON roundtrip")
		var data=w.battle_data()
		for a in data.allies: a.base[a.line]=1e12
		qb=Battle.new(data); auto(qb); check(qb.result=="victory","source quest controlled win")
		var expected_gold=w.dungeon_rules.quest_gold(q,10)
		w.record_battle(qb.snapshot()); check(w.finish_battle() and w.s.summary.gold==expected_gold,"source quest exact gold settlement "+spec[0])
	w=World.new(); w.depart_dungeon(1,117); w.s.run.phase="battle"; w.s.run.kind="elite"
	var b=Battle.new(w.battle_data()); w.record_battle(b.snapshot())
	var restored=World.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(w.s))),"new active run JSON roundtrip")
	var copy=Battle.new(restored.battle_data()); check(copy.restore(restored.s.run.battle),"new battle JSON roundtrip")
	auto(b); auto(copy)
	check(same_state(b.snapshot(),copy.snapshot()),"resume is deterministic, JSON number types normalized")
	var bad=w.s.duplicate(true); bad.run.floor=-1; check(not restored.restore(bad),"invalid floor rejected")
	bad=w.s.duplicate(true); bad.run.battle.r21_roster[0].foe_id="fake"; check(not restored.restore(bad),"invalid roster rejected")
	# A source phase transition and summoned minions survive a mid-combat reload.
	w=World.new(); w.s.dungeon_r21.best=27; w.depart_dungeon(3,117); w.s.run.phase="battle"; w.s.run.final=true; w.s.run.kind="boss"
	b=Battle.new(w.battle_data()); b.data.enemies[0].hp=1; b.dungeon_enemy_r21.phase_check()
	check(b.data.enemies[0].phase==2 and b.living(false).size()==3,"source phase2 entry summons two minions")
	w.record_battle(b.snapshot()); restored=World.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(w.s))),"phase2 + summons world restore")
	copy=Battle.new(restored.battle_data()); check(copy.restore(restored.s.run.battle),"phase2 + summons battle restore")
	check(copy.data.enemies[0].acts==b.data.enemies[0].acts and copy.living(false).size()==3,"phase2 acts and live summon roster preserved")
	bad=w.s.duplicate(true); bad.dungeon_r21={}; check(not restored.restore(bad),"broken progress metadata rejected")
	var fallback=0
	for id in w.dungeon_rules.foes:
		if w.art_for(id).fallback: fallback+=1
		var f=w.dungeon_rules.foes[id]
		if f.role in ["지원","소환"] and w.art_for(id).fallback: check(w.art_for(id).path.ends_with("lantern-v2.png"),"support/summon role fallback "+id)
		if f.role in ["사격","주술"] and w.art_for(id).fallback: check(w.art_for(id).path.ends_with("orb-v2.png"),"ranged/caster role fallback "+id)
	var report={"checks":checks,"failures":failures.size(),"details":failures,"floors":420,"outcomes":outcomes,"art_fallbacks":fallback,"enemies":100}
	FileAccess.open("res://../verification/data-r21/integration.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("DUNGEON_R21 "+JSON.stringify(report)); quit(0 if failures.is_empty() else 1)
