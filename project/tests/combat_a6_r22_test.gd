extends SceneTree
const Base=preload("res://tests/combat_p2_r22_test.gd")
const Battle=preload("res://tests/combat_a6_r22_fixture.gd")
const Legacy=preload("res://tests/combat_a6_legacy_fixture.gd")
var checks=0
var failures=[]
var rows=[]
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
	if a is float or a is int: return (b is float or b is int) and absf(float(a)-float(b))<.0000001
	return a==b
func check(ok: bool,label: String,got=null,want=null):
	checks+=1
	rows.append({"label":label,"got":got,"want":want,"ok":ok})
	if not ok: failures.append(label)
func fixture():
	var helper=Base.new(); var b0=helper.fixture(); var b=Battle.new(b0.data); helper.free()
	for u in b.data.allies+b.data.enemies:
		u.hp=1000; u.mhp=1000; u.shield=0; u.effects={}; u.remaining=10000
		if u.has("base"): u.mp=0; u.mmp=100; u.base.spd=100; u.base.str=100; u.base.int=100; u.base.agi=0; u.base.crit=0
		else: u.speed=100; u.defense=0; u.weak=[]
	b.ctb_tick=0; b.ctb_round=0
	return b
func _init(): call_deferred("run")
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/data-r21/a6-oracle.json"))
	var b=fixture(); var a=b.data.allies[0]
	b.current_id=b.data.allies[1].id; a.remaining=0; a.hp=1
	b.dungeon_enemy_r21.add_dot(a,b.data.enemies[0],100,3)
	b._finish_turn()
	check(a.mp==oracle.mp[0].mp,"1 actual finish / DOT death MP",a.mp,oracle.mp[0].mp)
	check(a.hp==0 and b.unit(b.current_id).hp>0 and b.turn_count==1,"1 skips DOT corpse without another action")
	for kind in ["rounding","echo","priority","priest","scar","sorel"]:
		var actual=fixture().data.duplicate(true); actual.erase("encounter_r21")
		var old=Legacy.new(actual); var now=Battle.new(actual)
		for model in [old,now]:
			var target=model.data.allies[0]; var attacker=model.data.enemies[0]
			target.hp=50 if kind!="rounding" else 500; target.mhp=1003
			attacker.attack=100; attacker.level=1; target.base.def=0
			if kind=="rounding": target.race="하프엘프"; model._effect(target,"psguard",3,.1)
			if kind=="echo": target.shield=21; model.data.allies[1].gear_special=[{"key":"pa_echo","v":[50]}]
			if kind=="priority": model.extra_state.marceline=model.x(target); target.id="marceline"; target.gear_special=[{"key":"wa_last","v":[20,2,30]}]
			if kind=="priest": target.class_id="priest"
			if kind=="scar": target.gear_special=[{"key":"wa_scar","v":[50,50]}]
			if kind=="sorel":
				var s=model.data.allies[1]; model.extra_state.sorel=model.x(s); s.id="sorel"; s.base.int=100
				target.hp=250; target.gear_special=[{"key":"last_stand","p":100,"x":20,"n":2}]
			model._enemy_hit(attacker,target,{"kind":"atk","name":"test","m":1})
		var lhs=now.data.allies[0]; var rhs=old.data.allies[0]
		var got=[lhs.hp,lhs.shield,now.x(lhs),lhs.effects]; var want=[rhs.hp,rhs.shield,old.x(rhs),rhs.effects]
		check(got==want,"2 pinned 72bf1b2 legacy "+kind,got,want)
	for chain in [false,true]:
		b=fixture(); b.freeze_finish=true; a=b.data.allies[0]; b.current_id=a.id; a.class_id="unsanctioned"
		a.skills.ruin={"name":"파괴적 마법","mp":0,"target":"적 전체","power":.6,"brk":0}
		for e in b.data.enemies: e.hp=10000; e.mhp=10000
		if chain: a.gear_special=[{"key":"un_chain","v":[3,20]}]
		for step in range(1,4):
			b.act("ruin"); var e=b.data.enemies[0]; var want=oracle.ruin[(3 if chain else 0)+step-1]
			var got={"hp":e.hp,"amount":b.fx(e,"dot"),"count":b.x(e).get("dot_stacks",0)}
			check(got.hp==want.hp and got.amount==want.amount and got.count==want.count,"3 ruin %s x%d"%[chain,step],got,want)
	b=fixture(); b.freeze_finish=true; a=b.data.allies[0]; a.class_id="unsanctioned"; b.current_id=a.id
	a.skills.ruin={"name":"test","mp":0,"target":"적 전체","power":.6,"brk":0}
	for foe in b.data.enemies: foe.hp=1
	b.act("ruin")
	check(b.data.enemies[0].effects.get("dot",{}).get("stacks",[]).size()==oracle.ruin_kill[0].count,"ruin does not push a line after lethal hit")
	for row in oracle.scar:
		b=fixture(); a=b.data.allies[0]; a.hp=1; a.gear_special=[{"key":"wa_scar","v":[50,50]}]
		b._incoming_strike(a,100,b.data.enemies[0],{"name":"test"},false,row.fixed)
		check(b.x(a).get("scar",0)==row.scar,"4 dead scar %s"%row.fixed,b.x(a).get("scar",0),row.scar)
	for row in oracle.order:
		b=fixture(); a=b.data.allies[0]; a.hp=250; var s=b.data.allies[1]; b.extra_state.sorel=b.x(s); s.id="sorel"
		a.gear_special=[{"key":"last_stand","p":100,"x":20,"n":2}]
		b._incoming_strike(a,100,b.data.enemies[0],{"name":"test"},false,row.fixed)
		check(a.hp==row.hp and b.x(a).get("stood",false)==row.stood,"6 personal damaged before gear %s"%row.fixed,{"hp":a.hp,"stood":b.x(a).get("stood",false)},row)
	b=fixture(); a=b.data.allies[0]; var e=b.data.enemies[0]
	b._effect(e,"dot",3,100); b.x(e).dot_stacks=4
	b._push_class_dot(e,20,3,a.id)
	check(b.x(e).dot_stacks==5 and b.fx(e,"dot")==120,"5 old aggregate retains stack count",{"n":b.x(e).dot_stacks,"sum":b.fx(e,"dot")},{"n":5,"sum":120})
	var restored=fixture(); var saved=JSON.parse_string(JSON.stringify(b.snapshot()))
	for enemy_id in saved.units:
		if not b.enemy(enemy_id).is_empty(): saved.units[enemy_id].hp=1
	check(restored.restore(saved),"5 migrated aggregate JSON restores")
	for row in oracle.round:
		b=fixture(); a=b.data.allies[0]; e=b.data.enemies[0]
		match row.kind:
			"judith":
				b.extra_state.judith=b.x(a); a.id="judith"; e.speed=101
				b._personal(a,e,a,{})
				if row.repeat_cast: b.ctb_round=1; b._personal(a,e,a,{})
				b.ctb_round=int(row.rd); b._round_tick()
				check(is_equal_approx(b.speed(e),row.speed) and e.speed==row.sp,"round Judith "+str(row),[e.speed,b.speed(e)],[row.sp,row.speed])
			"persona":
				b.extra_state.persona=b.x(a); a.id="persona"; b.data.allies[1].hp=500
				if b.has_method("set_persona_regen"): b.call("set_persona_regen",b.data.allies[1],31,2)
				else: b._effect(b.data.allies[1],"persona_regen",2,31)
				if row.dead_owner: a.hp=0
				for n in range(int(row.n)): b._round_tick()
				var got=[b.data.allies[1].hp,b.data.allies[1].effects.get("persona_regen",{}).get("turns",0)]
				check(got[0]==row.hp and got[1]==row.left,"round persona "+str(row),got,[row.hp,row.left])
			"felice":
				var f=b.data.allies[1]; b.extra_state.felice=b.x(f); f.id="felice"; a.remaining=row.g; a.hp=1
				b._incoming_strike(a,100,e,{"name":"test"},false,true)
				b.ctb_tick=int(row.elapsed); b._felice_scan()
				check(a.hp==row.hp and a.remaining==row.gauge,"round Felice wait "+str(row),[a.hp,a.remaining],[row.hp,row.gauge])
			"wall":
				a.hp=0; b._effect(a,"wall_party",2,.3)
				for n in range(int(row.n)): b._round_tick()
				check(a.effects.get("wall_party",{}).get("turns",0)==row.left,"round dead wall "+str(row),a.effects.get("wall_party",{}).get("turns",0),row.left)
	for own in [false,true]:
		b=fixture(); a=b.data.allies[0]
		if b.has_method("_begin_effect_action"): b.call("_begin_effect_action",a.id if own else b.data.allies[1].id)
		b._effect(a,"attack_up",2,.2)
		for n in range(4):
			if n>0: b.dungeon_enemy_r21.end_effects(a)
			var want=oracle.effects[(4 if own else 0)+n].left
			check(a.effects.get("attack_up",{}).get("turns",0)==want,"effect end own %s step %d"%[own,n],a.effects.get("attack_up",{}).get("turns",0),want)
	for row in oracle.events:
		b=fixture(); b.freeze_finish=true; a=b.data.allies[0]; e=b.data.enemies[0]
		for u in b.data.allies: u.hp=500
		for u in b.data.enemies: u.hp=10000; u.mhp=10000; u.gauge=10000
		b.current_id=a.id; b.selected_enemy=e.id; b.selected_ally=b.data.allies[1].id
		var kind=row.input.kind; var id=row.input.id
		for i in range(row.input.rows.size()): (b.data.allies+b.data.enemies)[i].row=row.input.rows[i]
		if kind=="personal":
			b.extra_state[id]=b.x(a); a.id=id; b.current_id=id
			a.skills.personal={"name":"test","mp":0,"target":"아군 1" if id in ["marceline","urda","felice","berenga","miko"] else "적 1","brk":15}
			# This oracle invokes PRUN directly, bypassing can_use/player/reseed.
			b.x(e).source_rng=int(row.input.start_rng); b.action_id="personal"
			b._begin_combat_events("personal",a,e,b.data.allies[1]); b._personal(a,e,b.data.allies[1],a.skills.personal); b.combat_events.finish(b)
		elif kind=="batch":
			a.skills.burst={"name":"test","mp":0,"power":1.9,"brk":0,"target":"적 1"}
			b.act("burst"); e.acts=[{"kind":"charge","name":"test"}]; e.act_index=0; b.current_id=e.id
			b.dungeon_enemy_r21.turn(); b.current_id=a.id; b.automatic_turn()
			e.broken=true; e.charged=false; b.current_id=e.id; b.dungeon_enemy_r21.turn()
		elif kind=="boundary":
			match id:
				"deplete": e.gauge=10; b._break(e,100)
				"recover","cancel":
					e.broken=true; e.charged=id=="cancel"; b.current_id=e.id; b.dungeon_enemy_r21.turn()
				"adot": b.dungeon_enemy_r21.add_dot(a,e,20,3); b._tick(a)
				"end":
					for foe in b.data.enemies: foe.hp=0
					b._check_end()
				"phase":
					b.dungeon_enemy_r21.configure(e,"tome_librarian",1,0); b.data.enemies[1].hp=0
					e.hp=1; b.dungeon_enemy_r21.phase_check()
		elif kind=="enemy":
			e.acts=[row.input.act.duplicate(true)]; e.act_index=0; e.target_id=a.id; b.current_id=e.id
			if id=="all": e.acts[0].kind="big_all"
			if id!="heal_full": b.data.enemies[1].hp=500
			b.dungeon_enemy_r21.turn()
		elif kind=="item":
			var native_id={"hp_s":"hp_s","mp_s":"mp_s","sh_s":"sh_s","antidote":"antidote","bandage":"bandage"}[id]
			var item={"id":native_id,"name":"test","level":1,"kind":{"hp_s":"hp","mp_s":"mp","sh_s":"shield","antidote":"cleanse","bandage":"revive"}[id],"fraction":.2}
			b.inventory[native_id]=1
			if id=="bandage": b.data.allies[1].hp=0
			if id=="antidote": b.dungeon_enemy_r21.add_dot(b.data.allies[1],e,10,3)
			b._use_supply(item,b.data.allies[1])
		else:
			var native_id={"atk":"attack","df":"guard","guard2":"guard","shield":"pshield","pshield":"hshield","defdn":"acid","wave":"chaoswave"}.get(id,id)
			if id=="release":
				a.charging=true; a.skills.burst={"name":"test","power":1.9,"brk":0}; b.automatic_turn()
			else:
				a.skills[native_id]={"name":"test","mp":0,"target":"아군 1" if id=="tonic" else "적 전체" if id in ["ruin","wave"] else "적 1","power":.6,"brk":0,"turns":2}
				b.act(native_id)
		var got=b.call("combat_event_trace") if b.has_method("combat_event_trace") else {"events":[],"T":0}
		check(same(got,{"events":row.events,"T":row.T}),"events "+str(row.input),got,{"events":row.events,"T":row.T})
	for row in oracle.display:
		b=fixture()
		var got=b.call("combat_display_schedule",row.event) if b.has_method("combat_display_schedule") else []
		check(same(got,row.observed),"display "+row.event.k,got,row.observed)
	for row in oracle.chips:
		b=fixture(); a=b.data.allies[0]; var t=b.data.allies[1]; t.name=row.names[1]
		var kind=row.kind
		match kind:
			"down": a.hp=0
			"shield": a.shield=21
			"taunt": b._effect(a,"taunt",2)
			"guard": b._effect(a,"guard",1,.4)
			"charge": a.charging=true
			"protect": b.x(a).protect=t.id
			"hidden": b.x(a).hidden=true
			"silence": b._effect(a,"silence",1)
			"oath": b.x(a).cover=t.id
			"rift": b._effect(a,"rift_charge",99,1)
			"mark": b._effect(a,"mark",1,1)
			"fox": b._effect(a,"foxflame",3,.6)
			"dot": b._push_class_dot(a,10,2,a.id); b._push_class_dot(a,10,3,a.id)
			"edot": b.dungeon_enemy_r21.add_dot(a,b.data.enemies[0],10,3)
			"amp": b._effect(a,"enemy_attack_self",3,.2)
			"seal": a.once=true
			"save": b.x(a).saved=true
			"atk","def","adn","ddn","spd","sdn","bl","g2","bs":
				b._effect(a,{"atk":"attack_up","def":"defense_up","adn":"attack_down","ddn":"defense_down","spd":"haste","sdn":"slow","bl":"blood","g2":"fortified_guard","bs":"backstep"}[kind],2,.2)
		var got=b.call("status_chips",a) if b.has_method("status_chips") else []
		check(same(got,row.labels),"chips "+kind,got,row.labels)
	for burst in [false,true]:
		b=fixture(); e=b.data.enemies[0]; e.hp=10000; e.mhp=10000
		if burst: b.data.allies[0].gear_special=[{"key":"dot_burst","p":100,"x":50}]
		b._push_class_dot(e,10,2,b.data.allies[0].id); b._push_class_dot(e,20,3,b.data.allies[1].id)
		for n in range(4):
			b._tick(e); var want=oracle.dots[(4 if burst else 0)+n]
			var got=[e.hp,b.x(e).get("dot_stacks",0),b.fx(e,"dot")]
			check(same(got,[want.hp,want.count,want.amount]),"DOT individual lifetime %s tick %d"%[burst,n+1],got,[want.hp,want.count,want.amount])
	b=fixture(); e=b.data.enemies[0]; e.hp=10000; e.mhp=10000
	for i in range(2): b.data.allies[i].nation="모르가스 신관국"
	b._push_class_dot(e,30,3,b.data.allies[0].id); b._tick(e)
	check(e.hp==oracle.dots[8].hp,"DOT canonical Morgas multiplier",e.hp,oracle.dots[8].hp)
	b=fixture(); a=b.data.allies[0]; b.extra_state.adeline=b.x(a); a.id="adeline"; b.current_id=a.id
	for u in b.data.allies: u.hp=100
	for row in oracle.regen:
		b.turn_count=int(row.n)-1
		if row.n==1 or row.n==3: b._personal(a,b.data.enemies[0],b.data.allies[1],{})
		var target=b.data.allies[1]
		if b.has_method("_turn_end_regen"): b.call("_turn_end_regen",target)
		var left=target.effects.get("regen",{}).get("heals",[]).map(func(r):return r.turns)
		check(target.hp==row.hp and same(left,row.left),"Adeline separate end regen "+str(row.n),[target.hp,left],[row.hp,row.left])
	for row in oracle.supplies:
		b=fixture(); b.freeze_finish=true; b.data.seed=int(row.seed); a=b.data.allies[0]; var target=b.data.allies[1]
		b.current_id=a.id; target.hp=500; target.mhp=1003; target.mp=0; target.mmp=103
		for i in range(int(row.humans)): b.data.allies[i].race="인간"
		for i in range(int(row.marento)): b.data.allies[i].nation="마렌토 공화국"
		if row.get("solen",false): b.data.allies[1].nation="솔렌 성왕국"; b.data.allies[2].nation="솔렌 성왕국"
		target.gear_fx={"healrecv":25}; a.gear_fx={"shield":20}
		var item={"id":row.id,"name":"test","level":1,"kind":{"hp_s":"hp","mp_s":"mp","sh_s":"shield","bandage":"revive","antidote":"cleanse"}[row.id],"fraction":.2 if row.id=="hp_s" else .15}
		b.inventory[row.id]=1
		if row.id=="bandage": target.hp=0; target.remaining=1; b.dungeon_enemy_r21.add_dot(target,b.data.enemies[0],10,3)
		if row.id=="antidote": b.dungeon_enemy_r21.add_dot(target,b.data.enemies[0],10,3); b._effect(target,"foxflame",3,.6)
		b._use_supply(item,target)
		var got=[target.hp,target.mp,target.shield,target.remaining,not target.effects.has("enemy_dot_0") and not target.effects.has("foxflame"),b.x(b.data.enemies[0]).source_rng]
		check(same(got,[row.hp,row.mp,row.shield,row.g,row.clean,row.rng]),"supply arithmetic "+str([row.id,row.humans,row.marento]),got,[row.hp,row.mp,row.shield,row.g,row.clean,row.rng])
	for row in oracle.delays:
		b=fixture(); b.freeze_finish=true; a=b.data.allies[0]; e=b.data.enemies[0]
		b.current_id=a.id; e.remaining=10000; e.grade="boss" if row.boss else "mob"
		a.skills.burst={"name":"test","mp":0,"power":1.9,"brk":0,"target":"적 1"}
		b.act("burst")
		check(e.remaining==row.g,"charge delay boss "+str(row.boss),e.remaining,row.g)
	b=fixture()
	for i in range(2):
		a=b.data.allies[i]; a.hp=1; a.gear_special=[{"key":"wa_last","v":[20,2,30]}]
		b._incoming_strike(a,10000,{}, {"name":"test"},false,true)
	a=b.data.allies[2]; b._incoming_strike(a,100,{}, {"name":"test"},false,true)
	check(a.hp==oracle.walls[0].hp,"new wall replaces previous party wall",a.hp,oracle.walls[0].hp)
	b=fixture(); a=b.data.allies[0]; e=b.data.enemies[0]; e.hp=1
	b._push_class_dot(e,10,2,a.id); b._push_class_dot(e,20,3,b.data.allies[1].id)
	b._add_adeline_regen(b.data.allies[1],16,2,a.id)
	var value=JSON.parse_string(JSON.stringify(b.snapshot())); var loadable=Battle.new(b.data)
	for foe in b.data.enemies: value.units[foe.id].hp=1
	check(loadable.restore(value),"new DOT and regeneration metadata JSON restores")
	check(same(loadable.data.enemies[0].effects.dot,b.data.enemies[0].effects.dot),"DOT individual owners and lifetimes persist")
	for field in ["lifetimes","owners","bursts","initial_turns"]:
		var invalid=value.duplicate(true); invalid.units[e.id].effects.dot[field]=["bad"]
		check(not loadable.restore(invalid),"reject malformed DOT metadata "+field)
	for bad in ["bad",[{"amount":-1,"turns":2,"action":1}],[{"amount":16,"turns":0,"action":1}]]:
		var invalid=value.duplicate(true); invalid.units[b.data.allies[1].id].effects.regen.heals=bad
		check(not loadable.restore(invalid),"reject malformed regeneration "+str(bad))
	b=fixture(); a=b.data.allies[0]; e=b.data.enemies[0]; e.hp=1; e.speed=101
	var judith_state=b.x(a); b.extra_state.erase(a.id); a.id="judith"; b.extra_state.judith=judith_state
	for foe in b.data.enemies:
		if foe.target_id=="neutral_0": foe.target_id="judith"
	b.current_id=a.id; b.last_ally=a.id; b.selected_ally=a.id
	b._personal(a,e,a,{}); b.ctb_round=1; b.ctb_tick=100
	value=JSON.parse_string(JSON.stringify(b.snapshot()))
	for foe in b.data.enemies: value.units[foe.id].hp=1
	loadable=Battle.new(b.data)
	var loaded_judith=loadable.restore(value)
	check(loaded_judith and loadable.data.enemies[0].speed==e.speed,"Judith base speed reconstructs after JSON hydration",loadable.data.enemies[0].speed,e.speed)
	b=fixture(); a=b.data.allies[0]; b.current_id=a.id; b.freeze_finish=true; b.inventory.sh_s=1
	b._use_supply({"id":"sh_s","name":"test","level":1,"kind":"shield","fraction":.15},a)
	b.dungeon_enemy_r21.end_effects(a)
	check(a.effects.shield.turns==2,"item shield own action counts its turn end",a.effects.shield.turns,2)
	var report={"checks":checks,"failures":failures,"rows":rows}
	var f=FileAccess.open("res://../verification/data-r21/a6-latest.json",FileAccess.WRITE); f.store_string(JSON.stringify(report,"\t")); f.close()
	print("A6 ",checks," checks / failures ",failures.size()," ",failures)
	quit(0 if failures.is_empty() else 1)
