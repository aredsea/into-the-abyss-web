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
	a.effects.duty={"amount":.5,"turns":3}; a.effects.guard={"amount":.4,"turns":3}; a.shield=20
	b.dungeon_enemy_r21.add_dot(a,e,40,3); b.dungeon_enemy_r21.add_dot(a,e,60,3)
	var rng=b.rng_state; b._tick(a)
	check(a.hp==970 and a.shield==0,"1 DOT uses take/duty before shield; fixed bypasses defensive stance")
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
	check(oracle.dots.size()==6 and oracle.evades.size()==120,"review oracle contains all hook and RNG samples")
	for row in oracle.dots:
		b=fixture(); a=b.data.allies[0]; e=b.data.enemies[0]
		match row.kind:
			"duty": a.effects.duty={"amount":.5,"turns":3}; a.effects.guard={"amount":.4,"turns":3}; a.shield=20
			"wall_scar": a.hp=50; a.gear_special=[{"key":"wa_last","v":[20,2,30]},{"key":"wa_scar","v":[50,50]}]
			"last_stand": a.hp=250; a.gear_special=[{"key":"last_stand","x":20,"n":2,"p":100}]
			"priest": a.hp=50; b.data.allies[1].class_id="priest"
			"echo_saved", "echo_dead":
				a.hp=50; a.shield=20; b.data.allies[1].gear_special=[{"key":"pa_echo","v":[50]}]
				if row.kind=="echo_saved": a.gear_special=[{"key":"wa_last","v":[20,2,30]}]
		b.dungeon_enemy_r21.add_dot(a,e,40 if row.kind=="duty" else 100,3)
		if row.kind!="last_stand": b.dungeon_enemy_r21.add_dot(a,e,60 if row.kind=="duty" else 100,3)
		b._tick(a)
		check(a.hp==row.hp and a.shield==row.shield and b.x(a).get("scar",0)==row.scar and b.x(a).get("wall_saved",false)==row.saved and b.x(a).get("stood",false)==row.stood,"1 actual Lua fixed strike hooks "+row.kind)
	for row in oracle.evades:
		b=fixture(); a=b.data.allies[0]; e=b.data.enemies[0]; b.data.seed=int(row.seed)
		a.gear_fx={"evade":row.evade}; a.nation="나에린" if row.nation=="naerin" else ""
		e.acts=[{"kind":"dot","name":"dot","m":1,"tick":.3,"turns":3}]; e.act_index=0; e.target_id=a.id; b.current_id=e.id
		b.dungeon_enemy_r21.turn()
		check(a.effects.has("enemy_dot_0")==row.stack and int(b.x(e).source_rng)==int(row.rng) and e.target_id==b.data.allies[int(row.target)-1].id,"2 actual Lua evade/stack/RNG/forecast %d/%d/%s"%[row.seed,row.evade,row.nation])
	var out={"checks":checks,"failures":failures,"evidence":evidence}
	FileAccess.open("res://../verification/data-r21/enemy-review-latest.json",FileAccess.WRITE).store_string(JSON.stringify(out,"\t"))
	print("ENEMY_REVIEW_R21 "+JSON.stringify(out)); quit(0 if failures.is_empty() else 1)
