extends SceneTree
const World=preload("res://game/dungeon_world_r21.gd")
const Battle=preload("res://game/battle_v3.gd")
var checks=0
var failures=[]
var evidence={}
func check(ok: bool,label: String):
	checks+=1
	if not ok: failures.append(label)
func same(a,b) -> bool:
	if a is Dictionary:
		if not b is Dictionary or a.size()!=b.size(): return false
		for key in a:
			if not b.has(key) or not same(a[key],b[key]): return false
		return true
	if a is Array:
		if not b is Array or a.size()!=b.size(): return false
		for i in range(a.size()):
			if not same(a[i],b[i]): return false
		return true
	return a==b
func fixture():
	var w=World.new(); w.depart_dungeon(1,12345); w.s.run.phase="battle"
	var d=w.battle_data()
	var plan=d.encounter_r21.duplicate(true)
	plan.enc.merge({"fl":["apprentice_doll","apprentice_doll"],"fg":["",""],"ne":2,"star":1,"raid":false,"dk":0,"dc":0},true)
	plan.el=1; plan.star=1
	d.encounter_r21=plan; d.enemies=w.make_enemies(plan,d.allies)
	for i in range(d.allies.size()):
		var a=d.allies[i]; a.id="neutral_%d"%i; a.class_id="warrior"; a.line="str"
		a.race=""; a.nation=""; a.lineage=""; a.gear_fx={}; a.gear_special=[]; a.passive={}; a.trait={"p":{}}
		a.hp=1000; a.mhp=1000; a.mp=10; a.mmp=100
	return Battle.new(d)
func slots(b,ids: Array) -> Array:
	var all=b.data.allies+b.data.enemies
	return ids.map(func(id):return all.find(b.unit(id))+1)
func _init(): call_deferred("run")
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/data-r21/p2-oracle.json"))
	var rows=[]
	for row in oracle.clock:
		var b=fixture(); var all=b.data.allies+b.data.enemies
		b.current_id=all[0].id
		b.set("ctb_tick",0); b.set("ctb_round",0)
		for i in range(all.size()):
			all[i].remaining=row.input.g[i]; all[i].hp=1000 if row.input.alive[i] else 0
			all[i].effects={}
			if i<4: all[i].base.spd=row.input.sp[i]
			else: all[i].speed=row.input.sp[i]
		b.refresh_forecast()
		check(slots(b,b.data.queue)==row.preview.map(func(v):return int(v)),"CTB preview "+str(rows.size()))
		b._finish_turn(float(row.input.cost)/10000)
		var g=all.map(func(u):return u.remaining)
		var match_g=true
		for i in range(all.size()): match_g=match_g and is_equal_approx(float(g[i]),float(row.g[i]))
		check(match_g,"CTB additive gauge and overshoot "+str(rows.size()))
		check(all.find(b.unit(b.current_id))+1==int(row.cur),"CTB ceil tie slot "+str(rows.size()))
		check(b.get("ctb_tick")==row.tk and b.get("ctb_round")==row.rd,"CTB elapsed round "+str(rows.size()))
		check(slots(b,b.data.queue)==row.next_preview.map(func(v):return int(v)),"CTB next preview "+str(rows.size()))
		rows.append({"g":g,"cur":b.current_id,"tick":b.get("ctb_tick"),"round":b.get("ctb_round"),"preview":slots(b,b.data.queue)})
	evidence.clock=rows
	rows=[]
	for row in oracle.round:
		var b=fixture(); var owner=int(row.input.owner)-1; var kind=row.input.kind
		for i in range(4):
			var a=b.data.allies[i]; a.hp=400+i*100; a.mp=99 if i==1 else 10; a.base.int=51; a.base.str=51; a.base.spd=100
			a.remaining=100000; a.line="int" if i<2 else "str"
			if kind=="halfelf":
				a.race="하프엘프" if i<3 else ""; b._effect(a,"attack_down",3,.2); b._effect(a,"defense_down",3,.2)
		var a=b.data.allies[owner]
		if kind in ["urda","tove","sorel","miko"]: b.extra_state[kind]=b.x(a); a.id=kind
		if kind=="urda": b._effect(b.data.allies[0],"attack_down",3,.2); b._effect(b.data.allies[0],"defense_down",3,.2)
		if kind=="tove": a.shield=250
		if kind=="sorel":
			for member in b.data.allies: b._effect(member,"sorel_regen",2,31)
		if kind=="dead":
			b.data.allies[1].hp=0; a.hp=0; b.extra_state.urda=b.x(a); a.id="urda"
		# Production boundary dispatch, without beginning an actor turn.
		for k in range(int(row.input.ticks)):
			if b.has_method("_round_tick"): b.call("_round_tick")
		var units=[]
		for i in range(4):
			var u=b.data.allies[i]; var want=row.units[i]
			var got={"hp":u.hp,"mp":u.mp,"sh":u.shield,"g":u.remaining,"adn":u.effects.has("attack_down"),"ddn":u.effects.has("defense_down"),"regen":u.effects.get("sorel_regen",{}).get("turns",0)}
			check(same(got,want),"round "+str(row.input)+" unit "+str(i))
			units.append(got)
		rows.append({"input":row.input,"units":units})
	evidence.round=rows
	rows=[]
	for row in oracle.hit:
		var b=fixture(); var a=b.data.allies[0]; var e=b.data.enemies[0]; var input=row.input
		b.data.seed=int(input.seed); b.turn_count=int(input.n); b.dungeon_enemy_r21.begin_random(b.turn_count)
		a.base.str=43.25; a.base.agi=17; a.base.crit=13; a.element="fire"
		e.hp=1000; e.mhp=1000; e.defense=27.3; e.level=1; e.rules={}; e.weak=["fire"] if input.snipe else ["ice"]
		e.broken=input.broken; e.effects.shield={"amount":21,"turns":3}
		b._effect(a,"attack_up",3,input.up); b._effect(a,"attack_down",3,input.dn)
		b._effect(e,"defense_up",3,input.df); b._effect(e,"defense_down",3,.1)
		if input.mark: b._effect(e,"mark",3,1)
		if input.fox: b._effect(e,"foxflame",2,.6)
		if input.guard: b._effect(e,"guard",2,.4)
		b.action_id="snipe" if input.snipe else "attack"
		b._damage(a,e,input.power,0)
		var got={"hp":e.hp,"shield":b.fx(e,"shield"),"crit":b.critical_this_action,"rng":b.x(e).source_rng}
		check(got.hp==row.hp and got.shield==row.shield and got.crit==row.crit,"ally hit "+str(rows.size()))
		check(got.rng==row.rng,"ally forced/random crit consumption "+str(rows.size()))
		rows.append(got)
	evidence.hit=rows
	for row in oracle.ending:
		var b=fixture(); b.turn_count=int(row.n)
		for a in b.data.allies: a.hp=1000 if row.alive_a else 0
		for e in b.data.enemies: e.hp=1000 if row.alive_e else 0
		if b.has_method("_check_end"): b.call("_check_end")
		var want={"win":"victory","lose":"defeat","":""}[row.result]
		check(b.result==want,"ending "+str(row))
	for row in oracle.raid:
		var b=fixture(); var e=b.data.enemies[0]
		b.dungeon_enemy_r21.configure(e,row.id,int(row.phase),0); e.act_index=int(row.ia)-1; e.charged=row.charged
		var got={"turns":0,"name":""}
		if b.dungeon_enemy_r21.has_method("raid_charge_info"): got=b.dungeon_enemy_r21.call("raid_charge_info",e)
		check(got.turns==row.turns and got.name==row.name,"raid charge "+str(row))
	for row in oracle.enrage:
		var b=fixture(); var e=b.data.enemies[0]
		b.dungeon_enemy_r21.configure(e,row.id,int(row.phase),0); e.hp=e.mhp
		b.data.encounter_r21.enc.raid=true; b.ctb_round=int(row.round)
		check(is_equal_approx(b.dungeon_enemy_r21.attack_mult(e),row.mult),"raid enrage by clock "+str(row))
	# Signed overshoot and elapsed rounds survive JSON; old schema-3 saves stay readable.
	var capped=fixture(); capped.turn_count=399; capped._finish_turn()
	check(capped.turn_count==400 and capped.result=="defeat" and not capped.living(true).is_empty(),"action 400 ends a still-living party")
	check(fixture().restore(JSON.parse_string(JSON.stringify(capped.snapshot()))),"action-cap defeat restores with survivors")
	var summoner=fixture(); var caster=summoner.data.enemies[0]
	var plan=summoner.data.encounter_r21.enc
	plan.fl=["raging_lecturer"]; plan.fg=["",""]; plan.ne=2
	summoner.dungeon_enemy_r21.configure(caster,"raging_lecturer",1,0)
	summoner.data.enemies[1].hp=0
	summoner.dungeon_enemy_r21.summon(caster,{"enemy":"apprentice_doll","name":"summon","count":1})
	var summon_save=JSON.parse_string(JSON.stringify(summoner.snapshot()))
	check(summon_save.r21_roster[1].summon_grade=="minion","new summon persists source minion grade")
	var old_summon=summon_save.duplicate(true); old_summon.r21_roster[1].erase("summon_grade")
	# Reconstruct the exact old mob statistics, including an HP value exceeding
	# the corrected minion maximum. Restoring must preserve it without clamping.
	summoner.dungeon_enemy_r21.configure(summoner.data.enemies[1],"apprentice_doll",1,1,"mob")
	old_summon.units[summoner.data.enemies[1].id].hp=summoner.data.enemies[1].mhp
	var old_hp=old_summon.units[summoner.data.enemies[1].id].hp
	check(summoner.restore(old_summon) and summoner.data.enemies[1].hp==old_hp,"old mob-stat summon restored without HP loss")
	check(summoner.snapshot().r21_roster[1].summon_grade=="mob","old summon grade persists across subsequent saves")
	evidence.resume=[]
	for bn in range(1,7):
		var b=fixture(); b.data.seed=bn*7919
		for step in range(7):
			if b.result.is_empty():
				if not b.automatic_turn(): b.act("attack")
		var value=JSON.parse_string(JSON.stringify(b.snapshot())); var loaded=fixture(); loaded.data.seed=bn*7919
		check(loaded.restore(value),"signed CTB restore "+str(bn))
		for step in range(5):
			if b.result.is_empty():
				if not b.automatic_turn(): b.act("attack")
			if loaded.result.is_empty():
				if not loaded.automatic_turn(): loaded.act("attack")
		check(same(b.snapshot(),loaded.snapshot()),"source RNG resume "+str(bn))
		if not same(b.snapshot(),loaded.snapshot()): evidence.resume.append({"before":b.snapshot(),"after":loaded.snapshot()})
		var old=value.duplicate(true); old.erase("ctb")
		var migrated=fixture(); check(migrated.restore(old),"old schema3 accepts unrecorded clock "+str(bn))
		check(migrated.snapshot().units==old.units and migrated.extra_state==old.extra_state,"old schema3 preserves gauges effects HP MP RNG "+str(bn))
		for clock in [{"tick":-1,"round":0},{"tick":100,"round":0},{"tick":1.5,"round":0},{"tick":"1","round":0}]:
			var bad=value.duplicate(true); bad.ctb=clock; var before=JSON.stringify(loaded.snapshot())
			check(not loaded.restore(bad) and JSON.stringify(loaded.snapshot())==before,"invalid clock atomically rejected "+str(clock))
	var report={"checks":checks,"failures":failures,"evidence":evidence}
	var f=FileAccess.open("res://../verification/data-r21/p2-latest.json",FileAccess.WRITE); f.store_string(JSON.stringify(report,"\t")); f.close()
	print("P2 ",checks," checks / failures ",failures.size())
	for failure in failures: print("FAIL ",failure)
	quit(0 if failures.is_empty() else 1)
