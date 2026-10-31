extends RefCounted
## Source enemy action vocabulary adapted to the existing r20 CTB battle model.
const Rules=preload("res://game/dungeon_rules_r21.gd")
var rules=Rules.new()
var battle_ref: WeakRef
var b:
	get: return battle_ref.get_ref()
var templates=JSON.parse_string(FileAccess.get_file_as_string("res://data/battle_scene.json"))
func _init(battle): battle_ref=weakref(battle)

func art(id: String) -> Dictionary:
	var f=rules.foes[id]
	if ResourceLoader.exists(f.art):
		var t=load(f.art); return {"art":f.art,"bbox":[0,0,t.get_width(),t.get_height()],"art_fallback":false}
	var key="lantern" if f.role in ["지원","소환"] else "orb" if f.role in ["사격","주술"] else "executor" if f.role=="방어" or f.grade in ["elite","boss","core","chief"] else "apprentice"
	var t=templates.enemies.filter(func(e):return e.id==key)[0]
	return {"art":t.art,"bbox":t.bbox.duplicate(),"art_fallback":true}

func configure(e: Dictionary,id: String,phase: int,index: int):
	var enc=b.data.encounter_r21.enc.duplicate(true)
	while enc.fl.size()<=index: enc.fl.append(""); enc.fg.append("minion")
	enc.fl[index]=id
	var d=rules.foe_def(enc,index,int(b.data.encounter_r21.el)); var st=rules.foe_stats(enc,d,int(d.lvn))
	st.hp*=b.data.get("enemy_power_r21",1); st.atk*=b.data.get("enemy_power_r21",1)
	e.merge({"foe_id":id,"name":d.name,"short":d.name,"role":d.role,"grade":d.grade,"row":"전열" if d.row=="front" else "후열","mhp":maxi(1,int(floor(st.hp+.5))),"attack":st.atk,"defense":st.de,"speed":st.sp,"max":st.ay,
		"acts":d.acts.duplicate(true),"weak":d.weak.duplicate(),"phase":phase,"rules":d.get("rules",{}).duplicate(true)},true)
	if phase==2:
		e.acts=d.phase2.acts.duplicate(true); e.weak=d.phase2.weak.duplicate()
	e.merge(art(id),true)

func roster() -> Array:
	return b.data.enemies.map(func(e):return {"foe_id":e.foe_id,"phase":e.get("phase",1)})

func hydrate(list: Variant) -> bool:
	if not list is Array or list.size()!=b.data.enemies.size(): return false
	var enc=b.data.encounter_r21.enc; var possible=[]
	for id in enc.fl:
		var f=rules.foes[id]
		for a in f.acts+f.get("phase2",{}).get("acts",[])+[f.get("phase2",{}).get("entry",{})]:
			if a.get("kind")=="summon": possible.append(a.enemy)
	for i in range(list.size()):
		var v=list[i]
		if not v is Dictionary or v.size()!=2 or not v.get("foe_id") is String: return false
		if not (v.get("phase") is int or v.get("phase") is float) or v.phase!=floor(v.phase) or int(v.phase) not in [1,2]: return false
		var id=v.foe_id
		if i<enc.fl.size() and id!=enc.fl[i]: return false
		if i>=enc.fl.size() and not id.is_empty() and id not in possible: return false
		if not id.is_empty():
			if not rules.foes.has(id) or (v.phase==2 and not rules.foes[id].has("phase2")): return false
			configure(b.data.enemies[i],id,int(v.phase),i)
	return true

func summon(e: Dictionary,a: Dictionary):
	var adds=0
	for u in b.data.enemies:
		if u.grade=="minion" and u.hp>0: adds+=1
	for n in range(int(a.get("count",1))):
		if adds>=int(rules.catalog.tune.boss.summon_cap): return
		for i in range(b.data.encounter_r21.enc.fl.size(),b.data.enemies.size()):
			var slot=b.data.enemies[i]
			if slot.hp<=0:
				configure(slot,a.enemy,1,i); slot.hp=slot.mhp; slot.gauge=float(slot.max); slot.act_index=0; slot.effects={}; slot.broken=false; slot.charged=false; slot.remaining=10000.0
				b.extra_state[slot.id]={}; slot.target_id=pick_target(slot).id
				adds+=1; b._event(e.name+" · "+a.name+" → "+slot.name); break

func phase_check():
	for e in b.data.enemies:
		if e.hp<=0 or e.foe_id.is_empty() or e.get("phase",1)!=1: continue
		var f=rules.foes[e.foe_id]
		if f.has("phase2") and e.hp<=e.mhp*rules.catalog.tune.boss.phase_hp:
			e.phase=2; e.acts=f.phase2.acts.duplicate(true); e.weak=f.phase2.weak.duplicate(); e.gauge=float(e.max); e.broken=false; e.act_index=0; e.charged=false; e.remaining=10000.0
			b._event(e.name+" · 2단계")
			if f.phase2.get("weak_cycle",false): cycle(e)
			if f.phase2.has("entry"): summon(e,f.phase2.entry)
			e.target_id=pick_target(e).id

func phase_guard(e: Dictionary):
	if not e.foe_id.is_empty() and e.get("phase",1)==1 and rules.foes[e.foe_id].has("phase2") and e.hp<=e.mhp*rules.catalog.tune.boss.phase_hp:
		e.hp=maxi(e.hp,maxi(1,int(floor(e.mhp*rules.catalog.tune.boss.phase_hp))-1))

func protector(e: Dictionary) -> Dictionary:
	for u in b.living(false):
		if not u.broken and b.x(u).get("protect","")==e.id: return u
	return e

func defense(a: Dictionary,e: Dictionary) -> float:
	var m=1.0; var R=e.rules
	if R.has("dr_while_ally"):
		for u in b.living(false):
			if u.id!=e.id and u.foe_id==R.dr_while_ally.enemy: m*=R.dr_while_ally.mult; break
	if a.line=="str" and R.has("melee_dr"): m*=1-R.melee_dr
	if a.line!="str" and b.x(e).get("hidden",false): m*=1-R.get("ranged_dr",.5)
	return m*(1-b.fx(e,"guard"))

func after_hit(a: Dictionary,e: Dictionary):
	if e.hp<=0: return
	if e.rules.has("weak_hit_delay") and a.element==e.rules.weak_hit_delay.el: e.remaining+=10000*e.rules.weak_hit_delay.amount*(rules.catalog.tune.boss.reduce if e.grade=="boss" else 1)
	if e.rules.has("counter_when_guard") and e.effects.has("guard") and not b.x(e).get("counter_busy",false):
		b.x(e).counter_busy=true
		b._enemy_hit(e,a,{"name":"되치기","kind":"atk","m":e.rules.counter_when_guard.get("m",.6)})
		b.x(e).counter_busy=false

func attack_mult(e: Dictionary) -> float:
	var m=(1+b.fx(e,"enemy_attack_self"))*(1+b.fx(e,"attack_up")); var R=e.rules; var T=rules.catalog.tune.boss
	if R.has("hp_atk") and e.hp<=e.mhp*R.hp_atk.thr: m*=1+R.hp_atk.amount
	if e.grade=="chief" and e.hp<=e.mhp*T.rage_hp: m*=1+T.rage_atk
	# Round count follows one round per party-size actions in the existing CTB engine.
	if b.data.encounter_r21.enc.raid and e.grade in ["chief","boss","core"]:
		var round_no=int(b.x(e).get("foe_turns",0))
		if round_no>T.enrage_round: m*=1+minf(T.enrage_max,T.enrage_step*(round_no-T.enrage_round))
	return m

func cycle(e: Dictionary):
	var elements=rules.catalog.elements; var first=int(floor(random()*6)); var second=int(floor(random()*5))
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
	if a.kind=="aimed" or a.get("low",false): return lowest(pool)
	return pool[int(floor(random()*pool.size()))]

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
				var owner=b.enemy(source)
				if owner.is_empty() or owner.hp<=0 or owner.broken: u.effects.erase(key)

func end_effects(u: Dictionary):
	for key in u.effects.keys():
		var eff=u.effects[key]
		if eff.get("r21",false):
			eff.turns-=1
			if eff.turns<=0: u.effects.erase(key)
	drop_auras()

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

func intent(e: Dictionary) -> String:
	if e.hp<=0: return "쓰러짐"
	if e.broken: return "고갈 · 다음 행동 취소"
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
	begin_random(b.turn_count+1)
	var turns=int(b.x(e).get("foe_turns",0))
	var f=rules.foes.get(e.foe_id,{})
	if e.broken:
		e.broken=false; e.gauge=float(e.max); b._event(e.name+" · 차례 상실 · 심연 회복")
		if e.charged:
			e.charged=false; e.act_index=(int(e.act_index)+1)%e.acts.size()
			e.hp=maxi(0,e.hp-int(floor(e.mhp*e.rules.get("break_self",0))))
	else:
		b.x(e).protect=""; b.x(e).hidden=false
		turns+=1; b.x(e).foe_turns=turns
		if e.phase==2 and f.get("phase2",{}).get("weak_cycle",false): cycle(e)
		var a=e.acts[e.act_index]; var targets=b.living(false) if a.get("target")=="allies" else [e]
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
			"debuff":
				var list=allies_alive() if a.get("target")=="all" else [target(e,a)]
				for t in list:
					if a.stat=="delay": t.remaining+=10000*a.get("amount",.2)
					else: effect(t,{"atk":"attack_down","def":"defense_down","spd":"slow"}.get(a.stat,"attack_down"),int(a.get("turns",2)),a.get("amount",.2))
				b._event(e.name+" · "+a.name)
			"summon": summon(e,a)
			"special":
				if a.get("fx")=="silence":
					var choices=silence_choices()
					if not choices.is_empty():
						var choice=choices[int(floor(random()*choices.size()))]; b.x(choice[0]).silenced_id=str(choice[1]); effect(choice[0],"silence",1)
				b._event(e.name+" · "+a.name)
			"dot":
				var t=target(e,a)
				add_dot(t,e,dot_per(e,t,a.get("m",1)*a.get("tick",.3)),int(a.get("turns",3)))
				b._event(e.name+" · "+a.name)
			_:
				var list=allies_alive() if a.kind=="big_all" or a.get("target")=="all" else [target(e,a)]
				for t in list:
					var before={}
					for ally in b.data.allies: before[ally.id]=int(ally.hp)
					b._enemy_hit(e,t,a)
					if b.last_enemy_hit_target.is_empty(): continue
					t=b.ally(b.last_enemy_hit_target)
					if t.hp>0:
						if a.has("drain"): e.hp=mini(e.mhp,e.hp+int(floor((before[t.id]-t.hp)*a.drain)))
						if a.has("push"): t.remaining+=10000*a.push
						if a.has("dot"): add_dot(t,e,dot_per(e,t,a.dot.m),int(a.dot.get("turns",3)))
						if a.get("strip",false):
							for key in ["attack_up","defense_up","bless","guard","haste","shield"]:
								if t.effects.has(key): t.effects.erase(key); break
				if a.kind in ["big_one","big_all"]: e.charged=false
		e.act_index=(int(e.act_index)+1)%e.acts.size()
		if e.rules.has("hide_every") and turns%int(e.rules.hide_every)==0: b.x(e).hidden=true
	e.target_id=pick_target(e).id
	phase_check(); b._finish_turn(); return true
