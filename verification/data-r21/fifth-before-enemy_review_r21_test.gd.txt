extends SceneTree
const World=preload("res://game/dungeon_world_r21.gd")
const Battle=preload("res://tests/enemy_action_fixture_r21.gd")
var checks=0
var failures=[]
var evidence={}
func check(ok: bool,label: String):
	checks+=1
	if not ok: failures.append(label)
func fixture():
	var w=World.new(); w.depart_dungeon(1,12345); w.s.run.phase="battle"
	var d=w.battle_data()
	for i in range(d.allies.size()):
		var a=d.allies[i]; a.id="neutral_%d"%i
		a.class_id="sanctioned"; a.race=""; a.nation=""; a.lineage=""; a.gear_fx={}; a.gear_special=[]; a.passive={}; a.trait={"p":{}}
		a.hp=1000; a.mhp=1000; a.shield=0; a.effects={}
	return Battle.new(d)
func next_rng(rs: int) -> int: return (rs*16807)%2147483647
func _init(): call_deferred("run")
func run():
	var b=fixture(); var a=b.data.allies[0]; var e=b.data.enemies[0]
	b.extra_state.hildegard=b.extra_state[a.id]; a.id="hildegard"
	a.effects.duty={"amount":.25,"turns":3}; a.effects.guard={"amount":.4,"turns":3}; a.shield=20
	b.dungeon_enemy_r21.add_dot(a,e,40,3); b.dungeon_enemy_r21.add_dot(a,e,60,3)
	var rng=b.rng_state; b._tick(a)
	check(a.hp==956 and a.shield==0,"1 DOT uses Hildegard red25 inside take before shield; fixed bypasses defensive stance")
	check(b.rng_state==rng,"1 DOT fixed strike cannot evade or consume attack RNG")
	b=fixture(); a=b.data.allies[0]; e=b.data.enemies[0]; a.hp=50
	a.gear_special=[{"key":"wa_last","v":[20,2,30]},{"key":"wa_scar","v":[50,50]}]
	b.dungeon_enemy_r21.add_dot(a,e,100,3); b.dungeon_enemy_r21.add_dot(a,e,100,3); b._tick(a)
	check(a.hp==200 and b.x(a).get("wall_saved",false),"1 DOT lethal strike invokes last wall once for summed stacks")
	check(b.x(a).get("scar",0)==100,"1 DOT invokes damaged scar hook for summed HP damage")
	b=fixture(); a=b.data.allies[0]; e=b.data.enemies[0]; a.hp=250
	a.gear_special=[{"key":"last_stand","p":100,"x":20,"n":2}]
	b.dungeon_enemy_r21.add_dot(a,e,100,3); b._tick(a)
	check(b.x(a).get("stood",false) and b.fx(a,"gear_guard")==.3,"1 DOT triggers post-damage last stand")
	for evade in [100,0]:
		b=fixture(); a=b.data.allies[0]; e=b.data.enemies[0]
		a.gear_fx={"evade":evade}; e.target_id=a.id
		e.acts=[{"kind":"dot","name":"dot","m":1,"turns":3,"tick":.3}]; e.act_index=0; b.current_id=e.id
		b.dungeon_enemy_r21.begin_random(b.turn_count+1)
		var expected=next_rng(int(b.x(e).source_rng))
		if evade>0: expected=next_rng(expected)
		b.dungeon_enemy_r21.turn()
		check(a.effects.has("enemy_dot_0")==bool(evade==0),"2 pure DOT evade gates stack %d"%evade)
		check(int(b.x(e).source_rng)==expected,"2 source RNG: evade (only positive chance), then next target %d"%evade)
	# Reach a naturally changed target before serializing an actual production roster.
	b=fixture(); e=b.data.enemies[0]; b.current_id=e.id
	var initial=e.target_id
	for n in range(20):
		b.dungeon_enemy_r21.turn()
		if e.target_id!=initial and not b.ally(e.target_id).is_empty(): break
	check(e.target_id!=initial and not b.ally(e.target_id).is_empty(),"3 fixture reaches a changed ally forecast through real enemy turns")
	var saved=JSON.parse_string(JSON.stringify(b.snapshot())); var restored=fixture()
	check(restored.restore(saved),"3 progressed snapshot restores")
	evidence={"initial_target":initial,"saved_target":e.target_id,"loaded_target":restored.data.enemies[0].target_id,"turn_count":b.turn_count}
	check(restored.data.enemies[0].target_id==e.target_id,"3 save/load preserves progressed forecast target")
	check(restored.intent(restored.data.enemies[0])==b.intent(e),"3 save/load preserves intent text")
	var legacy=saved.duplicate(true)
	for v in legacy.r21_roster: v.erase("target_id")
	var old=fixture(); var fallback=old.data.enemies.map(func(u):return u.target_id)
	check(old.restore(legacy),"3 old roster without targets still restores")
	check(old.data.enemies.map(func(u):return u.target_id)==fallback,"3 old roster retains initialized fallback targets")
	b.dungeon_enemy_r21.turn(); restored.dungeon_enemy_r21.turn()
	# Normalize JSON's int-to-float decoding on both sides before exact value comparison.
	check(JSON.parse_string(JSON.stringify(b.snapshot()))==JSON.parse_string(JSON.stringify(restored.snapshot())),"3 resumed enemy action preserves full snapshot including HP, action index, forecasts and RNG")
	for bad_target in [123,"unknown",{}]:
		var bad=saved.duplicate(true); bad.r21_roster[0].target_id=bad_target
		check(not restored.restore(bad),"3 invalid target rejected "+str(bad_target))
	# Source/save targets may intentionally refer to dead allies until action fallback.
	b=fixture(); e=b.data.enemies[0]; a=b.data.allies[0]; e.target_id=a.id; a.hp=0
	saved=JSON.parse_string(JSON.stringify(b.snapshot())); restored=fixture()
	check(restored.restore(saved),"3 dead forecast target snapshot accepted")
	check(restored.data.enemies[0].target_id==a.id,"3 dead forecast ID preserved for normal action fallback")
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/data-r21/enemy-review-oracle.json"))
	check(oracle.dots.size()==7 and oracle.evades.size()==120,"review oracle contains all hook and RNG samples")
	for row in oracle.dots:
		b=fixture(); a=b.data.allies[0]; e=b.data.enemies[0]
		match row.kind:
			"duty":
				b.extra_state.hildegard=b.extra_state[a.id]; a.id="hildegard"; a.effects.duty={"amount":.25,"turns":3}
			"psguard": a.effects.psguard={"amount":.1,"turns":3}; a.effects.guard={"amount":.4,"turns":3}
			"wall_scar": a.hp=50; a.gear_special=[{"key":"wa_last","v":[20,2,30]},{"key":"wa_scar","v":[50,50]}]
			"last_stand": a.hp=250; a.gear_special=[{"key":"last_stand","x":20,"n":2,"p":100}]
			"priest": a.hp=50; b.data.allies[1].class_id="priest"
			"echo_saved", "echo_dead":
				a.hp=50; a.shield=20; b.data.allies[1].gear_special=[{"key":"pa_echo","v":[50]}]
				if row.kind=="echo_saved": a.gear_special=[{"key":"wa_last","v":[20,2,30]}]
		b.dungeon_enemy_r21.add_dot(a,e,10 if row.kind=="duty" else 100,3)
		if row.kind not in ["last_stand","duty","psguard"]: b.dungeon_enemy_r21.add_dot(a,e,60 if row.kind=="duty" else 100,3)
		b._tick(a)
		check(a.hp==row.hp and a.shield==row.shield and b.x(a).get("scar",0)==row.scar and b.x(a).get("wall_saved",false)==row.saved and b.x(a).get("stood",false)==row.stood,"1 actual Lua fixed strike hooks "+row.kind)
	for row in oracle.evades:
		b=fixture(); a=b.data.allies[0]; e=b.data.enemies[0]; b.data.seed=int(row.seed)
		a.gear_fx={"evade":row.evade}; a.nation="나에린" if row.nation=="naerin" else ""
		e.acts=[{"kind":"dot","name":"dot","m":1,"tick":.3,"turns":3}]; e.act_index=0; e.target_id=a.id; b.current_id=e.id
		b.dungeon_enemy_r21.turn()
		check(a.effects.has("enemy_dot_0")==row.stack and int(b.x(e).source_rng)==int(row.rng) and e.target_id==b.data.allies[int(row.target)-1].id,"2 actual Lua evade/stack/RNG/forecast %d/%d/%s"%[row.seed,row.evade,row.nation])
	fourth(oracle.fourth)
	var out={"checks":checks,"failures":failures,"evidence":evidence}
	FileAccess.open("res://../verification/data-r21/enemy-review-latest.json",FileAccess.WRITE).store_string(JSON.stringify(out,"\t"))
	print("ENEMY_REVIEW_R21 "+JSON.stringify(out)); quit(0 if failures.is_empty() else 1)

func rename_ally(b,index: int,id: String):
	var a=b.data.allies[index]; b.extra_state[id]=b.extra_state[a.id]; a.id=id
	return a
func fourth(o: Dictionary):
	var observations={"strikes":[],"seals":[],"saves":[],"saya":[],"zahar":[]}
	for row in o.strikes:
		var b=fixture(); var a=b.data.allies[0]
		if row.cid=="hildegard":
			a=rename_ally(b,0,"hildegard"); a.effects.duty={"amount":.25,"turns":3}
		if row.stance==1: a.effects.guard={"amount":.4,"turns":3}
		b._tactic(b.data.allies[1],b.data.enemies[0],a,{"prefix":{"kind":"shield","power":0},"suffix":{"kind":"guard","value":.1}})
		check(a.effects.has("psguard"),"4.1/2 tactic suffix creates separate psguard")
		a.shield=0
		b._incoming_strike(a,row.raw,{}, {"name":"probe"},false,row.fixed)
		var loss=1000-a.hp
		observations.strikes.append({"input":row,"actual_loss":loss})
		check(loss==row.loss,"4.1/2 canonical take/psguard rounding "+str(row))
	for row in o.seals:
		var b=fixture(); var target=int(row.target)-1
		rename_ally(b,int(row.colette)-1,"colette")
		var a=b.data.allies[target]
		if row.saya: a=rename_ally(b,target,"saya")
		a.gear_fx={"evade":15}; b.data.seed=1
		var e=b.data.enemies[0]
		if row.sealed: e.effects.silence={"amount":1,"turns":2}
		e.acts=[{"kind":"dot","name":"dot","m":1,"tick":.3,"turns":3,"magic":row.magic}]; e.act_index=0; e.target_id=a.id; b.current_id=e.id
		b.dungeon_enemy_r21.turn()
		var actual={"stack":a.effects.has("enemy_dot_0"),"rng":int(b.x(e).source_rng),"next":b.data.allies.find(b.ally(e.target_id))+1}
		observations.seals.append({"input":row,"actual":actual})
		check(actual.stack==row.stack and actual.rng==int(row.rng) and actual.next==row.next,"4.3/6 personal slot order then global roll "+str(row))
	for row in o.saves:
		var b=fixture(); var a=b.data.allies[0]; var e=b.data.enemies[0]; a.hp=50
		b.current_id=a.id if row.kind!="wall_other" else b.data.allies[1].id
		if row.kind.begins_with("wall"):
			a.gear_special=[{"key":"wa_last","v":[20,2,30]}]
		else:
			a.gear_fx={"shield":20}; a.gear_special=[{"key":"guardian","p":100,"x":50}]
			if row.kind=="marceline": a=rename_ally(b,0,"marceline"); b.current_id=a.id
			else:
				b.data.allies[1].class_id="priest"; b.data.allies[1].gear_special=[{"key":"pr_miracle","v":[60,15]}]
		var rng=b.rng_state
		b.dungeon_enemy_r21.add_dot(a,e,100,3); b._tick(a)
		var wall=int(a.effects.get("wall_party",{}).get("turns",0))
		observations.saves.append({"input":row,"hp":a.hp,"shield":a.shield,"wall_after_tick":wall,"rng_unchanged":rng==b.rng_state})
		check(a.hp==row.hp and a.shield==row.shield,"4.4/7 canonical DOT save "+row.kind)
		check(rng==b.rng_state and row.rng_unchanged,"4.7 save uses raw setf shield without guardian RNG "+row.kind)
		if row.wall>0: check(wall==int(row.wall)-1,"4.4 wall duration offsets this start tick "+row.kind)
	var b=fixture(); var a=b.data.allies[0]; var e=b.data.enemies[0]
	rename_ally(b,1,"felice"); a.hp=50; b.current_id=a.id
	b.dungeon_enemy_r21.add_dot(a,e,100,1); b._tick(a)
	check(a.hp==o.revive.hp and a.hp==0 and b.x(a).get("reviving",false),"4.5 DOT death loses current turn before Felice scan")
	# Production CTB must move away from the dead owner, then revive after another action.
	var prod=load("res://game/battle_v3.gd").new(b.data)
	prod.data.allies[0].hp=50; prod.current_id=prod.data.enemies[0].id
	for u in prod.data.allies+prod.data.enemies: u.remaining=10000.0
	prod.data.allies[0].remaining=0.0; prod.data.allies[1].remaining=1.0
	prod.dungeon_enemy_r21.add_dot(prod.data.allies[0],prod.data.enemies[0],100,1)
	var actions_before=prod.data.allies[0].actions; var turns_before=prod.turn_count
	prod._finish_turn()
	check(prod.data.allies[0].actions==actions_before and prod.turn_count==turns_before+1,"4.5 DOT death is not an extra action")
	check(prod.data.allies[0].hp==0 and prod.current_id!=prod.data.allies[0].id,"4.5 production CTB skips DOT death turn")
	var saved=JSON.parse_string(JSON.stringify(prod.snapshot())); var restored=load("res://game/battle_v3.gd").new(prod.data)
	check(restored.restore(saved),"4.5 pending Felice revival snapshot restores")
	prod._finish_turn(); restored._finish_turn()
	check(JSON.parse_string(JSON.stringify(prod.snapshot()))==JSON.parse_string(JSON.stringify(restored.snapshot())),"4.5 pending revival resumes identically")
	check(prod.data.allies[0].hp==o.revive.after_scan_hp,"4.5 next completed action scans Felice revival")
	check(not prod.data.allies[0].effects.has("enemy_dot_0"),"4.5 revival clears dead unit buffs")
	for row in o.revive_scans:
		b=fixture(); a=b.data.allies[0]; e=b.data.enemies[0]; rename_ally(b,1,"felice")
		a.hp=50; b.current_id=a.id; b.dungeon_enemy_r21.add_dot(a,e,100,1); b._tick(a)
		if row.event=="evade": b._enemy_evade(e,b.data.allies[2])
		else:
			b.current_id=b.data.allies[1].id if row.event=="turn_end" else e.id
			# Test the production hook dispatch, independent of subsequent CTB ticks.
			if row.event=="enemy_end": e.acts=[{"kind":"guard","name":"guard","amount":.1,"turns":2}]; e.act_index=0
			var probe=load("res://game/battle_v3.gd").new(b.data)
			probe.extra_state=b.extra_state.duplicate(true); probe.data.allies[0].hp=0; probe.current_id=b.current_id
			for u in probe.data.allies+probe.data.enemies: u.remaining=10000.0
			probe._finish_turn(); a=probe.data.allies[0]
		check(a.hp==row.hp,"4.5 canonical Felice scan event "+row.event)
	b=fixture(); a=b.data.allies[0]; e=b.data.enemies[0]; rename_ally(b,1,"felice")
	a.hp=50; b.current_id=a.id; b.dungeon_enemy_r21.add_dot(a,e,100,1); b._tick(a)
	b.current_id=e.id
	b._enemy_hit(e,b.data.allies[2],{"kind":"atk","name":"scan","m":0})
	check(a.hp==o.revive.after_scan_hp,"4.5 ordinary enemy attack also visits Felice evade scan")
	for row in o.saya:
		b=fixture(); a=rename_ally(b,0,"saya"); e=b.data.enemies[0]; b.data.seed=int(row.seed)
		e.acts=[{"kind":"dot","name":"dot","m":1,"tick":.3,"turns":3,"magic":true}]; e.act_index=0; e.target_id=a.id; b.current_id=e.id
		var before=b.rng_state; b.dungeon_enemy_r21.turn()
		var actual={"rng":int(b.x(e).source_rng),"next":b.data.allies.find(b.ally(e.target_id))+1,"stack":a.effects.has("enemy_dot_0")}
		observations.saya.append({"input":row,"actual":actual})
		check(actual.rng==int(row.rng) and actual.next==row.next and actual.stack==row.stack,"4.6 Saya counter consumes canonical crit RNG seed %d"%row.seed)
		check(b.rng_state==before,"4.6 Saya counter uses source stream only seed %d"%row.seed)
	for row in o.zahar:
		b=fixture(); a=rename_ally(b,0,"zahar"); a.base.def=row.defense; a.effects.zdn={"amount":row.zdn,"turns":2}
		b.data.def_curve={"a":0,"b":0}
		b._incoming_strike(a,100,{}, {"name":"probe"},false,row.fixed)
		observations.zahar.append({"input":row,"loss":1000-a.hp})
		check(1000-a.hp==row.loss,"4.8 Zahar zdn take correction "+str(row))
	evidence.fourth=observations
