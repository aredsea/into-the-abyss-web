extends RefCounted
## Pure GDScript model. No nodes, platform calls, or copied Lua engine.
const SCHEMA_VERSION=2
var data: Dictionary
var selected_enemy="executor"
var selected_action="attack"
var current_id="hildegard"
var last_ally="hildegard"
var result=""
var rng_state: int
var turn_count=0
var events: Array=[]
var history: Array=[]
var critical_this_action=false

func _init(scene_data: Dictionary={}) -> void:
	data=scene_data.duplicate(true)
	rng_state=int(data.get("seed",20261018))
	for a in data.get("allies",[]):
		a.hp=int(a.hp); a.mp=int(a.mp)
		a.effects={}; a.shield=0; a.ward_used=false; a.actions=0; a.once=false; a.charging=false; a.remaining=float(a.remaining)
	for e in data.get("enemies",[]):
		e.hp=int(e.hp); e.act_index=int(e.act_index)
		e.effects={}; e.broken=false; e.redirected=false; e.remaining=float(e.remaining); e.gauge=float(e.gauge)
	refresh_forecast()

func enemy(id: String) -> Dictionary:
	for e in data.get("enemies",[]):
		if e.id==id: return e
	return {}

func ally(id: String) -> Dictionary:
	for a in data.get("allies",[]):
		if a.id==id: return a
	return {}

func unit(id: String) -> Dictionary:
	return enemy(id) if ally(id).is_empty() else ally(id)

func living(friends: bool) -> Array:
	return data.allies.filter(func(a):return a.hp>0) if friends else data.enemies.filter(func(e):return e.hp>0)

func player_turn() -> bool:
	return result.is_empty() and not ally(current_id).is_empty()

func actions() -> Dictionary:
	return ally(current_id).skills if not ally(current_id).is_empty() else {}

func choose_enemy(id: String) -> bool:
	if enemy(id).is_empty() or enemy(id).hp<=0: return false
	selected_enemy=id
	return true

func choose_action(id: String) -> bool:
	if not actions().has(id): return false
	selected_action=id
	return true

func unavailable(id: String) -> String:
	if not player_turn() or not actions().has(id): return "행동할 수 없음"
	var a=ally(current_id); var skill=actions()[id]
	if skill.has("disabled"): return skill.disabled
	if a.charging: return "마력 폭발 충전 중"
	if id=="personal" and a.id=="teiris" and a.once: return "전투당 1회 사용함"
	return "MP 부족" if a.mp<skill.mp else ""

func _event(message: String) -> void:
	events.append(message); history.append(message)
	if history.size()>32: history.pop_front()

func _roll(chance: float) -> bool:
	rng_state=(rng_state*48271)%2147483647
	return float(rng_state)/2147483647.0<chance

func speed(u: Dictionary) -> float:
	var base_speed=float(u.base.spd) if u.has("base") else float(u.speed)
	var bonus=0.0
	for key in ["windup","alarm"]:
		bonus+=float(u.effects.get(key,{}).get("amount",0))
	return base_speed*(1+bonus)

func refresh_forecast() -> void:
	var pending=[]; var queue=[]
	for u in living(true)+living(false): pending.append({"id":u.id,"remaining":float(u.remaining),"speed":speed(u)})
	for i in range(8):
		if pending.is_empty(): break
		var best=0
		for j in range(1,pending.size()):
			if pending[j].remaining/pending[j].speed<pending[best].remaining/pending[best].speed: best=j
		queue.append(pending[best].id); pending[best].remaining+=data.formula.gauge
	data.queue=queue

func _tick(u: Dictionary) -> void:
	for key in u.effects.keys():
		u.effects[key].turns-=1
		if u.effects[key].turns<=0:
			u.effects.erase(key)
			if key=="shield": u.shield=0

func _effect(u: Dictionary,key: String,turns: int,amount: float=0) -> void:
	u.effects[key]={"turns":turns,"amount":amount}

func _finish_turn(interval_scale: float=1) -> void:
	var u=unit(current_id)
	u.remaining=float(data.formula.gauge)*interval_scale
	if u.has("base"):
		u.actions+=1
		if u.id=="bargut" and critical_this_action: u.remaining*=1-float(u.trait.p.pull)
		if u.id=="teiris" and int(u.actions)%int(u.trait.p.every)==0:
			u.remaining=0.0; _event("상대성 이론 · 테이리스 추가 행동")
	critical_this_action=false; turn_count+=1
	if living(false).is_empty(): result="victory"
	elif living(true).is_empty(): result="defeat"
	if not result.is_empty():
		_event("전투 승리" if result=="victory" else "전투 패배 · 부상으로 이탈")
		refresh_forecast(); return
	var next: Dictionary={}; var elapsed=INF
	for entry in living(true)+living(false):
		var t=maxf(0,float(entry.remaining))/speed(entry)
		if t<elapsed: elapsed=t; next=entry
	for entry in living(true)+living(false): entry.remaining=maxf(0,float(entry.remaining)-elapsed*speed(entry))
	current_id=next.id; _tick(next)
	if living(false).is_empty() or living(true).is_empty():
		result="victory" if living(false).is_empty() else "defeat"
		refresh_forecast(); return
	if next.has("mp"):
		next.mp=mini(next.mmp,next.mp+int(data.formula.mp_regen)); last_ally=next.id
	if enemy(selected_enemy).hp<=0: selected_enemy=living(false)[0].id
	selected_action="attack"; refresh_forecast()

func _break(e: Dictionary,amount: float) -> void:
	if e.hp<=0 or e.broken: return
	e.gauge=maxf(0,e.gauge-amount)
	if e.gauge>0: return
	e.broken=true; _event("%s · 고갈 · 다음 행동 취소" % e.short)
	if e.charged:
		e.charged=false
		var hit=int(floor(e.mhp*e.rules.get("break_self",0)))
		e.hp=maxi(0,e.hp-hit); _event("증기 분출 취소 · 과열 자해 %d" % hit)

func _damage(a: Dictionary,e: Dictionary,power: float,brk: float,extra=false) -> void:
	if e.hp<=0: return
	var chance=(float(a.base.crit)+float(a.base.agi)/data.formula.crit_per_agi+float(a.passive.get("crit",0))+float(a.trait.p.get("crit",0)))/100
	var critical=_roll(minf(1,chance)); critical_this_action=critical_this_action or critical
	var weak=a.element in e.weak
	var bonus=float(a.effects.get("bless",{}).get("amount",0))
	var k=data.formula.def_k_ratio*data.formula.def_std_base
	var damage=float(a.base[a.line])*data.formula.atk_per_stat*power*(1+bonus)*k/(k+e.defense)
	if weak: damage*=data.formula.weak_mult
	if e.broken: damage*=data.formula.break_mult
	if critical: damage*=data.formula.crit_dmg
	var dealt=maxi(1,int(floor(damage)))
	e.hp=maxi(0,e.hp-dealt)
	_event("%s → %s · %d 피해%s" % [a.name,e.short,dealt," · 치명" if critical else ""])
	_break(e,brk*(data.formula.brk_weak_mult if weak else 1.0))
	if a.id=="teiris" and e.hp>0: e.remaining+=data.formula.gauge*a.passive.delay
	if a.id=="bargut" and not extra and e.hp>0 and _roll(a.passive.extra): _damage(a,e,1.0,0,true)

func intimidation_target(id: String) -> Dictionary:
	if id=="taunt": return enemy(selected_enemy)
	var target=living(false)[0]
	for e in living(false):
		if e.hp<target.hp: target=e
	return target

func act(id: String) -> bool:
	if not unavailable(id).is_empty(): return false
	var a=ally(current_id); var skill=actions()[id]
	if skill.target=="적 1" and enemy(selected_enemy).hp<=0: return false
	events=[]; critical_this_action=false; a.mp-=int(skill.mp); selected_action=id
	match id:
		"attack": _damage(a,enemy(selected_enemy),skill.power,skill.brk)
		"guard":
			_effect(a,"guard",skill.turns,skill.power); _event("%s · 방어 · 피해 -40%%" % a.name)
		"taunt","duty":
			_effect(a,"taunt",skill.turns)
			if id=="duty": _effect(a,"duty",skill.turns,0.25)
			var foe=intimidation_target(id)
			_break(foe,skill.brk*(data.formula.brk_weak_mult if a.element in foe.weak else 1.0))
			_event("%s · %s · %d턴" % [a.name,skill.name,skill.turns])
		"burst":
			a.charging=true; enemy(selected_enemy).remaining+=data.formula.gauge*a.delay
			_event("테이리스 · 마력 폭발 충전 · 다음 차례 발동")
		"personal":
			a.once=true; _event("테이리스 · 마감 전날 대폭발")
			for e in living(false): _damage(a,e,skill.power,skill.brk)
		"hshield":
			for member in living(true):
				member.shield=int(floor(a.base.int*skill.power)); _effect(member,"shield",skill.turns)
			_event("파티 보호막 · 각 %d · 2턴" % int(a.base.int*skill.power))
		"bless":
			for member in living(true): _effect(member,"bless",skill.turns,skill.power)
			_event("파티 공격·방어 +15% · 3턴")
	_finish_turn(float(skill.turns) if id=="burst" else 1.0); return true

func automatic_turn() -> bool:
	if not result.is_empty(): return false
	var a=ally(current_id)
	if not a.is_empty():
		if not a.charging: return false
		events=[]; a.charging=false; _event("테이리스 · 마력 폭발 발동")
		for e in living(false): _damage(a,e,a.skills.burst.power,a.skills.burst.brk)
		_finish_turn(); return true
	var e=enemy(current_id)
	events=[]
	if e.broken:
		e.broken=false; e.gauge=float(e.max); _event("%s · 차례 상실 · 심연 회복" % e.short)
	else:
		var skill=e.acts[e.act_index]
		match skill.kind:
			"heal":
				var target=_heal_target()
				var healed=mini(target.mhp-target.hp,int(floor(target.mhp*skill.amount)))
				target.hp+=healed; _event("등불 보수 → %s · HP +%d" % [target.short,healed])
			"buff":
				var targets=living(false) if skill.target=="allies" else [e]
				for target in targets: _effect(target,"alarm" if e.id=="orb" else "windup",skill.turns,skill.amount)
				_event("%s · %s · 속도 +%d%%" % [e.short,skill.name,int(skill.amount*100)])
			"charge":
				e.charged=true; _event("집행 인형 · 과열 · 다음 증기 분출")
			"big_all":
				e.charged=false
				for target in living(true): _enemy_hit(e,target,skill)
			_:
				_enemy_hit(e,_attack_target(e),skill)
	e.act_index=(int(e.act_index)+1)%e.acts.size()
	_plan_redirect(e)
	_finish_turn(); return true

func _heal_target() -> Dictionary:
	var target=living(false)[0]
	for e in living(false):
		if float(e.hp)/e.mhp<float(target.hp)/target.mhp: target=e
	return target

func _peek_target(e: Dictionary) -> Dictionary:
	for a in living(true):
		if a.effects.has("taunt"): return a
	var target=ally(e.target_id)
	if target.is_empty() or target.hp<=0: target=living(true)[0]
	var h=ally("hildegard")
	return h if e.redirected and h.hp>0 else target

func _plan_redirect(e: Dictionary) -> void:
	# Roll once when the next intent is created. Inspecting/saving cannot reroll it.
	e.redirected=false
	if e.acts[e.act_index].kind not in ["atk","shoot","spell"]: return
	for a in living(true):
		if a.effects.has("taunt"): return
	var h=ally("hildegard")
	if h.hp>0 and e.target_id!=h.id: e.redirected=_roll(h.trait.p.pull)

func _attack_target(e: Dictionary) -> Dictionary:
	var target=_peek_target(e)
	var taunted=false
	for a in living(true):
		if a.effects.has("taunt"): taunted=true
	var h=ally("hildegard")
	if e.redirected and target.id==h.id and not taunted:
		h.hp=mini(h.mhp,h.hp+int(floor(h.mhp*h.trait.p.heal)))
		_event("첫 번째 펭귄 · 힐데가르트가 대신 받음")
	return target

func _enemy_hit(e: Dictionary,a: Dictionary,skill: Dictionary) -> void:
	var k=data.formula.def_k_ratio*data.formula.def_std_base*(1+data.def_curve.a+data.def_curve.b)
	var defense=float(a.base.def)*(1+float(a.effects.get("bless",{}).get("amount",0)))
	var hit=float(e.attack)*skill.get("m",1)*k/(k+defense)
	if a.id=="hildegard": hit*=1-float(a.trait.p.red)
	if a.effects.has("guard"): hit*=1-float(a.effects.guard.amount)
	if a.effects.has("duty"): hit*=1-float(a.effects.duty.amount)
	var damage=maxi(1,int(floor(hit))); var absorbed=mini(a.shield,damage)
	a.shield-=absorbed; damage-=absorbed; a.hp=maxi(0,a.hp-damage)
	_event("%s → %s · %d 피해%s" % [skill.name,a.name,damage," · 보호막 %d" % absorbed if absorbed>0 else ""])
	if a.hp==0 and not a.ward_used and ally("berenga").hp>0:
		a.ward_used=true; a.hp=int(floor(a.mhp*0.5)); _event("이탈 방지 · %s HP %d" % [a.name,a.hp])

func intent(e: Dictionary) -> String:
	if e.hp<=0: return "쓰러짐"
	if e.broken: return "고갈 · 다음 행동 취소 · 받는 피해 ×1.5"
	var skill=e.acts[e.act_index]
	match skill.kind:
		"big_all": return "%s → 아군 전체 / 심연 0이면 취소" % skill.name
		"heal": return "%s → %s" % [skill.name,_heal_target().short]
		"buff": return "%s · 속도 +%d%%" % [skill.name,int(skill.amount*100)]
		"charge": return "과열 → 다음 증기 분출 준비"
	if living(true).is_empty(): return skill.name
	var target=_peek_target(e)
	return "%s → %s" % [skill.name,target.name]

func effects_text(a: Dictionary) -> String:
	if a.hp==0: return "부상 이탈"
	var labels=[]
	for key in a.effects:
		labels.append({"guard":"방어","taunt":"도발","duty":"피해 -25%","shield":"보호막 %d" % a.shield,"bless":"공격·방어 +15%"}.get(key,key)+" %d턴" % a.effects[key].turns)
	if a.charging: labels.append("마력 폭발 충전 중")
	return " · ".join(labels) if not labels.is_empty() else "걸린 효과 없음"

func snapshot() -> Dictionary:
	var units={}
	for u in data.allies+data.enemies:
		var fields=["hp","remaining","effects"]
		fields.append_array(["mp","shield","ward_used","actions","once","charging"] if u.has("base") else ["gauge","broken","charged","act_index","redirected"])
		var values={}
		for field in fields: values[field]=u[field].duplicate(true) if u[field] is Dictionary else u[field]
		units[u.id]=values
	return {"schema_version":SCHEMA_VERSION,"build":data.build,"units":units,"current_id":current_id,"last_ally":last_ally,"selected_enemy":selected_enemy,"selected_action":selected_action,"result":result,"rng":rng_state,"turn_count":turn_count,"history":history.duplicate(),"events":events.duplicate()}

func restore(value: Variant) -> bool:
	if not value is Dictionary or value.get("schema_version")!=SCHEMA_VERSION or value.get("build")!=data.build: return false
	if not _shape_valid(value,snapshot()): return false
	if not value.current_id in value.units or ally(value.last_ally).is_empty() or enemy(value.selected_enemy).is_empty(): return false
	if value.result not in ["","victory","defeat"] or value.rng<1 or value.rng>=2147483647 or value.turn_count<0: return false
	for u in data.allies+data.enemies:
		var v=value.units[u.id]
		if v.hp<0 or v.hp>u.mhp or v.remaining<0 or v.remaining>1000000: return false
		if u.has("mp") and (v.mp<0 or v.mp>u.mmp or v.shield<0 or v.shield>10000 or v.actions<0): return false
		if u.has("gauge") and (v.gauge<0 or v.gauge>u.max or v.act_index<0 or v.act_index>=u.acts.size() or v.broken!=(v.gauge==0)): return false
		for key in v.effects:
			var effect=v.effects[key]
			if key not in ["guard","taunt","duty","shield","bless","windup","alarm"] or not effect is Dictionary or effect.size()!=2: return false
			if not _number(effect.get("turns")) or not _number(effect.get("amount")) or effect.turns<1 or effect.turns>3 or effect.amount<0 or effect.amount>1: return false
	for key in ["history","events"]:
		if value[key].size()>32: return false
		for line in value[key]:
			if not line is String or line.length()>200: return false
	var na=0; var ne=0
	for a in data.allies:
		if value.units[a.id].hp>0: na+=1
	for e in data.enemies:
		if value.units[e.id].hp>0: ne+=1
	if (value.result=="victory")!=(ne==0) or (value.result=="defeat")!=(na==0): return false
	if value.result.is_empty() and value.units[value.current_id].hp<=0: return false
	var actor=ally(value.current_id)
	if not actor.is_empty() and not actor.skills.has(value.selected_action): return false
	for id in value.units:
		for key in value.units[id]:
			var v=value.units[id][key]
			if key=="effects":
				var effects={}
				for effect in v: effects[effect]={"turns":int(v[effect].turns),"amount":float(v[effect].amount)}
				unit(id)[key]=effects
			elif key in ["remaining","gauge"]: unit(id)[key]=float(v)
			elif v is bool: unit(id)[key]=v
			else: unit(id)[key]=int(v)
	current_id=value.current_id; last_ally=value.last_ally; selected_enemy=value.selected_enemy; selected_action=value.selected_action
	result=value.result; rng_state=int(value.rng); turn_count=int(value.turn_count); history=value.history.duplicate(); events=value.events.duplicate()
	refresh_forecast(); return true

func _number(v: Variant) -> bool:
	return (v is int or v is float) and is_finite(float(v))

func _shape_valid(v: Variant,sample: Variant) -> bool:
	if sample is Dictionary:
		if not v is Dictionary: return false
		if sample.is_empty(): return true # Effects are validated above.
		if v.size()!=sample.size(): return false
		for key in sample:
			if key=="effects":
				if not v.get(key) is Dictionary: return false
				continue
			if not v.has(key) or not _shape_valid(v[key],sample[key]): return false
		return true
	if sample is Array: return v is Array
	if sample is bool: return v is bool
	if _number(sample): return _number(v) and (not sample is int or float(v)==floor(float(v)))
	return typeof(v)==typeof(sample)
