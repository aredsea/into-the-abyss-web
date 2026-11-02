extends "res://game/battle_state.gd"
## Web CTB adaptation. Legacy saves keep using battle_state.gd.
var selected_ally=""
var extra_state={}
var action_id=""
var hit_serial=0
var inventory={}
var dungeon_enemy_r21
var last_enemy_hit_target=""
var last_enemy_hit_result={}
const CombatClock=preload("res://game/combat_clock_r22.gd")
var ctb_tick=0
var ctb_round=0
var combat_hits=[]
var r21_action_actor=""
var volley_active=false
var pending_hit_hooks=[]
const CombatEvents=preload("res://game/combat_events_r22.gd")
const CombatDisplay=preload("res://game/combat_display_r22.gd")
var combat_events=CombatEvents.new()
const PersonalRules=preload("res://game/personal_rules_r22.gd")
const TraitRules=preload("res://game/trait_rules_r22.gd")
const GearBattle=preload("res://game/gear_battle_r22.gd")
const PersonaCombat=preload("res://game/persona_combat_r22.gd")
var gear_bridge

func _volley(a: Dictionary,power: float,brk: float) -> void:
	volley_active=true; pending_hit_hooks=[]
	for foe in living(false):
		_damage(a,foe,power,brk)
		if action_id=="ruin" and foe.hp>0:
			_push_class_dot(foe,floor(a.base.int),3,a.id); _effect(foe,"attack_down",3,.15)
	var hooks=pending_hit_hooks; pending_hit_hooks=[]; volley_active=false
	for hook in hooks: _personal_hit_after(hook)

func _trait_event(a: Dictionary,label: String,duration: float=0) -> void:
	combat_events.push("trait",combat_events.slot(self,a),combat_events.T)
	combat_events.T+=duration
	_event(a.name+" · "+label)

func _personal_enemy_down(e: Dictionary) -> void:
	PersonalRules.enemy_down(self,e); TraitRules.enemy_down(self,e)
	if gear_bridge!=null: gear_bridge.invoke("enemy_dead",[gear_bridge.slot(e)])

func _flat_enemy(e: Dictionary,amount: float,a: Dictionary={},fixed=true,record_hit=true,credit=true) -> void:
	if e.hp<=0: return
	var damage=maxi(1,int(floor(amount)))
	if not fixed and e.effects.has("guard"): damage=maxi(1,int(floor(damage*.6)))
	var before=e.hp; var shield=mini(damage,int(fx(e,"shield")))
	if shield>0: e.effects.shield.amount-=shield
	e.hp=maxi(0,e.hp-damage+shield); dungeon_enemy_r21.phase_guard(e,before)
	e.effects.erase("mark")
	if not a.is_empty() and record_hit: _record_hit(a.id,e.id,damage,shield)
	if e.hp<=0:
		_personal_enemy_down(e)
		if not a.is_empty() and credit: TraitRules.kill_credit(self,a)

func _personal_hit_after(h: Dictionary) -> void:
	# B.attack/volley emits its body and advances T before firing hit_after.
	combat_events.finish(self)
	PersonalRules.hit_after(self,h)
	TraitRules.hit_after(self,h)
	_gear_hit_after(h)
	var a=h.a; var e=h.e
	if a.id=="selva" and action_id=="personal" and not h.extra and h.killed: a.mp=mini(a.mmp,a.mp+6)
	# Source volley does not run foe_hit_after or GH.extra_hit.
	if h.volley: return
	dungeon_enemy_r21.after_hit(a,e)
	var extra_chance=sig(a,"as_shadow")[0]/100.0 if not sig(a,"as_shadow").is_empty() else .2
	if gear_bridge!=null:
		gear_bridge.pack(); extra_chance=gear_bridge.hooks.assassin_extra(gear_bridge.st.u[gear_bridge.slot(a)-1],.2)
	if a.hp>0 and a.class_id=="assassin" and (not h.extra or h.get("allow_extra",false)) and e.hp>0 and _roll(extra_chance):
		_damage(a,e,a.skills.attack.power,0,true,-1,{"hit":.25,"duration":.8,"element":h.get("element",a.element)})

func _gear_hit_after(h: Dictionary) -> void:
	if gear_bridge!=null:
		gear_bridge.invoke("hit_after",[gear_bridge.slot(h.a),gear_bridge.slot(h.e),{"d":h.dealt,"kill":1 if h.killed else 0},{},combat_events.T]); return
	var a=h.a
	var frenzy=proc(a,"frenzy")
	if not frenzy.is_empty() and x(a).get("frenzy_action",-1)!=turn_count+1:
		x(a).frenzy_action=turn_count+1
		if _roll(frenzy.p/100.0): _effect(a,"crit_up",int(frenzy.n),frenzy.x/100.0)
	var hunger=sig(a,"gl_hunger")
	if not hunger.is_empty() and a.hp>0: _receive_heal(a,h.dealt*hunger[2]/100.0)

func _gear_kill(a: Dictionary) -> void:
	if gear_bridge!=null:
		gear_bridge.invoke("gear_kill",[gear_bridge.slot(a),combat_events.T]); return
	a.mp=mini(a.mmp,a.mp+int(a.get("gear_fx",{}).get("killmp",0)))
	var chain=proc(a,"chain")
	if not chain.is_empty(): _effect(a,"next_power",4,chain.x/100.0)
	var hunt=sig(a,"as_hunt")
	if not hunt.is_empty() and x(a).get("hunts",0)<hunt[0]: x(a).hunts=x(a).get("hunts",0)+1; x(a).pull=1; _effect(a,"next_power",4,hunt[1]/100.0)
	var shot=sig(a,"ar_chain")
	if not shot.is_empty() and action_id=="snipe": a.mp=mini(a.mmp,a.mp+int(a.skills.snipe.mp*shot[1]/100.0)); x(a).pull=maxf(x(a).get("pull",0),shot[0]/100.0)
	for member in living(true):
		var king=sig(member,"gl_king")
		if king.is_empty(): continue
		x(member).king=mini(int(king[2]),int(x(member).get("king",0))+1); _effect(member,"crit_up",99,x(member).king*king[1]/100.0)
		if member.id==a.id: _receive_heal(a,a.mhp*king[0]/100.0)

func _sorel_aid(a: Dictionary) -> void:
	if a.hp<=0 or a.hp>a.mhp*.25 or not has_alive("sorel"): return
	var o=ally("sorel")
	if x(o).get("rescue",0)>=2: return
	x(o).rescue=x(o).get("rescue",0)+1; _receive_heal(a,o.base[o.line]*2)
func combat_event_trace() -> Dictionary: return combat_events.trace()
func combat_display_schedule(event: Dictionary) -> Array: return CombatDisplay.schedule(event)
func status_chips(u: Dictionary) -> Array: return CombatDisplay.chips(self,u)
func _begin_combat_events(id: String,a: Dictionary,e: Dictionary,t: Dictionary) -> void:
	combat_events=CombatEvents.new()
	combat_events.begin(self,id,a,e,t)

func _record_hit(actor: String,target: String,damage: int,shield: int,critical: bool=false) -> void:
	var all=data.allies+data.enemies
	combat_hits.append({"actor":all.find(unit(actor))+1,"target":all.find(unit(target))+1,"damage":damage,"shield":shield,"critical":critical})

func _roll(chance: float) -> bool:
	if dungeon_enemy_r21==null: return super(chance)
	return dungeon_enemy_r21.random()<chance

func refresh_forecast() -> void:
	if dungeon_enemy_r21==null: super(); return
	if not result.is_empty(): data.queue=[]; return
	var units=data.allies+data.enemies
	data.queue=CombatClock.preview(units,units.map(func(u):return speed(u)),current_id)

func _advance_ctb() -> void:
	dungeon_enemy_r21.phase_check()
	var units=data.allies+data.enemies
	var next=CombatClock.advance(units,units.map(func(u):return speed(u)))
	if next.is_empty(): return
	ctb_tick+=next.ticks
	while ctb_round<int(floor(float(ctb_tick)/100)):
		ctb_round+=1
		_round_tick()
	current_id=units[next.index].id
	_tick(units[next.index])
	if units[next.index].has("mp"): last_ally=current_id
	if not living(false).is_empty() and enemy(selected_enemy).hp<=0: selected_enemy=living(false)[0].id
	selected_action="attack"

func _round_tick() -> void:
	# MP synergy precedes living personal hooks, then the global round hook.
	if living(true).filter(func(a):return a.line=="int").size()>=2:
		for a in living(true):
			if a.line=="int": a.mp=mini(a.mmp,a.mp+4)
	for owner in data.allies:
		if owner.hp<=0: continue
		match owner.id:
			"urda":
				var target=_lowest()
				if not target.is_empty():
					_receive_heal(target,owner.base[owner.line]*2*.35)
					for key in ["attack_down","defense_down"]:
						if target.effects.has(key): target.effects.erase(key); break
			"tove":
				owner.shield=maxi(owner.shield,mini(int(floor(owner.mhp*.3)),owner.shield+int(floor(owner.mhp*.06+.5))))
				_effect(owner,"shield",4)
			"sorel":
				for a in living(true):
					if a.effects.has("sorel_regen"):
						_receive_heal(a,fx(a,"sorel_regen")); a.effects.sorel_regen.turns-=1
						if a.effects.sorel_regen.turns<=0: a.effects.erase("sorel_regen")
			"felice": _felice_scan()
			"judith": _judith_unslow()
			"persona": _persona_round()
			"jorund":
				for e in data.enemies: x(e).jd=0
			"hildegard": _hg_scan()
			"miko":
				var pick={}; var late=-1.0
				for a in living(true):
					if a.id==owner.id: continue
					var wait=float(a.remaining)/speed(a)
					if wait>late: late=wait; pick=a
				if not pick.is_empty(): pick.remaining=maxf(0,pick.remaining-4000)
	if count_tag("race","하프엘프")>=3:
		for a in living(true):
			for key in ["attack_down","defense_down","zdn"]:
				if a.effects.has(key): a.effects.erase(key); break

	# Gear's global round hook also runs while the wall wearer is down.
	for a in (data.allies if gear_bridge==null else []):
		if a.hp<=0 and a.effects.has("wall_party"):
			a.effects.wall_party.turns-=1
			if a.effects.wall_party.turns<=0: a.effects.erase("wall_party")
	if gear_bridge!=null: gear_bridge.invoke("round_end")

func _begin_effect_action(actor: String) -> void:
	r21_action_actor=actor

func set_persona_regen(target: Dictionary,amount: float,rounds: int=2) -> void:
	# P1's persona assembler can call this boundary without owning the clock.
	_effect(target,"persona_regen",rounds,amount)

func _persona_round() -> void:
	for a in living(true):
		if a.effects.has("persona_regen"):
			_receive_heal(a,fx(a,"persona_regen"))
			a.effects.persona_regen.turns-=1
			if a.effects.persona_regen.turns<=0: a.effects.erase("persona_regen")

func _judith_unslow() -> void:
	for e in data.enemies:
		if x(e).has("judith_sp0") and ctb_round>=x(e).get("judith_until",0):
			e.speed=x(e).judith_sp0; x(e).erase("judith_sp0"); x(e).erase("judith_until")

func _init(scene_data: Dictionary={}) -> void:
	super(scene_data)
	if data.is_empty(): return
	inventory=data.get("inventory",{}).duplicate(true)
	current_id=data.allies[0].id; last_ally=current_id; selected_ally=current_id
	for u in data.allies+data.enemies: extra_state[u.id]={}
	if data.has("encounter_r21"):
		dungeon_enemy_r21=preload("res://game/dungeon_enemy_r21.gd").new(self)
		gear_bridge=GearBattle.new(self); gear_bridge.initialize()
		selected_enemy=data.enemies[0].id
		dungeon_enemy_r21.initialize_targets()
	for a in data.allies:
		if a.id=="altan":
			for m in living(true): _shield(m,a.base.int*2,3,dungeon_enemy_r21==null)
	if dungeon_enemy_r21!=null: _start_ctb()
	refresh_forecast()

func _start_ctb() -> void:
	for a in data.allies:
		a.remaining=10000.0
		a.base.spd=floor(a.base.spd+.5)
		if a.id=="tove" and a.hp>0:
			a.shield=mini(int(floor(a.mhp*.3)),a.shield+int(floor(a.mhp*.06+.5)))
			_effect(a,"shield",4)
	_hg_scan()
	if not _check_end(): _advance_ctb()

func _check_end() -> bool:
	if not result.is_empty(): return true
	if living(false).is_empty(): result="victory"
	elif living(true).is_empty() or turn_count>=400: result="defeat"
	if not result.is_empty():
		if dungeon_enemy_r21!=null: combat_events.push("end",0,combat_events.T+.3)
		_event("전투 승리" if result=="victory" else "전투 패배 · 부상으로 이탈")
		data.queue=[]
		return true
	return false

func _hg_scan() -> void:
	if dungeon_enemy_r21==null or not has_alive("hildegard"): return
	var taunted=not living(true).filter(func(a):return a.effects.has("taunt")).is_empty()
	for e in living(false):
		if x(e).get("hg_index",-1)==int(e.act_index): continue
		x(e).hg_index=int(e.act_index); e.redirected=false
		if e.acts[e.act_index].kind in ["atk","shoot","aimed","spell","big_one","big_all"] and not taunted:
			var roll=dungeon_enemy_r21.random()
			if e.target_id!="hildegard" and roll<.35:
				e.target_id="hildegard"; e.redirected=true

func x(u: Dictionary) -> Dictionary:
	return extra_state[u.id]

func fx(u: Dictionary, key: String) -> float:
	return float(u.effects.get(key,{}).get("amount",0))

func sig(u: Dictionary,key: String) -> Array:
	for effect in u.get("gear_special",[]):
		if effect.key==key: return effect.get("v",[])
	return []

func proc(u: Dictionary,key: String) -> Dictionary:
	for effect in u.get("gear_special",[]):
		if effect.key==key and effect.has("p"): return effect
	return {}

func bonus(u: Dictionary,key: String) -> float:
	return u.get("gear_fx",{}).get(key,0)/100.0

func count_tag(key: String,value: String) -> int:
	var n=0
	for a in data.allies:
		if a.hp>0 and a.get(key)==value: n+=1
	return n

func _effect(u: Dictionary,key: String,turns: int,amount: float=0) -> void:
	if gear_bridge!=null and key in ["attack_up","defense_up","haste"] and amount>0:
		gear_bridge.pack(); amount=gear_bridge.hooks.gear_buff(amount)
	if dungeon_enemy_r21!=null and not u.has("base") and u.get("grade")=="boss":
		if key in ["attack_down","defense_down","slow","foxflame"]: amount*=.5
		if key in ["mark","silence"] and not _roll(.5): return
	if u.has("base"):
		if key in (["attack_down","defense_down","zdn"] if dungeon_enemy_r21!=null else ["attack_down","defense_down","slow"]):
			if u.get("race")=="인간": turns=maxi(1,turns-1)
			if u.get("race")=="녹스": amount*=.7
		elif key in (["attack_up","defense_up","backstep","blood","fortified_guard","adeline_guard","contract","duty"] if dungeon_enemy_r21!=null else ["guard","psguard","duty","bless","attack_up","defense_up","contract","blood"]):
			if count_tag("race","하프엘프")>=2: turns+=1
	super(u,key,turns,amount)
	if dungeon_enemy_r21!=null and r21_action_actor==u.id and key not in ["shield","taunt","mark","foxflame","wall_party","regen","sorel_regen","persona_regen"]: u.effects[key].fresh=true

func living(friends: bool) -> Array:
	if not friends: return super(false)
	if dungeon_enemy_r21!=null: return super(true)
	return data.allies.filter(func(a):return a.hp>0 or extra_state.get(a.id,{}).get("reviving",false))

func has_alive(id: String) -> bool:
	return not ally(id).is_empty() and ally(id).hp>0

func cost(id: String) -> int:
	var n=int(actions()[id].mp)
	var a=ally(current_id); var wind=sig(a,"ar_wind")
	if gear_bridge!=null:
		gear_bridge.pack(); n=int(gear_bridge.hooks.gear_mpc(gear_bridge.st.u[gear_bridge.slot(a)-1],{"id":gear_bridge.skill_id(id),"mp":n}))
	elif id=="snipe" and not wind.is_empty(): n=int(round(n*(1-wind[0]/100.0)))
	return maxi(1,int(floor(n*.85+.5+1e-9))) if n>0 and has_alive("lynette") else n

func actions() -> Dictionary:
	var result=super().duplicate(true)
	if result.is_empty(): return result
	if dungeon_enemy_r21!=null and ally(current_id).class_id=="warrior":
		result.guard.name="굳건한 방어"
		result.defend={"name":"방어","mp":0,"target":"자신","power":.4,"turns":1,"brk":0,"note":"다음 자기 차례까지 받는 피해 −40%"}
	for item in data.get("item_defs",[]):
		if item.kind not in ["return","level"]:
			result["item:"+item.id]={"name":item.name,"mp":0,"target":"아군 1","note":"동료를 선택하면 1개와 현재 차례를 소모합니다.","item":item}
	return result

func unavailable(id: String) -> String:
	if not player_turn() or not actions().has(id): return "행동할 수 없음"
	var a=ally(current_id)
	if dungeon_enemy_r21!=null and a.effects.has("silence") and x(a).get("silenced_id","")==id: return "이 차례에 봉인됨"
	if id.begins_with("item:") and inventory.get(id.substr(5),0)<=0: return "보유량 없음"
	if a.charging: return "충전 중"
	if dungeon_enemy_r21!=null and id=="personal" and not PersonalRules.can(self,a): return "사용 조건 미충족"
	if id=="personal" and a.id=="teiris" and a.once: return "이번 전투에서 사용함"
	if (id=="blood" or (id=="personal" and a.id in ["tika","levia"])) and a.hp<=hp_cost(a,id): return "HP 부족"
	return "MP 부족" if a.mp<cost(id) else ""

func hp_cost(a: Dictionary,id: String) -> int:
	var result=int(floor(a.mhp*(.15 if id=="blood" else .1))); var boil=sig(a,"gl_boil")
	if a.get("nation")=="모르가스 신관국": result=maxi(1,int(floor(result*.7)))
	if id=="blood" and gear_bridge!=null:
		gear_bridge.pack(); result=int(gear_bridge.hooks.hp_cost(gear_bridge.st.u[gear_bridge.slot(a)-1],result))
	elif id=="blood" and not boil.is_empty(): result=int(round(result*(1-boil[0]/100.0)))
	return result

func choose_ally(id: String) -> bool:
	if ally(id).is_empty(): return false
	if dungeon_enemy_r21!=null and selected_action=="personal" and current_id=="marceline" and id==current_id: return false
	if ally(id).hp<=0 and selected_action!="item:bandage": return false
	selected_ally=id; return true

func speed(u: Dictionary) -> float:
	if dungeon_enemy_r21!=null:
		var base_speed=float(u.base.spd) if u.has("base") else float(u.speed)
		var mult=1.0
		if u.has("base"):
			var elves=count_tag("race","엘프")
			if elves>=2: mult*=1.02 if elves>=3 else 1.01
			if count_tag("race","수인")>=2: mult*=1.01
			if u.get("nation")=="대카라쉰": mult*=1.01
			if count_tag("nation","대카라쉰")>=3: mult*=1+.01*x(data.allies[0]).get("karashin_kills",0)
			if u.class_id=="gladiator": mult*=1+.08*float(u.hp)/u.mhp
			for a in living(true):
				if a.id!=u.id and a.class_id=="alchemist": mult*=1.06; break
		mult*=1+fx(u,"haste")+fx(u,"windup")+fx(u,"alarm")-fx(u,"slow")
		if not u.has("base") and u.rules.has("hp_spd") and u.hp<=u.mhp*u.rules.hp_spd.thr: mult*=1+u.rules.hp_spd.amount
		mult=maxf(.3,mult)
		return base_speed if mult==1 else floor(base_speed*mult*100+.5)/100
	var result=super(u)*(1-fx(u,"slow"))*(1+fx(u,"haste"))
	if dungeon_enemy_r21!=null and not u.has("base") and u.rules.has("hp_spd") and u.hp<=u.mhp*u.rules.hp_spd.thr: result*=1+u.rules.hp_spd.amount
	if u.has("base"):
		var elves=count_tag("race","엘프"); var beasts=count_tag("race","수인")
		if elves>=2: result*=1.02 if elves>=3 else 1.01
		if beasts>=2: result*=1.01
		if u.get("nation")=="대카라쉰": result*=1.01
		if u.class_id=="gladiator": result*=1+.08*float(u.hp)/u.mhp
		for a in living(true):
			if a.id!=u.id and a.class_id=="alchemist": result*=1.06
	return maxf(1,result)

func _shield(a: Dictionary, amount: float, turns: int, skill_bonus=true) -> void:
	var source=ally(current_id)
	if gear_bridge!=null and skill_bonus and not source.is_empty():
		var modified=gear_bridge.invoke("shield",[gear_bridge.slot(source),amount]); amount=modified if modified!=null else amount
	elif skill_bonus and not source.is_empty():
		amount*=1+bonus(source,"shield")
		var guardian=proc(source,"guardian")
		if not guardian.is_empty() and _roll(guardian.p/100.0): amount*=1+guardian.x/100.0
	a.shield=maxi(a.shield,int(floor(amount))); _effect(a,"shield",turns)

func _heal(a: Dictionary,t: Dictionary,power: float,use_class_line=false) -> void:
	var amount=a.base[a.line if use_class_line else "int"]*2*power
	if a.id=="berenga": amount*=1+.6*(1-float(t.hp)/t.mhp)
	if dungeon_enemy_r21!=null:
		var healed_r21=_receive_heal(t,amount,a)
		_event("%s → %s · HP +%d" % [a.name,t.name,healed_r21])
		return
	amount*=1+a.get("gear_fx",{}).get("heal",0)/100.0
	amount*=1+bonus(t,"healrecv")
	if count_tag("race","인간")>=3: amount*=1.1
	var brew=sig(a,"al_brew")
	if action_id=="heal" and not brew.is_empty(): amount*=1+brew[0]/100.0
	var surplus=maxf(0,amount-(t.mhp-t.hp)); var surge=sig(a,"al_surge")
	if not surge.is_empty() and surplus>0: _shield(t,minf(t.mhp*.5,surplus*surge[0]/100.0),int(surge[1]))
	var healed=mini(t.mhp-t.hp,int(floor(amount))); t.hp+=healed
	_event("%s → %s · HP +%d" % [a.name,t.name,healed])
	if a.id=="miko": _effect(t,"next_power",4,.6)
	if a.id=="adeline": _effect(t,"regen",3,a.base.int*2*.08)
	var haste=proc(a,"heal_haste")
	if not haste.is_empty() and not x(a).get("haste_done",false) and _roll(haste.p/100.0):
		x(a).haste_done=true
		for member in living(true): member.remaining=maxf(0,member.remaining-10000*haste.x/100.0)

func _receive_heal(t: Dictionary,amount: float,skill_source: Dictionary={}) -> int:
	# B.heal + GH.heal: raw heals have no skill caster bonus or skill procs.
	if t.hp<=0: return 0
	if count_tag("race","인간")>=3: amount*=1.1
	if gear_bridge!=null:
		var old_act=gear_bridge.hooks.act; var old_skill=gear_bridge.hooks.skill
		if not skill_source.is_empty(): gear_bridge.hooks.act=gear_bridge.slot(skill_source); gear_bridge.hooks.skill=old_skill if old_skill!=null else true
		var modified=gear_bridge.invoke("heal_amount",[gear_bridge.slot(t),amount]); amount=modified if modified!=null else amount
		gear_bridge.hooks.act=old_act; gear_bridge.hooks.skill=old_skill
		var healed=mini(t.mhp-t.hp,maxi(0,int(floor(amount+.5+1e-9)))); t.hp+=healed
		return healed
	if not skill_source.is_empty():
		amount*=1+bonus(skill_source,"heal")
		var haste=proc(skill_source,"heal_haste")
		if amount>0 and not haste.is_empty() and not x(skill_source).get("haste_done",false):
			x(skill_source).haste_done=true
			if _roll(haste.p/100.0):
				for member in living(true): member.remaining=maxf(0,member.remaining-10000*haste.x/100.0)
	amount*=1+bonus(t,"healrecv")
	var rounded=int(floor(amount+.5))
	if not skill_source.is_empty():
		var surge=sig(skill_source,"al_surge")
		if not surge.is_empty():
			var over=maxi(0,t.hp+rounded-t.mhp)
			var shield=mini(int(floor(over*surge[0]/100.0)),maxi(0,int(floor(t.mhp*.5))-t.shield))
			if shield>0:
				t.shield+=shield; _effect(t,"shield",maxi(int(surge[1]),int(t.effects.get("shield",{}).get("turns",0))))
	var healed=mini(t.mhp-t.hp,maxi(0,rounded)); t.hp+=healed
	return healed

func _source_effect(u: Dictionary,key: String,turns: int,amount: float,source: String) -> void:
	_effect(u,key,turns,amount)
	if dungeon_enemy_r21!=null: u.effects[key].source=source

func _dot_metadata(e: Dictionary) -> Dictionary:
	var effect=e.effects.get("dot",{}).duplicate(true)
	var stacks=effect.get("stacks",[])
	if stacks.is_empty() and effect.get("amount",0)>0:
		var cap=6 if count_tag("nation","모르가스 신관국")>=3 else 5
		var count=clampi(int(x(e).get("dot_stacks",1)),1,cap)
		for i in range(count): stacks.append(float(effect.amount)/count)
	effect.stacks=stacks
	for key in ["lifetimes","owners","bursts","initial_turns","orders"]:
		if not effect.has(key):
			effect[key]=[]
			for i in range(stacks.size()): effect[key].append(x(e).get("dot_owner","") if key=="owners" else 0 if key in ["bursts","orders"] else int(effect.get("turns",1)))
	return effect

func _next_dot_order() -> int:
	var shared=x(data.allies[0]); shared.dot_order=int(shared.get("dot_order",0))+1
	return shared.dot_order

func _store_class_dot(e: Dictionary,effect: Dictionary) -> void:
	x(e).dot_stacks=effect.stacks.size()
	if effect.stacks.is_empty(): e.effects.erase("dot"); return
	effect.amount=0.0; effect.turns=0
	for i in range(effect.stacks.size()):
		effect.amount+=effect.stacks[i]; effect.turns=maxi(effect.turns,int(effect.lifetimes[i]))
	e.effects.dot=effect

func _push_class_dot(e: Dictionary,amount: float,turns: int,owner: String) -> void:
	var effect=_dot_metadata(e); var caster=ally(owner)
	var cap=6 if count_tag("nation","모르가스 신관국")>=3 else 5
	while effect.stacks.size()>=cap:
		for key in ["stacks","lifetimes","owners","bursts","initial_turns","orders"]: effect[key].pop_front()
	var gear_dot=[]
	if gear_bridge!=null and not caster.is_empty(): gear_dot=gear_bridge.invoke("gear_dot",[gear_bridge.slot(caster),amount]); amount=gear_dot[0]
	elif not caster.is_empty() and bonus(caster,"dot")!=0: amount=floor(amount*(1+bonus(caster,"dot"))+.5)
	var burst=proc(caster,"dot_burst") if not caster.is_empty() else {}
	effect.stacks.append(amount); effect.lifetimes.append(turns); effect.owners.append(owner)
	effect.bursts.append((gear_dot[1] if gear_dot[1]!=null else 0) if not gear_dot.is_empty() else burst.get("x",0)); effect.initial_turns.append(turns)
	effect.orders.append(_next_dot_order())
	_store_class_dot(e,effect); x(e).dot_owner=owner
	if caster.is_empty(): return
	if gear_bridge!=null:
		gear_bridge.invoke("gear_dotchain",[gear_bridge.slot(e),gear_bridge.slot(caster)]); return
	var chain=sig(caster,"un_chain")
	if not chain.is_empty() and e.hp>0 and effect.stacks.size()>=chain[0]:
		var pending=0.0
		for i in range(effect.stacks.size()): pending+=effect.stacks[i]*effect.lifetimes[i]
		for key in ["corrosion","bleed"]: pending+=fx(e,key)*e.effects.get(key,{}).get("turns",0)
		var damage=int(floor(pending*(1+chain[1]/100.0)))
		for key in ["dot","corrosion","bleed"]: e.effects.erase(key)
		x(e).dot_stacks=0
		var before=e.hp
		_incoming_strike(e,damage,{}, {"name":"연쇄 폭발"})
		dungeon_enemy_r21.phase_guard(e,before)
		if e.hp<=0: TraitRules.kill_credit(self,caster)

func _tick_enemy_dots(e: Dictionary) -> void:
	var sum=0.0; var owners=[]; var kill_owner=""; var latest=-1
	if e.effects.has("dot"):
		var effect=_dot_metadata(e)
		for i in range(effect.stacks.size()-1,-1,-1):
			if effect.orders[i]>latest: latest=int(effect.orders[i]); kill_owner=effect.owners[i]
			sum+=effect.stacks[i]; owners.append(effect.owners[i]); effect.lifetimes[i]-=1
			if effect.lifetimes[i]<=0:
				sum+=gear_bridge.hooks.dot_expiry({"d":effect.stacks[i],"n0":effect.initial_turns[i],"bu":effect.bursts[i],"n":0}) if gear_bridge!=null else floor(effect.stacks[i]*effect.initial_turns[i]*effect.bursts[i]/100.0)
				for key in ["stacks","lifetimes","owners","bursts","initial_turns","orders"]: effect[key].remove_at(i)
		_store_class_dot(e,effect)
	for key in ["corrosion","bleed"]:
		if e.effects.has(key):
			var effect=e.effects[key]; var owner=effect.get("by","")
			if not owner.is_empty():
				owners.append(owner)
				if effect.get("order",0)>latest: latest=int(effect.get("order",0)); kill_owner=owner
			sum+=fx(e,key); e.effects[key].turns-=1
			if e.effects[key].turns<=0: e.effects.erase(key)
	if sum<=0: return
	if count_tag("nation","모르가스 신관국")>=2: sum=floor(sum*1.1+.5)
	var before=e.hp
	_incoming_strike(e,sum,{}, {"name":"지속 피해"})
	combat_events.push("dot",combat_events.slot(self,e),combat_events.T,[combat_events.slot(self,e)]); combat_events.T+=.9
	dungeon_enemy_r21.phase_guard(e,before)
	if gear_bridge!=null:
		var wb=[]
		for id in owners:
			if not ally(id).is_empty(): wb.append(gear_bridge.slot(ally(id)))
		gear_bridge.invoke("gear_dottick",[wb,combat_events.T-.9])
	if e.hp<=0 and not kill_owner.is_empty(): TraitRules.kill_credit(self,ally(kill_owner))
	if gear_bridge!=null: return
	var seen=[]
	for id in owners:
		if id in seen: continue
		seen.append(id); var owner=ally(id)
		if owner.is_empty() or owner.hp<=0: continue
		var blood=sig(owner,"un_blood")
		if not blood.is_empty():
			owner.mp=mini(owner.mmp,owner.mp+int(blood[0])); _effect(owner,"next_power",99,minf(fx(owner,"next_power")+blood[1]/100.0,blood[1]*blood[2]/100.0))

func _ally_down(a: Dictionary) -> void:
	# GH.ally_down refreshes live synergies (count_tag reads HP dynamically),
	# then dot_trim removes the oldest class stacks, never corrosion/bleed.
	var cap=6 if count_tag("nation","모르가스 신관국")>=3 else 5
	for e in living(false):
		if e.effects.has("dot") and e.effects.dot.has("stacks"):
			var stacks=e.effects.dot.stacks
			while stacks.size()>cap:
				stacks.pop_front()
				for key in ["lifetimes","owners","bursts","initial_turns","orders"]:
					if e.effects.dot.has(key): e.effects.dot[key].pop_front()
			e.effects.dot.amount=0.0
			for amount in stacks: e.effects.dot.amount+=amount
			x(e).dot_stacks=stacks.size()
	a.effects.erase("taunt"); a.effects.erase("shield"); a.charging=false; x(a).cover=""; a.shield=0
	# B.drop_src(false) visits every unit and every source-tagged buff.
	for u in data.allies+data.enemies:
		for key in u.effects.keys():
			if u.effects[key].get("source","")==a.id: u.effects.erase(key)
	# Adeline regen carries the same caster in this model, so it is removed
	# above as well (the canonical damaged wrapper clears x.areg separately).

func _cleanse(t: Dictionary) -> void:
	for key in ["attack_down","defense_down","slow","dot","corrosion","bleed","enemy_dot_0","enemy_dot_1","enemy_dot_2","enemy_dot_3"]:
		if t.effects.has(key): t.effects.erase(key); return

func _lowest() -> Dictionary:
	var list=living(true); var t=list[0]
	for a in list:
		if float(a.hp)/a.mhp<float(t.hp)/t.mhp: t=a
	return t

func _behind(t: Dictionary) -> Dictionary:
	if t.row=="전열":
		for e in living(false):
			if e.id!=t.id and e.row=="후열": return e
	for e in living(false):
		if e.id!=t.id: return e
	return {}

func _tick(u: Dictionary) -> void:
	if dungeon_enemy_r21!=null:
		if not u.has("base"): combat_hits=[]
		dungeon_enemy_r21.drop_auras()
		if u.has("base"):
			# begin_turn runs before edot_tick, including expiry of taunt.
			if u.effects.has("fortified_guard"): _effect(u,"guard",99,.4)
			else: u.effects.erase("guard")
			if u.effects.has("taunt"):
				u.effects.taunt.turns-=1
				if u.effects.taunt.turns<=0: u.effects.erase("taunt")
			u.mp=mini(u.mmp,u.mp+int(data.formula.mp_regen))
			if gear_bridge!=null: gear_bridge.invoke("gear_begin",[gear_bridge.slot(u)])
		if not u.has("base") and u.effects.get("guard",{}).get("r21",false): u.effects.erase("guard")
		var dot_damage=0
		for i in range(4):
			var key="enemy_dot_%d"%i
			if u.effects.has(key):
				dot_damage+=int(u.effects[key].amount); u.effects[key].turns-=1
				if u.effects[key].turns<=0: u.effects.erase(key)
		if dot_damage>0:
			# edot_tick uses one fixed strike: skip attack/evade, retain damage hooks.
			_incoming_strike(u,dot_damage,{}, {"name":"지속 피해"},false,true)
			combat_events.push("adot",combat_events.slot(self,u),combat_events.T,[combat_events.slot(self,u)]); combat_events.T+=.9
			if u.hp<=0: return # B.run skips end_turn and every subsequent heal.
	if dungeon_enemy_r21==null and x(u).get("reviving",false): u.hp=maxi(1,int(u.mhp*.25)); x(u).reviving=false; _event(u.name+" · 응급 소생")
	if dungeon_enemy_r21!=null and not u.has("base"): _tick_enemy_dots(u)
	for key in ["dot","corrosion","bleed"]:
		if dungeon_enemy_r21==null and fx(u,key)>0:
			u.hp=maxi(0,u.hp-int(floor(fx(u,key)))); _event("%s · 지속 피해 %d" % [u.name,fx(u,key)])
			var owner=ally(x(u).get("dot_owner",""))
			if not owner.is_empty() and owner.hp>0:
				var blood=sig(owner,"un_blood")
				if not blood.is_empty(): owner.mp=mini(owner.mmp,owner.mp+int(blood[0])); _effect(owner,"next_power",99,minf(fx(owner,"next_power")+blood[1]/100.0,blood[1]*blood[2]/100.0))
				var burst=proc(owner,"dot_burst")
				if not burst.is_empty() and u.effects[key].turns==1: u.hp=maxi(0,u.hp-int(fx(u,key)*burst.x/100.0))
	if u.has("base"):
		if dungeon_enemy_r21==null:
			u.mp=mini(u.mmp,u.mp+int(u.get("gear_fx",{}).get("mpreg",0)))
			var th=proc(u,"taunt_heal")
			if not th.is_empty() and u.effects.has("taunt"): u.hp=mini(u.mhp,u.hp+int(u.mhp*th.x/100.0))
		if dungeon_enemy_r21==null and fx(u,"regen")>0: u.hp=mini(u.mhp,u.hp+int(floor(fx(u,"regen"))))
		if dungeon_enemy_r21==null and u.id=="tove": u.shield=mini(int(u.mhp*.3),u.shield+int(u.mhp*.06))
		if dungeon_enemy_r21==null and u.id=="urda" and not living(true).is_empty():
			var t=_lowest(); _heal(u,t,.175); _cleanse(t)
		if dungeon_enemy_r21==null and u.id=="erdene" and u.effects.get("taunt",{}).get("turns",0)==1:
			u.hp=mini(u.mhp,u.hp+int(x(u).get("prevented",0)*.25)); x(u).prevented=0
	# r21 buffs tick at the owner turn end; legacy saves retain start ticks.
	if dungeon_enemy_r21==null: super(u)
	if dungeon_enemy_r21!=null and not u.has("base"):
		dungeon_enemy_r21.phase_guard(u)
		var old_phase=u.phase
		dungeon_enemy_r21.phase_check()
		if old_phase!=u.phase: u.remaining=0.0

func _damage(a: Dictionary,e: Dictionary,power: float,brk: float,extra=false,source_crit_roll: float=-1,proc_event: Dictionary={}) -> void:
	if e.hp<=0: return
	if dungeon_enemy_r21!=null and not volley_active and not proc_event.get("redirected",false): e=dungeon_enemy_r21.protector(e)
	var gear=a.get("gear_fx",{}) if gear_bridge==null else {}
	var chance=(a.base.crit+a.get("combat_ag",a.base.agi)/20.0+a.passive.get("crit",0)+a.trait.p.get("crit",0)+gear.get("crit",0))/100.0
	if dungeon_enemy_r21!=null and a.class_id=="gladiator": chance-=a.passive.get("crit",0)/100.0
	if a.class_id=="gladiator": chance+=.08*float(a.hp)/a.mhp
	if action_id=="snipe" and not extra:
		if gear_bridge!=null:
			gear_bridge.pack(); chance=gear_bridge.hooks.snipe_crit(gear_bridge.st.u[gear_bridge.slot(a)-1])/100
		else: chance=sig(a,"ar_wind")[1]/100.0 if not sig(a,"ar_wind").is_empty() else .7
	if a.effects.has("blood"): chance+=.3
	chance+=fx(a,"crit_up")+fx(a,"pscrit")
	if gear_bridge!=null: chance+=gear_bridge.invoke("crit",[gear_bridge.slot(a),gear_bridge.slot(e),{},0])/100
	if a.get("lineage") in ["고양이","표범","고양이과"]:
		if not x(a).has("first_attack_action"): x(a).first_attack_action=turn_count+1
		if x(a).first_attack_action==turn_count+1: chance+=.15
	# B.hit always consumes one roll, including a marked guaranteed critical.
	var crit_roll=source_crit_roll
	if dungeon_enemy_r21!=null and crit_roll<0: crit_roll=dungeon_enemy_r21.random()
	var critical=e.effects.has("mark") or (crit_roll<minf(1,chance) if crit_roll>=0 else _roll(minf(1,chance)))
	critical_this_action=critical_this_action or critical
	e.effects.erase("mark")
	var mult=1+fx(a,"bless")+fx(a,"attack_up")+fx(a,"next_power")+gear.get("dmg",0)/100.0
	if dungeon_enemy_r21!=null: mult-=fx(a,"attack_down")
	if a.line=="int": mult*=1+fx(a,"magic_amp"); a.effects.erase("magic_amp")
	if a.get("race")=="엘프" and a.line=="int": mult*=1.03
	if a.get("race")=="악마" and a.hp<=a.mhp*.3: mult*=1.12
	if a.get("nation")=="솔렌 성왕국" and ((dungeon_enemy_r21==null and e.id=="executor") or e.get("grade","") in ["elite","boss","chief","core"]): mult*=1.03
	if (ctb_round==0 and count_tag("nation","대카라쉰")==2) if dungeon_enemy_r21!=null else (a.actions==0 and count_tag("nation","대카라쉰")>=2): mult*=1.03
	var shared=x(data.allies[0])
	if a.get("lineage") in ["개","여우","늑대","개과"] and shared.get("last_target")==e.id and shared.get("last_attacker")!=a.id: mult*=1.08
	if dungeon_enemy_r21==null: shared.last_target=e.id
	for member in (living(true) if gear_bridge==null else []):
		var pd=proc(member,"party_dmg")
		if not pd.is_empty(): mult*=1+pd.x/100.0
	if gear_bridge==null:
		if (dungeon_enemy_r21==null and e.id=="executor") or e.get("grade","") in ["elite","boss","chief","core"]: mult*=1+bonus(a,"elite")
		if a.hp<=a.mhp*.3: mult*=1+bonus(a,"lowhp")
		if a.shield>0: mult*=1+bonus(a,"shdmg")
		if a.actions==0: mult*=1+bonus(a,"first")
	var wrath=sig(a,"pa_wrath"); var high=sig(a,"ar_high"); var hunger=sig(a,"gl_hunger"); var comp=sig(a,"sa_comp")
	if gear_bridge==null:
		if not wrath.is_empty() and a.shield>0: mult*=1+wrath[0]/100.0
		if not high.is_empty() and a.row=="후열": mult*=1+high[0]/100.0
		if not hunger.is_empty() and a.hp<=a.mhp*hunger[0]/100.0: mult*=1+hunger[1]/100.0
		if not comp.is_empty() and (action_id=="burst" or (action_id=="personal" and a.id=="teiris")): mult*=1+comp[0]/100.0
	if e.broken and gear_bridge==null:
		var resonance=proc(a,"abyss_res"); var rift=sig(a,"ch_rift"); var full=sig(a,"ch_full")
		if not resonance.is_empty(): mult*=1+resonance.x/100.0
		if not rift.is_empty(): mult*=1+rift[1]/100.0
		if not full.is_empty(): mult*=full[0]/2.5*(full[1] if action_id=="chaoswave" else 1)
	if a.class_id=="gladiator": mult*=1+.2*float(a.hp)/a.mhp
	if a.id=="ornel" and float(e.hp)/e.mhp>=.7: mult*=1.6
	if a.id=="tove" and a.shield>0: mult*=1.35
	if a.id=="gunhild":
		if x(a).get("streak_action",-1)!=turn_count+1:
			x(a).streak_action=turn_count+1; x(a).streak=int(x(a).get("streak",0))+1 if x(a).get("target")==e.id else 0; x(a).target=e.id
		mult*=1+minf(.5,x(a).get("streak",0)*.05)
	if a.id=="bianca" and action_id=="personal" and not extra and (e.effects.has("attack_down") or e.effects.has("defense_down") or e.effects.has("dot") or e.effects.has("corrosion") or e.effects.has("bleed") or e.effects.has("foxflame")): mult*=1.4
	if a.id=="bargut" and action_id=="personal" and not extra:
		var fastest=true
		for u in living(true)+living(false):
			if (u.base.spd if u.has("base") else u.speed)>a.base.spd: fastest=false
		if fastest: mult*=1.5
	if a.id=="jorund" and action_id=="personal" and not extra and proc_event.get("jmk",x(e).get("jm",false)): mult*=1.4
	if a.id=="lavinia" and action_id=="personal" and not extra and (e.acts[e.act_index].get("ic","") in ["spell","weaken","summon"] or e.acts[e.act_index].kind in ["spell","weaken","summon"]): mult*=1.3
	if a.id=="bianca" and e.get("grade","") in ["boss","chief","core"]: mult*=1.3
	if dungeon_enemy_r21!=null: mult*=PersonalRules.damage_mult(self,a)
	var weak=proc_event.get("element",a.element) in e.weak
	var defense=e.defense*(1+fx(e,"defense_up")-fx(e,"defense_down")) if dungeon_enemy_r21!=null else e.defense*(1-fx(e,"defense_down"))
	var n=e.level-1
	var k=data.formula.def_k_ratio*data.formula.def_std_base*(1+data.def_curve.a*n+data.def_curve.b*n*n)
	var damage=a.base[a.line]*2*power*mult*k/(k+defense)*(1+fx(e,"foxflame"))
	if dungeon_enemy_r21!=null: damage*=dungeon_enemy_r21.defense(a,e)
	if weak: damage*=1.3
	if e.broken: damage*=2.5 if a.class_id=="chaos" else 1.5
	if e.broken and a.id=="levia": damage*=PersonalRules.levia_mult(self) if dungeon_enemy_r21!=null else 1+.3*(data.enemies.size()-living(false).size())/maxf(1,data.enemies.size()-1)
	if gear_bridge!=null:
		var old_skill=gear_bridge.hooks.skill; gear_bridge.hooks.skill=null
		damage=gear_bridge.invoke("deal",[gear_bridge.slot(a),gear_bridge.slot(e),damage,[],{"k":"burst" if volley_active and (action_id=="burst" or (action_id=="personal" and a.id=="teiris")) else "atk","name":"혼돈 파동" if action_id=="chaoswave" else ""}])
		gear_bridge.hooks.skill=old_skill
	if critical:
		var crit_bonus=gear.get("critdmg",0)/100.0
		if gear_bridge!=null:
			gear_bridge.pack(); crit_bonus=gear_bridge.hooks.crit_damage(gear_bridge.st.u[gear_bridge.slot(a)-1],0)
		elif not sig(a,"as_vital").is_empty(): crit_bonus+=sig(a,"as_vital")[0]/100.0
		damage*=(2.0 if action_id=="snipe" and not extra else 1.5)+(.5 if a.effects.has("blood") else 0)+crit_bonus
	if not extra and gear_bridge==null: damage+=x(a).get("scar",0)+x(a).get("charge_damage",0); x(a).scar=0; x(a).charge_damage=0
	if not extra:
		if dungeon_enemy_r21==null: damage+=x(a).get("overheal",0); x(a).overheal=0
		a.effects.erase("next_power")
	var before=int(e.hp); var shield_before=fx(e,"shield"); var dealt=maxi(1,int(floor(damage+(1e-9 if dungeon_enemy_r21!=null else 0))))
	if dungeon_enemy_r21!=null and e.effects.has("guard"): dealt=maxi(1,int(floor(dealt*.6+1e-9)))
	e.hp=maxi(0,e.hp-dealt)
	if dungeon_enemy_r21!=null:
		var shield=mini(dealt,int(fx(e,"shield")))
		if shield>0: e.effects.shield.amount-=shield; e.hp=mini(e.mhp,e.hp+shield)
		_record_hit(a.id,e.id,dealt,shield,critical)
		dungeon_enemy_r21.phase_guard(e,before)
	if proc_event.get("capture_result",false):proc_event.primary_kill=e.hp<=0
	_event("%s → %s · %d 피해%s" % [a.name,e.short,dealt," · 치명" if critical else ""])
	var abyss=brk*(1.5 if weak else 1.0)*(1+gear.get("abyss",0)/100.0)
	if gear_bridge==null and not sig(a,"ch_rift").is_empty(): abyss*=1+sig(a,"ch_rift")[0]/100.0
	var was_broken=e.broken
	if a.id=="levia": abyss*=PersonalRules.levia_mult(self) if dungeon_enemy_r21!=null else 1+.3*(data.enemies.size()-living(false).size())/maxf(1,data.enemies.size()-1)
	if gear_bridge!=null:
		var modified=gear_bridge.invoke("abyss_mul",[gear_bridge.slot(a),gear_bridge.slot(e),abyss]); abyss=modified if modified!=null else abyss
	_break(e,abyss)
	if gear_bridge!=null and not was_broken and e.hp>0 and brk>0:
		gear_bridge.invoke("abyss_after",[gear_bridge.slot(a),gear_bridge.slot(e),abyss,combat_events.T,[]])
	if gear_bridge==null and not was_broken and e.broken and not sig(a,"ch_void").is_empty():
		var v=sig(a,"ch_void"); a.mp=mini(a.mmp,a.mp+int(a.mmp*v[0]/100.0)); x(a).pull=maxf(x(a).get("pull",0),v[1]/100.0)
	if a.id=="levia" and brk>0 and e.hp>0 and not was_broken:
		for other in living(false):
			if other.id!=e.id: _break(other,floor(floor(abyss+.5)*.07+.5))
	if dungeon_enemy_r21!=null:
		if proc_event.has("hit"):
			combat_events.push("atk",combat_events.slot(self,a),combat_events.T,[combat_events.slot(self,e)],combat_events.T+proc_event.hit)
			combat_events.T+=proc_event.duration
		if before>0 and e.hp<=0: _personal_enemy_down(e)
		var hook={"a":a,"e":e,"power":power,"brk":brk,"extra":extra,"critical":critical,"dealt":dealt,"before":before,"shield_before":shield_before,"volley":volley_active,"killed":e.hp<=0}
		hook.element=proc_event.get("element",a.element)
		hook.allow_extra=proc_event.get("allow_extra",false)
		if volley_active: pending_hit_hooks.append(hook)
		else: _personal_hit_after(hook)
		return
	if a.class_id=="sanctioned" and action_id in ["attack","burst"] and e.hp>0:
		var delay=800.0; var warp=sig(a,"sa_warp")
		if not warp.is_empty(): delay=100*warp[0]; x(a).pull=maxf(x(a).get("pull",0),warp[0]*warp[2]/10000.0)
		e.remaining+=delay*(.5 if dungeon_enemy_r21!=null and e.grade=="boss" else 1.0)
	if a.class_id=="unsanctioned" and (dungeon_enemy_r21==null or (action_id=="attack" and e.hp>0)):
		var dot=(maxf(1,floor(a.base.int*.24)) if dungeon_enemy_r21!=null else a.base.int*.24)*(1+bonus(a,"dot") if dungeon_enemy_r21==null else 1)
		if dungeon_enemy_r21==null and not sig(a,"un_seep").is_empty(): dot*=1+sig(a,"un_seep")[0]/100.0
		if dungeon_enemy_r21!=null:
			_push_class_dot(e,dot,3,a.id)
		else:
			_effect(e,"dot",4,minf(fx(e,"dot")+dot,dot*5)); x(e).dot_stacks=int(x(e).get("dot_stacks",0))+1
		x(e).dot_owner=a.id
		var chain=sig(a,"un_chain")
		if dungeon_enemy_r21==null and not chain.is_empty() and x(e).dot_stacks>=chain[0]:
			e.hp=maxi(0,e.hp-int(fx(e,"dot")*3*(1+chain[1]/100.0))); e.effects.erase("dot"); x(e).dot_stacks=0
	if a.id=="naran": _effect(e,"foxflame",3,.6)
	if a.id=="judith": _effect(e,"corrosion",2,minf(fx(e,"corrosion")+a.base.int*1.5,a.base.int*4.5))
	if a.id=="colette":
		for other in living(false): _effect(other,"attack_down",2,.15)
	if a.id=="jorund":
		var stacks=int(x(e).get("bleed_stacks",0))+1
		if stacks>=3:
			e.hp=maxi(0,e.hp-int(a.base.agi*.2*3*3*1.5)); e.effects.erase("bleed"); stacks=0; e.remaining+=1800
		else: _effect(e,"bleed",3,a.base.agi*.2*stacks); e.remaining+=500
		x(e).bleed_stacks=stacks
	if a.id=="selva":
		var leech=int(mini(dealt,before)*.3); x(a).overheal=maxi(0,leech-(a.mhp-a.hp)); a.hp=mini(a.mhp,a.hp+leech)
	if a.id=="bianca" and e.hp>0 and e.hp<=e.mhp*.25 and e.get("grade","") not in ["boss","chief","core"]:
		e.hp=0; x(a).pull=.5; _event("손절 타이밍 · 처형")
	if e.hp==0:
		var demons=count_tag("race","악마")
		if demons>=2: a.hp=mini(a.mhp,a.hp+int(a.mhp*.03))
		if demons>=3:
			for member in living(true): member.mp=mini(member.mmp,member.mp+2)
		a.mp=mini(a.mmp,a.mp+int(gear.get("killmp",0)))
		var chain=proc(a,"chain")
		if not chain.is_empty(): _effect(a,"next_power",4,chain.x/100.0)
		var hunt=sig(a,"as_hunt")
		if not hunt.is_empty() and x(a).get("hunts",0)<hunt[0]: x(a).hunts=x(a).get("hunts",0)+1; x(a).pull=1; _effect(a,"next_power",4,hunt[1]/100.0)
		var chain_shot=sig(a,"ar_chain")
		if not chain_shot.is_empty() and action_id=="snipe": a.mp=mini(a.mmp,a.mp+int(a.skills.snipe.mp*chain_shot[1]/100.0)); x(a).pull=maxf(x(a).get("pull",0),chain_shot[0]/100.0)
		for member in living(true):
			var king=sig(member,"gl_king")
			if king.is_empty(): continue
			x(member).king=mini(int(king[2]),int(x(member).get("king",0))+1); _effect(member,"crit_up",99,x(member).king*king[1]/100.0)
			if member.id==a.id: a.hp=mini(a.mhp,a.hp+int(a.mhp*king[0]/100.0))
		if a.id=="selva" and action_id=="personal": a.mp=mini(a.mmp,a.mp+6)
		if fx(e,"corrosion")>0:
			for other in living(false): _effect(other,"corrosion",2,fx(e,"corrosion"))
	if dungeon_enemy_r21!=null and not volley_active: _hg_scan()
	if not extra:
		var frenzy=proc(a,"frenzy")
		if not frenzy.is_empty() and _roll(frenzy.p/100.0): _effect(a,"crit_up",int(frenzy.n),frenzy.x/100.0)
		if not hunger.is_empty(): a.hp=mini(a.mhp,a.hp+int(mini(before,dealt)*hunger[2]/100.0))
		if a.id=="gerda" and action_id!="personal":
			var behind=_behind(e)
			if not behind.is_empty(): _damage(a,behind,power*.6,0,true)
			elif e.hp>0: _damage(a,e,power*.3,0,true)
		if a.class_id=="assassin" and e.hp>0 and _roll(sig(a,"as_shadow")[0]/100.0 if not sig(a,"as_shadow").is_empty() else .2): _damage(a,e,1,0,true)
		if a.id=="lavinia" and e.hp>0 and _roll(.5): _damage(a,e,power*.7,0,true)
		if a.id=="tika":
			for i in range(2):
				if e.hp>0 and _roll(.3): _damage(a,e,power,0,true)
				else: break
		elif count_tag("race","수인")>=3 and e.hp>0 and _roll(.04): _damage(a,e,power,0,true)
	if dungeon_enemy_r21!=null: dungeon_enemy_r21.after_hit(a,e)

func _break(e: Dictionary,amount: float) -> void:
	if dungeon_enemy_r21==null: super(e,amount); return
	if e.hp<=0 or e.broken or amount<=0: return
	amount=maxf(1,floor(amount+.5+1e-9))
	e.gauge=maxf(0,e.gauge-amount)
	if e.gauge>0: return
	e.broken=true; dungeon_enemy_r21.drop_auras()
	combat_events.push("deplete",combat_events.slot(self,e),combat_events.abyss_time(maxi(0,combat_hits.size()-1)))
	_event("%s · 고갈 · 다음 행동 취소"%e.short)

func act(id: String) -> bool:
	if not unavailable(id).is_empty(): return false
	var a=ally(current_id); var sk=actions()[id]; var e=enemy(selected_enemy)
	var t=ally(selected_ally)
	if id.begins_with("item:"): return _use_supply(sk.item,t)
	if sk.target=="아군 1" and (t.is_empty() or t.hp<=0): return false
	if dungeon_enemy_r21!=null and id=="personal" and a.id=="marceline" and t.id==a.id: return false
	if sk.target.begins_with("적") and living(false).is_empty(): return false
	events=[]; critical_this_action=false; action_id=id; selected_action=id
	if dungeon_enemy_r21!=null: _begin_effect_action(a.id)
	combat_hits=[]
	if dungeon_enemy_r21!=null: dungeon_enemy_r21.begin_random(turn_count+1)
	x(a).haste_done=false
	if dungeon_enemy_r21!=null: _begin_combat_events(id,a,e,t)
	var paid=cost(id)
	if gear_bridge!=null: gear_bridge.invoke("first_action",[gear_bridge.slot(a)])
	a.mp-=paid
	if gear_bridge!=null:
		if paid>0: gear_bridge.invoke("gear_echo",[gear_bridge.slot(a),paid])
		gear_bridge.hooks.act=gear_bridge.slot(a); gear_bridge.hooks.skill=gear_bridge.skill_id(id)
	else:
		var echo=proc(a,"echo")
		if sk.mp>0 and not echo.is_empty() and _roll(echo.p/100.0): a.mp=mini(a.mmp,a.mp+int(paid*echo.x/100.0))
	_event(a.name+" · "+sk.name)
	match id:
		"tactic": _tactic(a,e,t,sk)
		"personal":
			if a.id=="persona" and sk.has("persona_skill"): PersonaCombat.run(self,a,e,t,sk)
			else: _personal(a,e,t,sk)
		"attack","snipe","rift":
			var brk=sk.brk*(1.5 if id=="rift" and a.effects.has("rift_charge") else 1.0)
			_damage(a,e,sk.power,brk)
			if id=="rift": a.effects.erase("rift_charge")
		"chaoswave":
			_volley(a,sk.power,sk.brk*(1.5 if a.effects.has("rift_charge") else 1))
			a.effects.erase("rift_charge")
		"guard","defend":
			if dungeon_enemy_r21!=null:
				_effect(a,"guard",99,.4)
				if id=="guard" and sk.mp>0: _effect(a,"fortified_guard",2,1)
			else: _effect(a,"guard",sk.turns,sk.power)
		"taunt","ptaunt": _effect(a,"taunt",2); PersonalRules.abyss(self,a,e,sk.brk)
		"burst":
			a.charging=true
			if gear_bridge!=null: gear_bridge.invoke("warp",[gear_bridge.slot(a),gear_bridge.slot(e),true,.5 if e.grade=="boss" else 1,2500])
			else:
				var warp=sig(a,"sa_warp"); var delay=2500.0 if warp.is_empty() else warp[1]*100.0
				e.remaining+=delay
				if not warp.is_empty(): x(a).pull=maxf(x(a).get("pull",0),delay*warp[2]/1000000.0)
		"pshield","hshield":
			var amount=floor(a.base[a.line]*(2 if dungeon_enemy_r21!=null else 1)*sk.power)*(1.03 if count_tag("nation","솔렌 성왕국")>=2 else 1)
			if gear_bridge!=null:
				var modified=gear_bridge.invoke("shield",[gear_bridge.slot(a),amount]); amount=floor(modified if modified!=null else amount)
			else: amount*=1+sig(a,"pa_layer")[0]/100.0 if not sig(a,"pa_layer").is_empty() else 1
			for member in living(true):
				_shield(member,amount,3 if dungeon_enemy_r21!=null else 2,gear_bridge==null)
				if gear_bridge==null and not sig(a,"pr_swift").is_empty(): member.remaining=maxf(0,member.remaining-100*sig(a,"pr_swift")[0])
		"bless":
			for member in living(true):
				for key in ["attack_up","defense_up"]: _effect(member,key,3,.15 if gear_bridge!=null else .15*(1+sig(a,"pr_bless")[0]/100.0 if not sig(a,"pr_bless").is_empty() else 1)*(1+bonus(a,"buff")))
		"heal":
			for member in living(true): _heal(a,member,(1.4*(1.1 if count_tag("nation","마렌토 공화국")>=2 else 1)) if dungeon_enemy_r21!=null else .7)
		"acid":
			var value=.2
			if gear_bridge!=null:
				gear_bridge.pack(); value=gear_bridge.hooks.splash_value(gear_bridge.st.u[gear_bridge.slot(a)-1])
			_effect(e,"defense_down",3,value)
			if gear_bridge!=null: gear_bridge.invoke("gear_splash",[gear_bridge.slot(a),gear_bridge.slot(e),value])
			PersonalRules.abyss(self,a,e,12)
			if gear_bridge==null and not sig(a,"al_splash").is_empty():
				var index=data.enemies.find(e)
				for other in living(false):
					if absi(data.enemies.find(other)-index)==1: _effect(other,"defense_down",3,sig(a,"al_splash")[0]/100.0)
		"tonic": _effect(t,"attack_up",3,.15)
		"ruin":
			if dungeon_enemy_r21!=null: _volley(a,.6,0)
			else:
				for foe in living(false): _damage(a,foe,.6,0); _effect(foe,"dot",3,a.base.int*.5); _effect(foe,"attack_down",3,.15)
		"blood":
			a.hp-=hp_cost(a,id)
			if dungeon_enemy_r21!=null: _sorel_aid(a)
			_effect(a,"blood",2,1)
	if gear_bridge!=null:
		gear_bridge.hooks.skill=null; gear_bridge.invoke("gear_skill",[gear_bridge.slot(a),gear_bridge.skill_id(id)])
	elif a.effects.has("taunt") and not sig(a,"wa_wall").is_empty(): _effect(a,"gear_guard",int(sig(a,"wa_wall")[1]),sig(a,"wa_wall")[0]/100.0)
	if dungeon_enemy_r21!=null: combat_events.finish(self)
	_finish_turn(2.0 if id=="burst" else 1.0); return true

func _tactic(a: Dictionary,e: Dictionary,t: Dictionary,sk: Dictionary) -> void:
	var p=sk.prefix; var q=sk.suffix
	var targets=living(false) if p.kind=="volley" else [e] if p.kind=="attack" else living(true) if p.kind.ends_with("_all") else [t]
	for target in targets:
		if p.kind in ["attack","volley"]:
			var power=p.power*(1+q.value if q.kind=="bane" and not target.effects.is_empty() else 1)
			_damage(a,target,power,p.brk+(q.value if q.kind=="abyss" else 0))
			if q.kind=="tempo" and target.hp==0: x(a).pull=q.value
			if q.kind=="bleed": _effect(target,"dot",2,a.base[a.line]*2*q.value)
			if q.kind=="weaken": _effect(target,"attack_down",2,q.value)
		else:
			if p.kind.begins_with("heal"): _heal(a,target,p.power,true)
			else: _shield(target,a.base[a.line]*2*p.power,2)
			if q.kind=="regen":
				if dungeon_enemy_r21!=null: set_persona_regen(target,floor(a.base[a.line]*2*q.value+.5),2)
				else: _effect(target,"regen",3,a.base[a.line]*2*q.value)
			if q.kind=="guard": _effect(target,"psguard",2,q.value)
			if q.kind=="crit": _effect(target,"crit_up",2,q.value)

func _use_supply(item: Dictionary,t: Dictionary) -> bool:
	if t.is_empty() or t.level<item.level or inventory.get(item.id,0)<=0: return false
	if dungeon_enemy_r21!=null: return _use_supply_r21(item,t)
	if item.kind=="revive":
		if t.hp>0: return false
		t.hp=maxi(1,int(t.mhp*.25))
	else:
		if t.hp<=0: return false
		match item.kind:
			"hp","mp":
				var maximum=t.mhp if item.kind=="hp" else t.mmp
				if t[item.kind]>=maximum: return false
				t[item.kind]=mini(maximum,t[item.kind]+int(round(maximum*item.fraction)))
			"shield":
				var amount=int(round(t.mhp*item.fraction))
				if t.shield>=amount: return false
				_shield(t,amount,3)
			"cleanse":
				var count=0
				for key in ["dot","corrosion","bleed","foxflame","enemy_dot_0","enemy_dot_1","enemy_dot_2","enemy_dot_3"]:
					if t.effects.has(key): t.effects.erase(key); count+=1
				if count==0: return false
	inventory[item.id]-=1; events=[]; action_id="supply"
	if dungeon_enemy_r21!=null:
		combat_hits=[]; dungeon_enemy_r21.begin_random(turn_count+1)
		_begin_combat_events("supply",ally(current_id),enemy(selected_enemy),t); combat_events.finish(self)
	_event(item.name+" → "+t.name); _finish_turn(); return true

func _use_supply_r21(item: Dictionary,t: Dictionary) -> bool:
	# 78-battle-item: validate before reseeding or consuming the action.
	var maximum=t.mmp if item.kind=="mp" else t.mhp
	if item.kind=="revive":
		if t.hp>0: return false
	else:
		if t.hp<=0: return false
		if item.kind in ["hp","mp"] and t[item.kind]>=maximum: return false
		if item.kind=="shield" and t.shield>=floor(t.mhp*item.fraction+.5): return false
		if item.kind=="cleanse" and t.effects.keys().filter(func(key):return key in ["dot","corrosion","bleed","foxflame"] or key.begins_with("enemy_dot_")).is_empty(): return false
	dungeon_enemy_r21.begin_random(turn_count+1); combat_hits=[]; events=[]; action_id="supply"
	_begin_effect_action(current_id); _begin_combat_events("supply",ally(current_id),enemy(selected_enemy),t)
	var mul=1.1 if count_tag("nation","마렌토 공화국")>=2 else 1.0
	var amount=int(floor(maximum*item.get("fraction",0)*mul+.5))
	match item.kind:
		"hp": _receive_heal(t,amount)
		"mp": t.mp=mini(t.mmp,t.mp+amount)
		"shield":
			var shield_amount=float(amount)
			if count_tag("nation","솔렌 성왕국")>=2: shield_amount*=1.03
			_shield(t,shield_amount,3)
		"cleanse":
			for key in t.effects.keys():
				if key in ["dot","corrosion","bleed","foxflame"] or key.begins_with("enemy_dot_"): t.effects.erase(key)
			x(t).dot_stacks=0
		"revive":
			t.hp=maxi(1,int(floor(t.mhp*.25))); t.remaining=10000.0; t.effects={}; t.charging=false
			x(t).cover=""; x(t).reviving=false; x(t).erase("death_tick")
	inventory[item.id]-=1; combat_events.finish(self)
	_event(item.name+" → "+t.name); _finish_turn(); return true

func _add_adeline_regen(t: Dictionary,amount: float,turns: int,owner: String) -> void:
	var heals=t.effects.get("regen",{}).get("heals",[]).duplicate(true)
	heals.append({"amount":amount,"turns":turns,"action":turn_count+1})
	_source_effect(t,"regen",turns,amount,owner); t.effects.regen.heals=heals

func _turn_end_regen(t: Dictionary) -> void:
	if t.hp<=0 or not t.effects.has("regen") or not has_alive("adeline"): return
	var eff=t.effects.regen
	var heals=eff.get("heals",[{"amount":eff.amount,"turns":eff.turns,"action":-1}])
	var keep=[]; var amount=0.0; var left=0
	for entry in heals:
		if entry.action!=turn_count+1: amount+=entry.amount; entry.turns-=1
		if entry.turns>0: keep.append(entry); left=maxi(left,int(entry.turns))
	_receive_heal(t,amount)
	if keep.is_empty(): t.effects.erase("regen")
	else: eff.heals=keep; eff.turns=left

func _personal(a: Dictionary,e: Dictionary,t: Dictionary,sk: Dictionary) -> void:
	if dungeon_enemy_r21!=null: PersonalRules.run(self,a,e,t,sk); return
	match a.id:
		"marceline": x(a).cover=t.id
		"naran": _effect(e,"mark",4,1); _break(e,3*(1.5 if a.element in e.weak else 1))
		"teiris":
			a.once=true
			volley_active=true
			for foe in living(false): _damage(a,foe,1.9,0)
			volley_active=false; _hg_scan()
		"haldric":
			for m in living(true):
				if m.row==a.row: _source_effect(m,"contract",3,.2,a.id)
		"erdene":
			a.hp=mini(a.mhp,a.hp+int(x(a).get("prevented",0)*.25)); x(a).prevented=0; _effect(a,"taunt",3)
			for foe in living(false): _effect(foe,"attack_down",2,.15); _break(foe,20)
		"saya": e.remaining+=4000; _break(e,3)
		"gerda":
			var other=_behind(e); _damage(a,e,1.3,3)
			if not other.is_empty(): _damage(a,other,1.3,3,true)
		"judith":
			_effect(e,"defense_down",3,.2); _effect(e,"attack_down",3,.15)
			if dungeon_enemy_r21!=null:
				_effect(e,"haste",3,.15)
				if not x(e).has("judith_sp0"): x(e).judith_sp0=e.speed; e.speed=floor(e.speed*.85+.5)
				x(e).judith_until=ctb_round+3
			else: _effect(e,"slow",3,.15)
			_effect(e,"corrosion",2,a.base.int*1.5); _break(e,3)
		"levia": a.hp-=hp_cost(a,"personal"); _effect(a,"rift_charge",99,1)
		"urda":
			var key=PersonalRules.best_double(t)
			if not key.is_empty():
				t.effects[key].amount=minf(.7,t.effects[key].amount*2) if key in ["contract","duty"] else t.effects[key].amount*2
				t.effects[key].doubled=true
		"lynette":
			for m in living(true): _heal(a,m,.5); _shield(m,a.base.int,2)
		"felice": _heal(a,t,.4); _cleanse(t)
		"sorel":
			for m in living(true):
				_heal(a,m,1)
				_effect(m,"sorel_regen" if dungeon_enemy_r21!=null else "regen",2 if dungeon_enemy_r21!=null else 3,int(floor(a.base.int*.6)))
		"tika": a.hp-=hp_cost(a,"personal"); x(a).free=2
		"hedwig":
			_damage(a,e,1.2,15)
			for m in living(true):
				if m.id!=a.id and m.line=="int": _effect(m,"magic_amp",3,.1)
		"hildegard": _effect(a,"taunt",2); _effect(a,"duty",2,.25); _break(intimidation_target("duty"),15)
		"berenga": _heal(a,t,1); _cleanse(t)
		"altan":
			var key="attack_up"
			for m in living(true):
				if m.effects.has("attack_up"): key="defense_up"
			for m in living(true): _effect(m,key,2,.15)
		"colette": _effect(e,"silence",2,1); _break(e,15)
		"ornel": _damage(a,e,1.2,15); _effect(e,"attack_down",2,.2)
		"zahar":
			for foe in living(false): _damage(a,foe,1.2,15)
			_effect(a,"zdn",1,.2)
		"tove": _break(e,40); _effect(a,"taunt",2)
		"miko": _heal(a,t,1); t.remaining=maxf(0,t.remaining-3000)
		"adeline":
			for m in living(true):
				_heal(a,m,.4); _source_effect(m,"adeline_guard",2,.1,a.id)
				if dungeon_enemy_r21!=null: _add_adeline_regen(m,a.base.int*.16,2,a.id)
				else: _source_effect(m,"regen",3,a.base.int*.16,a.id)
		_: _damage(a,e,1.4 if a.id=="bianca" else 1.2,15 if a.id=="bargut" and dungeon_enemy_r21!=null else sk.brk)

func _felice_scan() -> void:
	if not has_alive("felice"): return
	if dungeon_enemy_r21==null: return
	var owner=ally("felice")
	if x(owner).get("revive",false): return
	var pick={}; var earliest=INF
	for member in data.allies:
		if member.id==owner.id or member.hp>0: continue
		if not x(member).has("death_tick"): x(member).death_tick=ctb_tick
		var ready=x(member).death_tick+ceil(maxf(0,member.remaining)/member.base.spd)
		if ctb_tick>=ready and ready<earliest: pick=member; earliest=ready
	if pick.is_empty(): return
	var persistent={}
	for key in ["sorel_regen","regen","persona_regen"]:
		if pick.effects.has(key): persistent[key]=pick.effects[key]
	pick.hp=maxi(1,int(floor(pick.mhp*.25))); pick.effects=persistent; pick.shield=0; pick.charging=false
	pick.remaining=0.0; x(pick).reviving=false; x(pick).erase("death_tick"); x(owner).revive=true
	_event(pick.name+" · 펠리체 소생")

func _finish_turn(interval_scale: float=1) -> void:
	if dungeon_enemy_r21!=null:
		var ending=ally(current_id)
		if not ending.is_empty() and x(ending).get("cover_turns",0)>0:
			x(ending).cover_turns-=1
			if x(ending).cover_turns<=0: x(ending).erase("cover")
		if not ending.is_empty() and ending.hp>0 and ending.id=="erdene" and not ending.effects.has("taunt"):
			_receive_heal(ending,x(ending).get("prevented",0)*.25); x(ending).prevented=0
		# Felice's turn_end is an allied action hook, not an enemy_end hook.
		if not ally(current_id).is_empty() and unit(current_id).hp>0:
			_felice_scan(); _hg_scan()
		dungeon_enemy_r21.end_effects(unit(current_id))
		_turn_end_regen(unit(current_id))
		if has_alive("judith"): _judith_unslow()
		r21_action_actor=""
	var a=ally(current_id)
	if not a.is_empty():
		interval_scale*=1-float(x(a).get("pull",0)); x(a).pull=0
		if dungeon_enemy_r21==null and a.id=="tika" and action_id in ["attack","personal"] and x(a).get("free",0)>0 and not (action_id=="personal"):
			x(a).free-=1; interval_scale=0
		if dungeon_enemy_r21==null and a.id=="hedwig" and (int(a.actions)+1)%3==0: _effect(a,"next_power",4,.6)
	if dungeon_enemy_r21==null:
		super(interval_scale)
	else:
		var u=unit(current_id)
		u.remaining+=10000*interval_scale
		if u.has("base"):
			u.actions+=1
			if u.id=="bargut": u.remaining=maxf(0,u.remaining-10000*x(u).get("personal_pull",0)); x(u).personal_pull=0
			if u.id=="teiris" and int(u.actions)%int(u.trait.p.every)==0: u.remaining=maxf(0,u.remaining-10000)
			PersonalRules.turn_end(self,u); TraitRules.turn_end(self,u)
			if gear_bridge!=null: gear_bridge.invoke("turn_end",[gear_bridge.slot(u)])
		if gear_bridge!=null: gear_bridge.hooks.act=0; gear_bridge.hooks.skill=null
		critical_this_action=false; turn_count+=1
		if not _check_end(): _advance_ctb()
		refresh_forecast()
	if result.is_empty() and unit(current_id).hp<=0:
		if dungeon_enemy_r21!=null: _advance_after_dot_death()
		else: _finish_turn()

func _advance_after_dot_death() -> void:
	# Repeat only CTB selection from battle_state._finish_turn. A dead actor
	# neither acts nor ends a turn, so actions/turn_count must not advance.
	while result.is_empty() and unit(current_id).hp<=0:
		if not unit(current_id).has("base"):
			unit(current_id).remaining+=10000
			dungeon_enemy_r21.end_effects(unit(current_id))
		if _check_end(): break
		_advance_ctb()
		var next=unit(current_id)
		if next.hp<=0: continue
		if _check_end(): break
		if next.has("mp"):
			last_ally=next.id
		if enemy(selected_enemy).hp<=0: selected_enemy=living(false)[0].id
		selected_action="attack"
	refresh_forecast()

func automatic_turn() -> bool:
	if not result.is_empty(): return false
	var a=ally(current_id)
	if a.is_empty(): return dungeon_enemy_r21.turn() if dungeon_enemy_r21!=null else super()
	if not a.charging: return false
	events=[]; action_id="burst"; a.charging=false; _event(a.name+" · 마력 폭발 발동")
	combat_hits=[]
	if dungeon_enemy_r21!=null: dungeon_enemy_r21.begin_random(turn_count+1)
	if dungeon_enemy_r21!=null: combat_events.begin(self,"release",a,enemy(selected_enemy),a)
	_volley(a,a.skills.burst.power,a.skills.burst.brk)
	if dungeon_enemy_r21!=null: combat_events.finish(self)
	_finish_turn(); return true

func _plan_redirect(e: Dictionary) -> void:
	e.redirected=has_alive("hildegard") and e.target_id!="hildegard" and _roll(.35)

func _peek_target(e: Dictionary) -> Dictionary:
	for a in living(true):
		if a.effects.has("taunt"): return a
	if e.redirected and has_alive("hildegard"): return ally("hildegard")
	var t=ally(e.target_id)
	return t if not t.is_empty() and t.hp>0 else living(true)[0]

func _attack_target(e: Dictionary) -> Dictionary:
	var t=_peek_target(e)
	if dungeon_enemy_r21==null and t.id=="hildegard" and e.redirected: t.hp=mini(t.mhp,t.hp+int(t.mhp*.04))
	return t

func _enemy_evade(e: Dictionary,a: Dictionary) -> bool:
	# B.chain visits all living personal hooks in slot order, even after true.
	# Only the global gear/nation roll is suppressed by an earlier evade.
	var evaded=false
	var act=e.acts[e.act_index]
	var magic=e.get("magic",false) or act.get("magic",false) or act.get("ic","")=="spell" or act.kind=="spell"
	for owner in data.allies:
		if owner.hp<=0: continue
		if owner.id=="felice": _felice_scan()
		if owner.id=="jorund": x(e).jd=0
		if owner.id=="altan" and act.kind in ["atk","shoot","aimed","spell","big_one","big_all"] and act.get("m",0)>=1.5 and x(owner).get("refresh",0)<2:
			var amount=int(floor(owner.base[owner.line]*2))
			if a.hp>0 and a.shield<amount: a.shield=amount; _effect(a,"shield",3); x(owner).refresh=x(owner).get("refresh",0)+1
		if owner.id=="colette" and (x(e).get("seal_until",0)>ctb_tick or e.effects.has("silence")) and magic:
			_event("마법 봉인 · 행동 취소"); evaded=true
		if owner.id=="saya" and owner.id==a.id and dungeon_enemy_r21.random()<.1:
			_event("사야 · 회피 후 반격")
			if e.hp>0: _damage(a,e,1.5,0,true,dungeon_enemy_r21.random(),{"hit":.3,"duration":.9,"allow_extra":true})
			evaded=true
	if evaded: return true
	var chance=bonus(a,"evade")+(.01 if a.get("nation")=="나에린" else 0)
	if gear_bridge!=null:
		return gear_bridge.invoke("evade_roll",[gear_bridge.slot(a),.01 if a.get("nation")=="나에린" else 0,false])==true
	if chance>0 and dungeon_enemy_r21.random()<chance:
		_event(a.name+" · 회피"); return true
	return false

func _enemy_hit(e: Dictionary,a: Dictionary,sk: Dictionary) -> void:
	last_enemy_hit_target=""
	last_enemy_hit_result={}
	if a.hp<=0 or e.hp<=0: return
	var covered=false
	if has_alive("marceline") and a.id!="marceline" and x(ally("marceline")).get("cover")==a.id and (dungeon_enemy_r21==null or (sk.kind!="big_all" and sk.get("target","")!="all")):
		a=ally("marceline"); x(a).erase("cover"); covered=true
	# Ordinary attacks also visit Felice's evade hook before the global roll.
	if dungeon_enemy_r21!=null: _felice_scan()
	if dungeon_enemy_r21!=null:
		if _enemy_evade(e,a): _record_hit(e.id,a.id,0,0); return
	elif _roll(bonus(a,"evade")+(.01 if a.get("nation")=="나에린" else 0)): _event(a.name+" · 회피"); return
	if sk.kind=="spell" and e.effects.has("silence"): _event("마법 봉인 · 행동 취소"); return
	if dungeon_enemy_r21==null and a.id=="saya" and _roll(.1):
		_event("사야 · 회피 후 반격"); _damage(a,e,1.5,0,true); return
	last_enemy_hit_target=a.id
	var n=e.level-1
	var k=40*(1+data.def_curve.a*n+data.def_curve.b*n*n)
	var defense=a.base.def*(1+fx(a,"bless")+fx(a,"defense_up")-fx(a,"defense_down")) if dungeon_enemy_r21!=null else a.base.def*(1+fx(a,"bless")+fx(a,"defense_up"))*(1-fx(a,"defense_down"))
	var hit=e.attack*sk.get("m",1)*k/(k+defense)*(1-fx(e,"attack_down"))
	if dungeon_enemy_r21!=null: hit=maxi(1,int(floor(hit*dungeon_enemy_r21.attack_mult(e)+1e-9)))
	_incoming_strike(a,hit,e,sk,covered)

func _incoming_strike(a: Dictionary,hit: float,e: Dictionary,sk: Dictionary,covered=false,fixed=false) -> void:
	if dungeon_enemy_r21==null: _legacy_incoming_strike(a,hit,e,sk,covered,fixed); return
	if a.hp<=0: return
	if not a.has("base"):
		_flat_enemy(a,hit,{},false,false); return
	# B.strike: stance and cover precede take; tactical psguard follows it.
	if not fixed and a.effects.has("guard"): hit=floor(hit*(1-fx(a,"guard"))+1e-9)
	if covered: hit=floor(hit*.7+1e-9)
	hit=PersonalRules.take(self,a,hit,e if not fixed else {})
	if a.get("race")=="하프엘프": hit*=.98
	if count_tag("race","하프엘프")>=3: hit*=.98
	var nox=count_tag("race","녹스")
	if nox>=2: hit*=.95 if nox>=3 else .97
	if nox>=3 and a.effects.has("taunt"): hit*=.92
	if count_tag("nation","신성 세레디아 제국")>=2 and a.row=="전열": hit*=.97
	if a.get("nation")=="케른 연방" and a.effects.has("taunt"): hit*=.98
	if a.class_id=="gladiator": hit*=1-.1*float(a.hp)/a.mhp
	if gear_bridge!=null:
		var old_skill=gear_bridge.hooks.skill; gear_bridge.hooks.skill=null
		var modified=gear_bridge.invoke("take",[gear_bridge.slot(a),hit,gear_bridge.slot(e) if not e.is_empty() else "fixed",hit]); hit=modified if modified!=null else hit
		gear_bridge.hooks.skill=old_skill
	# red25 (duty) belongs inside take; psguard is rounded separately.
	hit=floor(hit+.5)
	if fx(a,"psguard")>0: hit=floor(hit*(1-fx(a,"psguard"))+.5)
	var damage=maxi(1,int(hit)); var absorbed=mini(a.shield,damage)
	if dungeon_enemy_r21!=null and not fixed and not e.is_empty(): _record_hit(e.id,a.id,damage,absorbed)
	# Lua al stays true during save hooks, even after lethal HP becomes zero.
	var save_owners=data.allies.filter(func(member): return member.hp>0)
	if a.hp-damage+absorbed<=0 and has_alive("felice") and a.id!="felice": x(a).death_tick=ctb_tick
	a.shield-=absorbed; damage-=absorbed; a.hp=maxi(0,a.hp-damage)
	if absorbed>0 and a.shield==0: a.effects.erase("shield")
	var echo_broken=absorbed>0 and a.shield==0
	if echo_broken and gear_bridge!=null: gear_bridge.invoke("gear_shbreak",[gear_bridge.slot(a),absorbed,gear_bridge.slot(e) if not e.is_empty() else "fixed"])
	_event("%s → %s · %d 피해" % [sk.name,a.name,damage])
	if a.hp==0:
		# Personal save hooks run in party order, then gear, then priest.
		if a.id=="marceline" and not x(a).get("saved",false):
			x(a).saved=true; a.hp=mini(a.mhp,1+int(a.mhp*.25)); _shield(a,a.mhp*.15,3,false)
		elif gear_bridge!=null and gear_bridge.invoke("gear_save",[gear_bridge.slot(a),combat_events.T])==1: pass
		else:
			if not a.ward_used:
				for member in save_owners:
					if member.class_id!="priest": continue
					gear_bridge.pack(); var miracle=gear_bridge.hooks.miracle(gear_bridge.st.u[gear_bridge.slot(member)-1],.5)
					var fraction=miracle.hp
					a.ward_used=true; a.hp=int(floor(a.mhp*fraction+.5))
					if miracle.shield>0: _shield(a,a.mhp*miracle.shield,3,false)
					break
			if a.hp==0 and a.id!="felice" and has_alive("felice") and not x(ally("felice")).get("revive",false):
				x(a).reviving=true; _event("펠리체 · 다음 차례에 소생")
		if a.hp<=0 and dungeon_enemy_r21!=null: _ally_down(a)
	a.effects.erase("mark")
	if damage>0 and a.hp>0 and a.hp<=a.mhp*.25 and has_alive("sorel") and x(ally("sorel")).get("rescue",0)<2:
		x(ally("sorel")).rescue=x(ally("sorel")).get("rescue",0)+1
		if dungeon_enemy_r21!=null: _receive_heal(a,ally("sorel").base.int*2)
		else: _heal(ally("sorel"),a,1)
	if damage>0 and gear_bridge!=null: gear_bridge.invoke("damaged",[gear_bridge.slot(a),damage,gear_bridge.slot(e) if not e.is_empty() else "fixed",combat_events.T])
	# Both fixed and ordinary strikes run pecho after saves, death and damaged.
	if gear_bridge!=null: gear_bridge.invoke("gear_pecho",[gear_bridge.slot(a),combat_events.T])
	# B.strike res.d includes shield absorption. Keep this hit independent of
	# subsequent counters and gear re-entry, which append their own hit records.
	last_enemy_hit_result={"d":damage+absorbed,"sh":absorbed}

# Frozen legacy damage path from 72bf1b2; ongoing pre-r21 expeditions keep their rules.
func _legacy_incoming_strike(a: Dictionary,hit: float,e: Dictionary,sk: Dictionary,covered=false,fixed=false) -> void:
	if a.hp<=0: return
	if not a.has("base"):
		var damage=maxi(1,int(floor(hit))); var absorbed=mini(int(a.get("shield",0)),damage)
		a.shield=a.get("shield",0)-absorbed; a.hp=maxi(0,a.hp-(damage-absorbed))
		return
	# B.strike: stance and cover precede take; tactical psguard follows it.
	if not fixed and a.effects.has("guard"): hit=floor(hit*(1-fx(a,"guard")))
	if covered: hit=floor(hit*.7)
	if a.id=="hildegard": hit*=.85*(1-fx(a,"duty"))
	if a.get("race")=="하프엘프": hit*=.98
	if count_tag("race","하프엘프")>=3: hit*=.98
	var nox=count_tag("race","녹스")
	if nox>=2: hit*=.95 if nox>=3 else .97
	if nox>=3 and a.effects.has("taunt"): hit*=.92
	if count_tag("nation","신성 세레디아 제국")>=2 and a.row=="전열": hit*=.97
	if a.get("nation")=="케른 연방" and a.effects.has("taunt"): hit*=.98
	if a.id=="zahar" and (fixed or not sk.get("magic",false)): hit*=.62
	if a.id=="zahar" and fx(a,"zdn")>0:
		var n=int(data.encounter_r21.el)-1 if dungeon_enemy_r21!=null else int(e.get("level",1))-1
		var k=40*(1+data.def_curve.a*n+data.def_curve.b*n*n)
		var d0=a.base.def*(1+fx(a,"bless")+fx(a,"defense_up"))
		var d1=d0-a.base.def*fx(a,"zdn")
		hit*=(k+d0)/(k+d1)
	if a.id=="erdene" and a.effects.has("taunt"): x(a).prevented=x(a).get("prevented",0)+hit*.15; hit*=.85
	if has_alive("haldric"):
		if a.id=="haldric" or ally("haldric").effects.has("taunt"): hit*=.85
		hit*=1-fx(a,"contract")
	if has_alive("adeline"): hit*=1-fx(a,"adeline_guard")
	hit*=1-fx(a,"gear_guard")
	for member in living(true): hit*=1-fx(member,"wall_party")
	if a.shield>0 and not sig(a,"pa_wrath").is_empty(): hit*=1-sig(a,"pa_wrath")[1]/100.0
	if a.charging and not sig(a,"sa_ward").is_empty():
		var ward=sig(a,"sa_ward"); x(a).charge_damage=x(a).get("charge_damage",0)+hit*ward[0]*ward[1]/10000.0; hit*=1-ward[0]/100.0
	if a.class_id=="gladiator": hit*=1-.1*float(a.hp)/a.mhp
	hit*=1-minf(.8,a.get("gear_fx",{}).get("dr",0)/100.0)
	if not fixed and has_alive("altan") and sk.get("m",1)>=1.5 and x(ally("altan")).get("refresh",0)<2:
		_shield(a,ally("altan").base.int*2,3); x(ally("altan")).refresh=x(ally("altan")).get("refresh",0)+1
	# red25 (duty) belongs inside take; psguard is rounded separately.
	hit=floor(hit+.5)
	if fx(a,"psguard")>0: hit=floor(hit*(1-fx(a,"psguard"))+.5)
	var damage=maxi(1,int(hit)); var absorbed=mini(a.shield,damage)
	a.shield-=absorbed; damage-=absorbed; a.hp=maxi(0,a.hp-damage)
	if (not fixed or damage>0) and not sig(a,"wa_scar").is_empty():
		var scar=sig(a,"wa_scar"); x(a).scar=minf(a.mhp*scar[1]/100.0,x(a).get("scar",0)+damage*scar[0]/100.0)
	if not e.is_empty(): e.hp=maxi(0,e.hp-int(damage*bonus(a,"reflect")))
	var echo_heal=0
	if absorbed>0 and a.shield==0:
		var thorns=proc(a,"thorns_shd")
		if not e.is_empty() and not thorns.is_empty(): e.hp=maxi(0,e.hp-int(absorbed*thorns.x/100.0))
		var echo=0.0
		for member in living(true):
			if not sig(member,"pa_echo").is_empty(): echo=maxf(echo,sig(member,"pa_echo")[0]/100.0)
		if fixed: echo_heal=int(absorbed*echo)
		else: a.hp=mini(a.mhp,a.hp+int(absorbed*echo))
	_event("%s → %s · %d 피해" % [sk.name,a.name,damage])
	if a.hp==0:
		if not sig(a,"wa_last").is_empty() and not x(a).get("wall_saved",false):
			var wall=sig(a,"wa_last"); x(a).wall_saved=true; a.hp=int(a.mhp*wall[0]/100.0); _effect(a,"wall_party",int(wall[1])+(1 if current_id==a.id else 0),wall[2]/100.0)
		elif a.id=="marceline" and not x(a).get("saved",false):
			x(a).saved=true; a.hp=1+int(a.mhp*.25); _shield(a,a.mhp*.15,3,false)
		else:
			var priest=false
			for m in living(true):
				if m.class_id=="priest": priest=true
			if priest and not a.ward_used:
				a.ward_used=true; a.hp=int(a.mhp*.5)
				for member in living(true):
					var miracle=sig(member,"pr_miracle")
					if not miracle.is_empty(): a.hp=maxi(a.hp,int(a.mhp*miracle[0]/100.0)); _shield(a,a.mhp*miracle[1]/100.0,3,false)
			elif has_alive("felice") and not x(ally("felice")).get("revive",false):
				x(ally("felice")).revive=true; x(a).reviving=true; _event("펠리체 · 다음 차례에 소생")
	var stand=proc(a,"last_stand")
	if (not fixed or damage>0) and not stand.is_empty() and a.hp>0 and a.hp<a.mhp*stand.x/100.0 and not x(a).get("stood",false):
		x(a).stood=true; _effect(a,"gear_guard",int(stand.n),.3)
	if (not fixed or damage>0) and a.hp>0 and a.hp<=a.mhp*.25 and has_alive("sorel") and x(ally("sorel")).get("rescue",0)<2:
		x(ally("sorel")).rescue=x(ally("sorel")).get("rescue",0)+1; _heal(ally("sorel"),a,1)
	# Canonical strike resolves lethal saves and damaged hooks before shield echo.
	if fixed and a.hp>0: a.hp=mini(a.mhp,a.hp+echo_heal)

func effects_text(a: Dictionary) -> String:
	if dungeon_enemy_r21!=null:
		var chips=status_chips(a)
		return " · ".join(chips) if not chips.is_empty() else "걸린 효과 없음"
	if a.hp<=0: return "부상 이탈"
	var names={"taunt":"도발","guard":"방어","duty":"피해 감소","psguard":"전술 피해 감소","zdn":"방어 감소","shield":"보호막","bless":"공격·방어 강화","attack_up":"공격 강화","defense_up":"방어 강화","attack_down":"공격 약화","defense_down":"방어 약화","slow":"감속","haste":"가속","regen":"재생","dot":"지속 피해","corrosion":"부식","bleed":"출혈","mark":"확정 치명 표식","foxflame":"여우불","next_power":"다음 공격 강화","magic_amp":"마법 강화","contract":"면책","adeline_guard":"피해 감소","silence":"마법 봉인","rift_charge":"심연 강화","blood":"피의 갈증"}
	var out=[]
	for key in a.effects:
		var label="지속 피해" if key.begins_with("enemy_dot_") else "공격 강화" if key=="enemy_attack_self" else names.get(key,key)
		out.append(label+" %d턴" % a.effects[key].turns)
	return " · ".join(out) if not out.is_empty() else "걸린 효과 없음"

func snapshot() -> Dictionary:
	var v=super(); v.schema_version=3; v.extra_state=extra_state.duplicate(true); v.selected_ally=selected_ally
	v.inventory=inventory.duplicate(true)
	if dungeon_enemy_r21!=null:
		v.r21_roster=dungeon_enemy_r21.roster()
		v.ctb={"tick":ctb_tick,"round":ctb_round}
	return v

func restore(value: Variant) -> bool:
	if dungeon_enemy_r21==null: return _restore_v3(value)
	var previous=data.enemies.duplicate(true)
	if not value is Dictionary or not dungeon_enemy_r21.hydrate(value.get("r21_roster")): data.enemies=previous; return false
	if not _restore_v3(value): data.enemies=previous; return false
	dungeon_enemy_r21.restore_cycles()
	return true

func intent(e: Dictionary) -> String:
	return dungeon_enemy_r21.intent(e) if dungeon_enemy_r21!=null else super(e)

func _restore_v3(value: Variant) -> bool:
	if not value is Dictionary or value.get("schema_version")!=3 or value.get("build")!=data.build: return false
	var shape=snapshot()
	if not value.has("ctb"): shape.erase("ctb")
	elif not value.ctb is Dictionary or value.ctb.size()!=2 or not _number(value.ctb.get("tick")) or not _number(value.ctb.get("round")): return false
	elif value.ctb.tick<0 or value.ctb.tick>100000000 or value.ctb.tick!=floor(value.ctb.tick) or value.ctb.round!=floor(value.ctb.tick/100): return false
	if dungeon_enemy_r21!=null:
		for id in shape.extra_state: shape.extra_state[id]={}
	if not _shape_valid(value,shape): return false
	if not value.current_id in value.units or ally(value.last_ally).is_empty() or enemy(value.selected_enemy).is_empty() or ally(value.selected_ally).is_empty(): return false
	if value.result not in ["","victory","defeat"] or value.rng<1 or value.rng>=2147483647: return false
	for key in value.inventory:
		if not _number(value.inventory[key]) or value.inventory[key]<0 or value.inventory[key]>10000: return false
	for key in ["history","events"]:
		if value[key].size()>32: return false
		for line in value[key]:
			if not line is String or line.length()>300: return false
	for u in data.allies+data.enemies:
		var v=value.units[u.id]
		if v.hp<0 or v.hp>u.mhp or v.remaining<(-1000000 if dungeon_enemy_r21!=null else 0) or v.remaining>1000000: return false
		if u.has("mp") and (v.mp<0 or v.mp>u.mmp or v.shield<0 or v.shield>100000): return false
		if u.has("gauge") and (v.gauge<0 or v.gauge>u.max or v.act_index<0 or v.act_index>=u.acts.size()): return false
		for key in v.effects:
			var eff=v.effects[key]
			if not eff is Dictionary or not _number(eff.get("turns")) or not _number(eff.get("amount")) or eff.turns<1 or eff.turns>100 or absf(eff.amount)>(1e12 if key.begins_with("enemy_dot_") else 100000): return false
			for flag in ["fresh","doubled"]:
				if eff.has(flag) and not eff[flag] is bool: return false
			if eff.has("by") and (not eff.by is String or not value.units.has(eff.by)): return false
			if eff.has("order") and (not _number(eff.order) or eff.order<0 or eff.order>10000000 or eff.order!=floor(eff.order)): return false
			if eff.has("source") and (not eff.source is String or not value.units.has(eff.source)): return false
			if eff.has("heals"):
				if key!="regen" or not eff.heals is Array or eff.heals.is_empty() or eff.heals.size()>400: return false
				for entry in eff.heals:
					if not entry is Dictionary or entry.size()!=3: return false
					for field in ["amount","turns","action"]:
						if not _number(entry.get(field)) or entry[field]<0: return false
					if entry.amount>100000 or entry.turns<1 or entry.turns>100 or entry.turns!=floor(entry.turns) or entry.action<1 or entry.action>400 or entry.action!=floor(entry.action): return false
			if eff.has("stacks"):
				if key!="dot" or not eff.stacks is Array or eff.stacks.is_empty() or eff.stacks.size()>6: return false
				var stack_sum=0.0
				for amount in eff.stacks:
					if not _number(amount) or amount<0 or amount>100000: return false
					stack_sum+=amount
				if not is_equal_approx(stack_sum,float(eff.amount)): return false
				for metadata in ["lifetimes","owners","bursts","initial_turns","orders"]:
					if not eff.has(metadata): continue
					if not eff[metadata] is Array or eff[metadata].size()!=eff.stacks.size(): return false
					for cell in eff[metadata]:
						if metadata=="owners":
							if not cell is String or (cell!="" and not value.units.has(cell)): return false
						elif not _number(cell) or cell<0 or cell>(10000000 if metadata=="orders" else 10000): return false
						elif metadata=="orders" and cell!=floor(cell): return false
						elif metadata in ["lifetimes","initial_turns"] and (cell<1 or cell>100 or cell!=floor(cell)): return false
		for key in value.extra_state[u.id]:
			var cell=value.extra_state[u.id][key]
			if key in ["gear_gw","gear_gk","gear_gb","gear_gt"]:
				if u.id!=data.allies[0].id or not cell is Dictionary or not _gear_global_valid(key,cell): return false
				continue
			if key=="judith_sp0" and (not _number(cell) or cell<=0 or cell>10000000): return false
			if key in ["judith_until","death_tick"] and (not _number(cell) or cell<0 or cell!=floor(cell)): return false
			if key=="source_rng" and (not _number(cell) or cell<1 or cell>=2147483647 or cell!=floor(cell)): return false
			if cell is String:
				if cell.length()>100: return false
			elif cell is bool: pass
			elif not _number(cell) or absf(cell)>(2147483646 if key=="source_rng" else 10000000): return false
	var alive_a=0; var alive_e=0
	for a in data.allies:
		if value.units[a.id].hp>0 or (dungeon_enemy_r21==null and value.extra_state[a.id].get("reviving",false)): alive_a+=1
	for e in data.enemies:
		if value.units[e.id].hp>0: alive_e+=1
	if (value.result=="victory")!=(alive_e==0): return false
	var defeated=alive_e>0 and (alive_a==0 or (dungeon_enemy_r21!=null and value.turn_count>=400))
	if (value.result=="defeat")!=defeated: return false
	for u in data.allies+data.enemies:
		for key in value.units[u.id]: u[key]=value.units[u.id][key].duplicate(true) if value.units[u.id][key] is Dictionary else value.units[u.id][key]
	current_id=value.current_id; last_ally=value.last_ally; selected_enemy=value.selected_enemy; selected_action=value.selected_action; selected_ally=value.selected_ally
	result=value.result; rng_state=int(value.rng); turn_count=int(value.turn_count); history=value.history.duplicate(); events=value.events.duplicate(); extra_state=value.extra_state.duplicate(true)
	for e in data.enemies:
		if x(e).has("judith_sp0"): e.speed=floor(x(e).judith_sp0*.85+.5)
	inventory=value.inventory.duplicate(true)
	ctb_tick=int(value.get("ctb",{}).get("tick",0)); ctb_round=int(value.get("ctb",{}).get("round",0))
	refresh_forecast(); return true

func _gear_global_valid(key: String,cell: Dictionary) -> bool:
	if key=="gear_gk":
		if cell.size()>64: return false
		for k in cell:
			if not k is String or k.length()>40 or not cell[k] is bool: return false
		return true
	var fields={"gear_gw":["n","p","who"],"gear_gb":["t","d"],"gear_gt":["t","e","d","x","n"]}[key]
	if cell.size()!=fields.size(): return false
	for k in fields:
		if not _number(cell.get(k)) or cell[k]<0 or cell[k]>10000000: return false
	for k in ["who","t","e"]:
		if cell.has(k) and (cell[k]<1 or cell[k]>4+data.enemies.size() or cell[k]!=floor(cell[k])): return false
		if cell.has(k) and cell[k]<=4 and cell[k]>data.allies.size(): return false
	if key=="gear_gw" and (cell.n<1 or cell.n>100 or cell.n!=floor(cell.n) or cell.p>100 or cell.who>data.allies.size()): return false
	return true
