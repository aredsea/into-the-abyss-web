extends RefCounted
const Text=preload("res://game/combat_display_r22.gd")
## Source enemy action vocabulary adapted to the existing r20 CTB battle model.
const Rules=preload("res://game/dungeon_rules_r21.gd")
var rules=Rules.new()
var battle_ref: WeakRef
var b:
	get: return battle_ref.get_ref()
var templates=JSON.parse_string(FileAccess.get_file_as_string("res://data/battle_scene.json"))
var counter_active=false
func _init(battle): battle_ref=weakref(battle)

func start() -> void:
	if not b.data.has("encounter_r21"):return
	for e in b.data.enemies:
		if e.hp>0 and e.get("rules",{}).get("first_move",false):e.remaining=0

func turn_start(e: Dictionary) -> void:
	b.x(e).protect="";b.x(e).hidden=false
	b.x(e).foe_turns=b.x(e).get("foe_turns",0)+1
	var f=rules.foes.get(e.foe_id,{})
	if e.phase==2 and f.get("phase2",{}).get("weak_cycle",false):cycle(e)

func art(id: String) -> Dictionary:
	var f=rules.foes[id]
	if ResourceLoader.exists(f.art):
		var t=load(f.art); return {"art":f.art,"bbox":[0,0,t.get_width(),t.get_height()],"art_fallback":false}
	var key="lantern" if f.role in ["지원","소환"] else "orb" if f.role in ["사격","주술"] else "executor" if f.role=="방어" or f.grade in ["elite","boss","core","chief"] else "apprentice"
	var t=templates.enemies.filter(func(e):return e.id==key)[0]
	return {"art":t.art,"bbox":t.bbox.duplicate(),"art_fallback":true}

func configure(e: Dictionary,id: String,phase: int,index: int,grade_override: String=""):
	var enc=b.data.encounter_r21.enc.duplicate(true)
	while enc.fl.size()<=index: enc.fl.append(""); enc.fg.append("minion")
	if not grade_override.is_empty(): enc.fg[index]=grade_override
	enc.fl[index]=id
	var d=rules.foe_def(enc,index,int(b.data.encounter_r21.el)); var st=rules.foe_stats(enc,d,int(d.lvn))
	st.hp*=b.data.get("enemy_power_r21",1); st.atk*=b.data.get("enemy_power_r21",1)
	e.merge({"foe_id":id,"name":d.name,"short":d.name,"role":d.role,"grade":d.grade,"row":"전열" if d.row=="front" else "후열","mhp":maxi(1,int(floor(st.hp+.5))),"attack":st.atk,"defense":st.de,"speed":st.sp,"max":st.ay,
		"acts":d.acts.duplicate(true),"weak":d.weak.duplicate(),"phase":phase,"rules":d.get("rules",{}).duplicate(true)},true)
	if phase==2:
		e.acts=d.phase2.acts.duplicate(true); e.weak=d.phase2.weak.duplicate()
	e.merge(art(id),true)

func roster() -> Array:
	var out=[]
	for i in range(b.data.enemies.size()):
		var e=b.data.enemies[i]
		var value={"foe_id":e.foe_id,"phase":e.get("phase",1),"target_id":e.target_id}
		if i>=b.data.encounter_r21.enc.fl.size() and not e.foe_id.is_empty(): value.summon_grade=e.grade
		out.append(value)
	return out

func hydrate(list: Variant) -> bool:
	if not list is Array or list.size()!=b.data.enemies.size(): return false
	var enc=b.data.encounter_r21.enc; var possible=[]
	for id in enc.fl:
		var f=rules.foes[id]
		for a in f.acts+f.get("phase2",{}).get("acts",[])+[f.get("phase2",{}).get("entry",{})]:
			if a.get("kind")=="summon": possible.append(a.enemy)
	for i in range(list.size()):
		var v=list[i]
		if not v is Dictionary or v.size()!=2+int(v.has("target_id"))+int(v.has("summon_grade")) or not v.get("foe_id") is String: return false
		if v.has("summon_grade") and (i<enc.fl.size() or v.summon_grade not in ["mob","minion"]): return false
		if v.has("target_id"):
			if not v.target_id is String: return false
			if v.target_id!="" and v.target_id!=b.data.enemies[i].id and b.ally(v.target_id).is_empty(): return false
		if not (v.get("phase") is int or v.get("phase") is float) or v.phase!=floor(v.phase) or int(v.phase) not in [1,2]: return false
		var id=v.foe_id
		if i<enc.fl.size() and id!=enc.fl[i]: return false
		if i>=enc.fl.size() and not id.is_empty() and id not in possible: return false
		if not id.is_empty():
			if not rules.foes.has(id) or (v.phase==2 and not rules.foes[id].has("phase2")): return false
			# Old schema-3 summons were serialized with mob statistics. Keep those
			# statistics until this fight ends; new summons record the source grade.
			configure(b.data.enemies[i],id,int(v.phase),i,v.get("summon_grade","") if i>=enc.fl.size() else "")
		# Legacy rosters retain constructor-initialized forecasts without consuming RNG.
		if v.has("target_id"): b.data.enemies[i].target_id=v.target_id
	return true

func summon(e: Dictionary,a: Dictionary,emit_event=true):
	var adds=0; var made=[]
	for u in b.data.enemies:
		if u.grade=="minion" and u.hp>0: adds+=1
	for n in range(int(a.get("count",1))):
		if adds>=int(rules.catalog.tune.boss.summon_cap): break
		# 31-foes summon_one uses empty slots first. A fallen minion can be
		# reused only on a later press, after its current event has finished.
		var candidates=[]
		for i in range(b.data.enemies.size()):
			if b.data.enemies[i].foe_id.is_empty(): candidates.append(i)
		for i in range(b.data.enemies.size()):
			var u=b.data.enemies[i]
			# Pre-P2 schema-3 summons retained mob statistics. Their reserved
			# slots stay reusable until this old fight ends (hydrate preserves
			# that grade), just like new minion slots.
			var summon_slot=u.grade=="minion" or i>=b.data.encounter_r21.enc.fl.size()
			if not u.foe_id.is_empty() and summon_slot and u.hp<=0 and not b.combat_events.changed_slots.has(b.combat_events.slot(b,u)): candidates.append(i)
		for i in candidates:
			var slot=b.data.enemies[i]
			if slot.hp<=0:
				configure(slot,a.enemy,1,i,"minion"); slot.hp=slot.mhp; slot.gauge=float(slot.max); slot.act_index=0; slot.effects={}; slot.broken=false; slot.charged=false; slot.remaining=10000.0
				b.extra_state[slot.id]={}; slot.target_id=pick_target(slot).id
				adds+=1; made.append(slot); b._event(e.name+" · "+a.name+" → "+slot.name); break
	if emit_event:
		var action=a.duplicate(true); action.kind="summon"
		b.combat_events.enemy(b,e,action,made)

func phase_check():
	for e in b.data.enemies:
		if e.hp<=0 or e.foe_id.is_empty() or e.get("phase",1)!=1: continue
		var f=rules.foes[e.foe_id]
		if f.has("phase2") and e.hp<=e.mhp*rules.catalog.tune.boss.phase_hp:
			e.phase=2; e.acts=f.phase2.acts.duplicate(true); e.weak=f.phase2.weak.duplicate(); e.gauge=float(e.max); e.broken=false; e.act_index=0; e.charged=false; e.remaining=10000.0
			b._event(e.name+" · 2단계")
			b.combat_events.push("phase",b.combat_events.slot(b,e),b.combat_events.T); b.combat_events.T+=1.2
			if f.phase2.get("weak_cycle",false): cycle(e)
			if f.phase2.has("entry"): summon(e,f.phase2.entry)
			e.target_id=pick_target(e).id

func phase_guard(e: Dictionary,before: int=-1):
	if not e.foe_id.is_empty() and e.get("phase",1)==1 and rules.foes[e.foe_id].has("phase2") and e.hp<=0:
		var cap=maxi(1,int(floor(e.mhp*rules.catalog.tune.boss.phase_hp))-1)
		e.hp=cap if before>cap or before<0 else maxi(1,before)

func protector(e: Dictionary) -> Dictionary:
	for u in b.living(false):
		if not u.broken and b.x(u).get("protect","")==e.id: return u
	return e

func defense(a: Dictionary,e: Dictionary) -> float:
	return defense_tags(a,e,[])

func defense_tags(a: Dictionary,e: Dictionary,tags: Array) -> float:
	var m=1.0; var R=e.rules
	if R.has("dr_while_ally"):
		for u in b.living(false):
			if u.id!=e.id and u.foe_id==R.dr_while_ally.enemy:
				m*=R.dr_while_ally.mult
				var name=Text.unit_name(u)
				tags.append(name+Text.Josa.tail(name,"이가")+" 서 있다 −%d%%"%Text.percent(1-R.dr_while_ally.mult));break
	if a.line=="str" and R.has("melee_dr"):
		m*=1-R.melee_dr;tags.append("비행 −%d%%"%Text.percent(R.melee_dr))
	if R.has("ranged_dr") and a.line!="str" and b.x(e).get("hidden",false):
		m*=1-R.ranged_dr;tags.append("은신 −%d%%"%Text.percent(R.ranged_dr))
	return m # Defensive stance is floored after the raw hit, in B.strike.

func after_hit(a: Dictionary,e: Dictionary,element: Variant=null):
	if e.hp<=0: return
	var attack_element=a.element if element==null else element
	if e.rules.has("weak_hit_delay") and attack_element==e.rules.weak_hit_delay.el: e.remaining+=10000*e.rules.weak_hit_delay.amount*(rules.catalog.tune.boss.reduce if e.grade=="boss" else 1)
	if e.rules.has("counter_when_guard") and e.effects.has("guard") and not counter_active and not b.x(e).get("counter_busy",false):
		counter_active=true; b.x(e).counter_busy=true
		b._enemy_hit(e,a,{"name":"되치기","kind":"atk","m":e.rules.counter_when_guard.get("m",.6),"counter":true})
		b.x(e).counter_busy=false; counter_active=false

func attack_mult(e: Dictionary) -> float:
	return attack_multiplier(e).value

func attack_multiplier(e: Dictionary) -> Dictionary:
	var result=attack_bonus(e)
	result.value*=1+b.fx(e,"enemy_attack_self")
	return result

# B.foe_atk_mul excludes u.am; callers multiply that separate scalar.
func attack_bonus(e: Dictionary) -> Dictionary:
	var m=1+b.fx(e,"attack_up"); var R=e.rules; var T=rules.catalog.tune.boss
	var tags=[]
	if R.has("hp_atk") and e.hp<=e.mhp*R.hp_atk.thr:
		m*=1+R.hp_atk.amount;tags.append("분노 +%d%%"%Text.percent(R.hp_atk.amount))
	if e.grade=="chief" and e.hp<=e.mhp*T.rage_hp:
		m*=1+T.rage_atk;tags.append("분노 +%d%%"%Text.percent(T.rage_atk))
	if b.data.encounter_r21.enc.raid and e.grade in ["chief","boss","core"]:
		var round_no=b.ctb_round
		if round_no>T.enrage_round:
			var value=minf(T.enrage_max,T.enrage_step*(round_no-T.enrage_round));m*=1+value;tags.append("장기전 +%d%%"%Text.percent(value))
	return {"value":m,"tags":", ".join(tags) if not tags.is_empty() else false}

func cycle(e: Dictionary):
	var elements=rules.catalog.elements; var first=mini(5,int(floor(random()*6))); var second=mini(4,int(floor(random()*5)))
	if second>=first: second+=1
	e.weak=[elements[first],elements[second]]
	b.x(e).cycle_a=first; b.x(e).cycle_b=second

func restore_cycles():
	for e in b.data.enemies:
		if b.x(e).has("cycle_a") and b.x(e).has("cycle_b"):
			var a=int(b.x(e).cycle_a); var c=int(b.x(e).cycle_b)
			if a>=0 and a<6 and c>=0 and c<6 and a!=c: e.weak=[rules.catalog.elements[a],rules.catalog.elements[c]]
func random() -> float:
	var state=b.x(b.data.enemies[0])
	state.source_rng=(int(state.get("source_rng",1))*16807)%2147483647
	return float(state.source_rng)/2147483647.0

func begin_random(action_no: int):
	b.x(b.data.enemies[0]).source_rng=(int(b.data.seed)*31+action_no*977+13)%2147483646+1

func initialize_targets():
	begin_random(0)
	for e in b.data.enemies:
		if e.hp>0: e.target_id=pick_target(e).id

func pick_target(e: Dictionary) -> Dictionary:
	var a=e.acts[e.act_index]
	if a.kind in ["buff","guard","heal","summon","protect","charge"]: return e
	var pool=b.data.allies.filter(func(u):return u.hp>0)
	if pool.is_empty(): return b.data.allies[0]
	# Imported "aimed" is the native alias for source atk + low=true.
	# An explicit low flag still takes precedence over that alias.
	if a.get("low",a.kind=="aimed"): return lowest(pool)
	return pool[mini(pool.size()-1,int(floor(random()*pool.size())))]

func allies_alive() -> Array:
	return b.data.allies.filter(func(u):return u.hp>0)

func lowest(pool: Array,prefer_back=false) -> Dictionary:
	var best={}; var score=INF
	for u in pool:
		var value=float(u.hp)/u.mhp+(0 if prefer_back and u.row=="후열" else 10)
		if value<score: best=u; score=value
	return best

func effect(u: Dictionary,key: String,turns: int,amount: float=0,source: String=""):
	b._effect(u,key,turns,amount)
	u.effects[key].r21=true
	if not source.is_empty(): u.effects[key].source=source

func drop_auras():
	for u in b.data.allies+b.data.enemies:
		for key in u.effects.keys():
			var source=u.effects[key].get("source","")
			if not source.is_empty():
				var owner=b.unit(source)
				if owner.is_empty() or owner.hp<=0 or (not owner.has("base") and owner.broken): u.effects.erase(key)

func end_effects(u: Dictionary):
	tick_buffs(u)
	drop_auras()

# The btick contract is independent of the subsequent caster/aura cleanup.
func tick_buffs(u: Dictionary):
	for key in u.effects.keys():
		if key=="guard" and u.has("base"): continue # df is reset at begin_turn, separately from bf.g2.
		if key.begins_with("enemy_dot_") or key in ["taunt","mark","sorel_regen","persona_regen","dot","corrosion","bleed","regen"]: continue
		var eff=u.effects[key]
		if eff.get("fresh",false): eff.erase("fresh"); continue
		eff.turns-=1
		if eff.turns<=0:
			u.effects.erase(key)
			if key=="shield" and u.has("base"): u.shield=0

func add_dot(u: Dictionary,e: Dictionary,per: int,turns: int):
	# Flat effect records preserve old saves and existing state validation.
	var dots=[]
	for i in range(4):
		var key="enemy_dot_%d"%i
		if u.effects.has(key): dots.append(u.effects[key].duplicate(true))
	if dots.size()==4: dots.pop_front()
	dots.append({"turns":turns,"amount":maxi(1,per),"by":e.id})
	for i in range(4): u.effects.erase("enemy_dot_%d"%i)
	for i in range(dots.size()): u.effects["enemy_dot_%d"%i]=dots[i]

func dot_per(e: Dictionary,t: Dictionary,coef: float) -> int:
	var k=40*rules.fc("def",e.level)
	var de=t.base.def*(1+b.fx(t,"bless")+b.fx(t,"defense_up")-b.fx(t,"defense_down"))
	return int(floor(e.attack*coef*(1+b.fx(e,"enemy_attack_self"))*(1-b.fx(e,"attack_down"))*k/(k+de)+1e-9))

func silence_choices() -> Array:
	var out=[]
	var aliases={"warrior":{"guard2":"guard"},"paladin":{"shield":"pshield","taunt":"ptaunt"},"priest":{"pshield":"hshield"},"alchemist":{"defdn":"acid"},"chaos":{"wave":"chaoswave"}}
	for u in b.data.allies:
		if u.hp<=0: continue
		for source_id in rules.config.enemy_skill_order.get(u.class_id,["personal"]):
			var id=aliases.get(u.class_id,{}).get(source_id,source_id)
			if u.skills.has(id): out.append([u,id])
	return out

func raid_charge_info(e: Dictionary) -> Dictionary:
	var a=e.acts[e.act_index]
	if e.charged: return {"turns":1,"name":a.name}
	if a.kind=="charge": return {"turns":2,"name":e.acts[(int(e.act_index)+1)%e.acts.size()].name}
	return {"turns":0,"name":""}

func intent(e: Dictionary) -> String:
	if e.hp<=0: return "쓰러짐"
	if e.broken: return "고갈 · 다음 행동 취소"
	if b.data.encounter_r21.enc.raid:
		var charge=raid_charge_info(e)
		if charge.turns>0: return "%d차례 뒤 %s · 심연 0으로 중단"%[charge.turns,charge.name]
	var a=e.acts[e.act_index]
	if a.kind=="charge": return a.name+" · 다음 큰 기술 준비"
	if a.kind in ["guard","buff","heal","summon","protect","special"]: return a.name
	if a.kind=="big_all" or a.get("target")=="all": return a.name+" → 아군 전체"
	return a.name+" → "+target(e,a).get("name","")

func target(e: Dictionary,a: Dictionary) -> Dictionary:
	if a.kind in ["buff","guard","heal","summon","protect","charge"]: return e
	var pool=b.data.allies.filter(func(u):return u.hp>0)
	if pool.is_empty(): return {}
	for u in pool:
		if u.effects.has("taunt"): return u
	var forecast=b.ally(e.target_id)
	return forecast if forecast in pool else pool[0]

func turn() -> bool:
	var e=b.enemy(b.current_id)
	if e.is_empty() or b.living(true).is_empty(): return false
	if allies_alive().is_empty(): b._finish_turn(); return true
	b.events=[]
	b.combat_hits=[]
	begin_random(b.turn_count+1)
	var turns=int(b.x(e).get("foe_turns",0))
	if e.broken:
		e.broken=false; e.gauge=float(e.max); b._event(e.name+" · 차례 상실 · 심연 회복")
		b.combat_events.push("recover",b.combat_events.slot(b,e),b.combat_events.T); b.combat_events.T+=1.2
		if e.charged:
			b.combat_events.push("ecut",b.combat_events.slot(b,e),b.combat_events.T)
			e.charged=false; e.act_index=(int(e.act_index)+1)%e.acts.size()
			e.hp=maxi(0,e.hp-int(floor(e.mhp*e.rules.get("break_self",0))))
	else:
		turn_start(e);turns=int(b.x(e).foe_turns)
		var a=e.acts[e.act_index]; var targets=b.living(false) if a.get("target")=="allies" else [e]
		var event_targets=[]
		match a.kind:
			"charge": e.charged=true; b._event(e.name+" · "+a.name)
			"guard": effect(e,"guard",2,.4); b._event(e.name+" · "+a.name)
			"protect":
				var list=b.living(false).filter(func(u):return u.id!=e.id)
				if not list.is_empty(): b.x(e).protect=lowest(list,true).id
				if a.get("guard",false): effect(e,"guard",2,.4)
				b._event(e.name+" · "+a.name)
			"heal":
				var pool=([e] if a.get("target")=="self" else b.living(false)).filter(func(u):return u.hp<u.mhp)
				if not pool.is_empty():
					var t=lowest(pool); var h=mini(t.mhp-t.hp,int(floor(t.mhp*a.get("amount",.2))))
					t.hp+=h; b._event(a.name+" → "+t.name+" · HP +%d"%h)
					event_targets=[t]
			"buff":
				if a.get("target")=="ally":
					var other=b.living(false).filter(func(u):return u.id!=e.id); targets=[lowest(other)] if not other.is_empty() else [e]
				for t in targets:
					if a.stat=="shield": effect(t,"shield",3,maxf(b.fx(t,"shield"),floor(t.mhp*a.amount)))
					elif a.stat=="pull": t.remaining=maxf(0,t.remaining-10000*a.amount)
					else:
						var key="enemy_attack_self" if a.stat=="atk" and a.get("target","self")=="self" and not a.get("until_down",false) else {"atk":"attack_up","def":"defense_up","spd":"haste"}.get(a.stat,"attack_up")
						effect(t,key,99 if a.get("until_down",false) else int(a.get("turns",3))+1,a.get("amount",0),e.id if a.get("until_down",false) else "")
				b._event(e.name+" · "+a.name)
				event_targets=targets
			"debuff":
				var list=allies_alive() if a.get("target")=="all" else [target(e,a)]
				for t in list:
					if a.stat=="delay": t.remaining+=10000*a.get("amount",.2)
					else: effect(t,{"atk":"attack_down","def":"defense_down","spd":"slow"}.get(a.stat,"attack_down"),int(a.get("turns",2)),a.get("amount",.2))
				b._event(e.name+" · "+a.name)
				event_targets=list
			"summon":
				var before=b.living(false).duplicate()
				summon(e,a,false)
				event_targets=b.living(false).filter(func(u):return u not in before)
			"special":
				if a.get("fx")=="silence":
					var choices=silence_choices()
					if not choices.is_empty():
						var choice=choices[int(floor(random()*choices.size()))]; b.x(choice[0]).silenced_id=str(choice[1]); effect(choice[0],"silence",1)
						event_targets=[choice[0]]
				b._event(e.name+" · "+a.name)
			"dot":
				var t=target(e,a)
				if not b._enemy_evade(e,t): add_dot(t,e,dot_per(e,t,a.get("m",1)*a.get("tick",.3)),int(a.get("turns",3)))
				event_targets=[t]
				b._event(e.name+" · "+a.name)
			_:
				var list=b.data.allies if a.kind=="big_all" or a.get("target")=="all" else [target(e,a)]
				event_targets=[]
				for t in list:
					if t.hp<=0: continue
					event_targets.append(t)
					b._enemy_hit(e,t,a)
					var hit=b.last_enemy_hit_result
					if b.last_enemy_hit_target.is_empty(): continue
					t=b.ally(b.last_enemy_hit_target)
					if t.hp>0:
						# 30-engine e_after_hit precedes personal/global attacked hooks.
						if a.has("push"): t.remaining+=10000*a.push
						if a.has("drain") and e.hp>0 and e.hp<e.mhp: e.hp=mini(e.mhp,e.hp+int(floor(hit.get("d",0)*a.drain+1e-9)))
						if a.has("dot"): add_dot(t,e,dot_per(e,t,a.dot.m),int(a.dot.get("turns",3)))
						if a.get("strip",false):
							# 31-foes STRIP_ORDER: atk, def, bs, bl, g2, red, red20, red25.
							for key in ["attack_up","defense_up","backstep","blood","fortified_guard","adeline_guard","contract","duty"]:
								if t.effects.has(key): t.effects.erase(key); break
						b.TraitRules.attacked(b,t,e)
						if b.gear_bridge!=null:
							b.gear_bridge.invoke("attacked",[b.gear_bridge.slot(t),b.gear_bridge.slot(e),hit,b.combat_events.T])
				if a.kind in ["big_one","big_all"]: e.charged=false
		b.combat_events.enemy(b,e,a,event_targets)
		e.act_index=(int(e.act_index)+1)%e.acts.size()
		if e.rules.has("hide_every") and turns%int(e.rules.hide_every)==0: b.x(e).hidden=true
	e.target_id=pick_target(e).id
	b._finish_turn(); return true
