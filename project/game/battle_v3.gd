extends "res://game/battle_state.gd"
## Web CTB adaptation. Legacy saves keep using battle_state.gd.
var selected_ally=""
var extra_state={}
var action_id=""
var hit_serial=0
var inventory={}

func _init(scene_data: Dictionary={}) -> void:
	super(scene_data)
	if data.is_empty(): return
	inventory=data.get("inventory",{}).duplicate(true)
	current_id=data.allies[0].id; last_ally=current_id; selected_ally=current_id
	for u in data.allies+data.enemies: extra_state[u.id]={}
	for a in data.allies:
		if a.id=="altan":
			for m in living(true): _shield(m,a.base.int*2,3)
	refresh_forecast()

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
	if u.has("base"):
		if key in ["attack_down","defense_down","slow"]:
			if u.get("race")=="인간": turns=maxi(1,turns-1)
			if u.get("race")=="녹스": amount*=.7
		elif key in ["guard","duty","bless","attack_up","defense_up","contract","blood"] and count_tag("race","하프엘프")>=2: turns+=1
	super(u,key,turns,amount)

func living(friends: bool) -> Array:
	if not friends: return super(false)
	return data.allies.filter(func(a):return a.hp>0 or extra_state.get(a.id,{}).get("reviving",false))

func has_alive(id: String) -> bool:
	return not ally(id).is_empty() and ally(id).hp>0

func cost(id: String) -> int:
	var n=int(actions()[id].mp)
	var a=ally(current_id); var wind=sig(a,"ar_wind")
	if id=="snipe" and not wind.is_empty(): n=int(round(n*(1-wind[0]/100.0)))
	return int(floor(n*.85)) if has_alive("lynette") else n

func actions() -> Dictionary:
	var result=super().duplicate(true)
	if result.is_empty(): return result
	for item in data.get("item_defs",[]):
		if item.kind not in ["return","level"]:
			result["item:"+item.id]={"name":item.name,"mp":0,"target":"아군 1","note":"동료를 선택하면 1개와 현재 차례를 소모합니다.","item":item}
	return result

func unavailable(id: String) -> String:
	if not player_turn() or not actions().has(id): return "행동할 수 없음"
	var a=ally(current_id)
	if id.begins_with("item:") and inventory.get(id.substr(5),0)<=0: return "보유량 없음"
	if a.charging: return "충전 중"
	if id=="personal" and a.id=="teiris" and a.once: return "이번 전투에서 사용함"
	if (id=="blood" or (id=="personal" and a.id in ["tika","levia"])) and a.hp<=hp_cost(a,id): return "HP 부족"
	return "MP 부족" if a.mp<cost(id) else ""

func hp_cost(a: Dictionary,id: String) -> int:
	var result=int(floor(a.mhp*(.15 if id=="blood" else .1))); var boil=sig(a,"gl_boil")
	if a.get("nation")=="모르가스 신관국": result=int(round(result*.7))
	if id=="blood" and not boil.is_empty(): result=int(round(result*(1-boil[0]/100.0)))
	return result

func choose_ally(id: String) -> bool:
	if ally(id).is_empty(): return false
	if ally(id).hp<=0 and selected_action!="item:bandage": return false
	selected_ally=id; return true

func speed(u: Dictionary) -> float:
	var result=super(u)*(1-fx(u,"slow"))*(1+fx(u,"haste"))
	if u.has("base"):
		var elves=count_tag("race","엘프"); var beasts=count_tag("race","수인")
		if elves>=2: result*=1.02 if elves>=3 else 1.01
		if beasts>=2: result*=1.01
		if u.get("nation")=="대카라쉰": result*=1.01
		if u.class_id=="gladiator": result*=1+.08*float(u.hp)/u.mhp
		for a in living(true):
			if a.id!=u.id and a.class_id=="alchemist": result*=1.06
	return maxf(1,result)

func _shield(a: Dictionary, amount: float, turns: int) -> void:
	var source=ally(current_id)
	if not source.is_empty():
		amount*=1+bonus(source,"shield")
		var guardian=proc(source,"guardian")
		if not guardian.is_empty() and _roll(guardian.p/100.0): amount*=1+guardian.x/100.0
	a.shield=maxi(a.shield,int(floor(amount))); _effect(a,"shield",turns)

func _heal(a: Dictionary,t: Dictionary,power: float,use_class_line=false) -> void:
	var amount=a.base[a.line if use_class_line else "int"]*2*power
	if a.id=="berenga": amount*=1+.6*(1-float(t.hp)/t.mhp)
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

func _cleanse(t: Dictionary) -> void:
	for key in ["attack_down","defense_down","slow","dot","corrosion","bleed"]:
		if t.effects.has(key): t.effects.erase(key); return

func _lowest() -> Dictionary:
	var list=living(true); var t=list[0]
	for a in list:
		if float(a.hp)/a.mhp<float(t.hp)/t.mhp: t=a
	return t

func _behind(t: Dictionary) -> Dictionary:
	for e in living(false):
		if e.id!=t.id and e.row=="후열": return e
	for e in living(false):
		if e.id!=t.id: return e
	return {}

func _tick(u: Dictionary) -> void:
	if x(u).get("reviving",false): u.hp=maxi(1,int(u.mhp*.25)); x(u).reviving=false; _event(u.name+" · 응급 소생")
	for key in ["dot","corrosion","bleed"]:
		if fx(u,key)>0:
			u.hp=maxi(0,u.hp-int(floor(fx(u,key)))); _event("%s · 지속 피해 %d" % [u.name,fx(u,key)])
			var owner=ally(x(u).get("dot_owner",""))
			if not owner.is_empty() and owner.hp>0:
				var blood=sig(owner,"un_blood")
				if not blood.is_empty(): owner.mp=mini(owner.mmp,owner.mp+int(blood[0])); _effect(owner,"next_power",99,minf(fx(owner,"next_power")+blood[1]/100.0,blood[1]*blood[2]/100.0))
				var burst=proc(owner,"dot_burst")
				if not burst.is_empty() and u.effects[key].turns==1: u.hp=maxi(0,u.hp-int(fx(u,key)*burst.x/100.0))
	if u.has("base"):
		u.mp=mini(u.mmp,u.mp+int(u.get("gear_fx",{}).get("mpreg",0)))
		var th=proc(u,"taunt_heal")
		if not th.is_empty() and u.effects.has("taunt"): u.hp=mini(u.mhp,u.hp+int(u.mhp*th.x/100.0))
		if fx(u,"regen")>0: u.hp=mini(u.mhp,u.hp+int(floor(fx(u,"regen"))))
		if u.id=="tove": u.shield=mini(int(u.mhp*.3),u.shield+int(u.mhp*.06))
		if u.id=="urda" and not living(true).is_empty():
			var t=_lowest(); _heal(u,t,.175); _cleanse(t)
		if u.id=="erdene" and u.effects.get("taunt",{}).get("turns",0)==1:
			u.hp=mini(u.mhp,u.hp+int(x(u).get("prevented",0)*.25)); x(u).prevented=0
	super(u)

func _damage(a: Dictionary,e: Dictionary,power: float,brk: float,extra=false) -> void:
	if e.hp<=0: return
	var gear=a.get("gear_fx",{})
	var chance=(a.base.crit+a.base.agi/20.0+a.passive.get("crit",0)+a.trait.p.get("crit",0)+gear.get("crit",0))/100.0
	if a.class_id=="gladiator": chance+=.08*float(a.hp)/a.mhp
	if action_id=="snipe": chance=sig(a,"ar_wind")[1]/100.0 if not sig(a,"ar_wind").is_empty() else .7
	if a.effects.has("blood"): chance+=.3
	chance+=fx(a,"crit_up")
	if a.actions==0 and a.get("lineage") in ["고양이","표범","고양이과"]: chance+=.15
	var critical=e.effects.has("mark") or _roll(minf(1,chance))
	critical_this_action=critical_this_action or critical
	e.effects.erase("mark")
	var mult=1+fx(a,"bless")+fx(a,"attack_up")+fx(a,"next_power")+gear.get("dmg",0)/100.0
	if a.line=="int": mult*=1+fx(a,"magic_amp"); a.effects.erase("magic_amp")
	if a.get("race")=="엘프" and a.line=="int": mult*=1.03
	if a.get("race")=="악마" and a.hp<=a.mhp*.3: mult*=1.12
	if a.get("nation")=="솔렌 성왕국" and (e.id=="executor" or e.get("grade","") in ["elite","boss","chief","core"]): mult*=1.03
	if a.actions==0 and count_tag("nation","대카라쉰")>=2: mult*=1.03
	var shared=x(data.allies[0])
	if a.get("lineage") in ["개","여우","늑대","개과"] and shared.get("last_target")==e.id: mult*=1.08
	shared.last_target=e.id
	for member in living(true):
		var pd=proc(member,"party_dmg")
		if not pd.is_empty(): mult*=1+pd.x/100.0
	if e.id=="executor" or e.get("grade","") in ["elite","boss","chief","core"]: mult*=1+bonus(a,"elite")
	if a.hp<=a.mhp*.3: mult*=1+bonus(a,"lowhp")
	if a.shield>0: mult*=1+bonus(a,"shdmg")
	if a.actions==0: mult*=1+bonus(a,"first")
	var wrath=sig(a,"pa_wrath"); var high=sig(a,"ar_high"); var hunger=sig(a,"gl_hunger"); var comp=sig(a,"sa_comp")
	if not wrath.is_empty() and a.shield>0: mult*=1+wrath[0]/100.0
	if not high.is_empty() and a.row=="후열": mult*=1+high[0]/100.0
	if not hunger.is_empty() and a.hp<=a.mhp*hunger[0]/100.0: mult*=1+hunger[1]/100.0
	if not comp.is_empty() and (action_id=="burst" or (action_id=="personal" and a.id=="teiris")): mult*=1+comp[0]/100.0
	if e.broken:
		var resonance=proc(a,"abyss_res"); var rift=sig(a,"ch_rift"); var full=sig(a,"ch_full")
		if not resonance.is_empty(): mult*=1+resonance.x/100.0
		if not rift.is_empty(): mult*=1+rift[1]/100.0
		if not full.is_empty(): mult*=full[0]/2.5*(full[1] if action_id=="chaoswave" else 1)
	if a.class_id=="gladiator": mult*=1+.2*float(a.hp)/a.mhp
	if a.id=="ornel" and float(e.hp)/e.mhp>=.7: mult*=1.6
	if a.id=="tove" and a.shield>0: mult*=1.35
	if a.id=="gunhild":
		if not extra:
			x(a).streak=int(x(a).get("streak",0))+1 if x(a).get("target")==e.id else 0; x(a).target=e.id
		mult*=1+minf(.5,x(a).get("streak",0)*.05)
	if a.id=="bianca" and action_id=="personal" and not e.effects.is_empty(): mult*=1.4
	if a.id=="bargut" and action_id=="personal":
		var fastest=true
		for u in living(true)+living(false):
			if speed(u)>speed(a): fastest=false
		if fastest: mult*=1.5
	if a.id=="jorund" and action_id=="personal" and fx(e,"bleed")>0: mult*=1.4
	if a.id=="lavinia" and action_id=="personal" and e.acts[e.act_index].kind in ["spell","weaken","summon"]: mult*=1.3
	if a.id=="bianca" and e.get("grade","") in ["boss","chief","core"]: mult*=1.3
	var weak=a.element in e.weak
	var defense=e.defense*(1-fx(e,"defense_down"))
	var n=e.level-1
	var k=data.formula.def_k_ratio*data.formula.def_std_base*(1+data.def_curve.a*n+data.def_curve.b*n*n)
	var damage=a.base[a.line]*2*power*mult*k/(k+defense)*(1+fx(e,"foxflame"))
	if weak: damage*=1.3
	if e.broken: damage*=2.5 if a.class_id=="chaos" else 1.5
	if e.broken and a.id=="levia": damage*=1+.3*(data.enemies.size()-living(false).size())/maxf(1,data.enemies.size()-1)
	if critical:
		var crit_bonus=gear.get("critdmg",0)/100.0
		if not sig(a,"as_vital").is_empty(): crit_bonus+=sig(a,"as_vital")[0]/100.0
		damage*=(2.0 if action_id=="snipe" else 1.5)+(.5 if a.effects.has("blood") else 0)+crit_bonus
	if not extra: damage+=x(a).get("scar",0)+x(a).get("charge_damage",0); x(a).scar=0; x(a).charge_damage=0
	if not extra: damage+=x(a).get("overheal",0); x(a).overheal=0; a.effects.erase("next_power")
	var before=int(e.hp); var dealt=maxi(1,int(floor(damage))); e.hp=maxi(0,e.hp-dealt)
	_event("%s → %s · %d 피해%s" % [a.name,e.short,dealt," · 치명" if critical else ""])
	var abyss=brk*(1.5 if weak else 1.0)*(1+gear.get("abyss",0)/100.0)
	if not sig(a,"ch_rift").is_empty(): abyss*=1+sig(a,"ch_rift")[0]/100.0
	var was_broken=e.broken
	if a.id=="levia": abyss*=1+.3*(data.enemies.size()-living(false).size())/maxf(1,data.enemies.size()-1)
	_break(e,abyss)
	if not was_broken and e.broken and not sig(a,"ch_void").is_empty():
		var v=sig(a,"ch_void"); a.mp=mini(a.mmp,a.mp+int(a.mmp*v[0]/100.0)); x(a).pull=maxf(x(a).get("pull",0),v[1]/100.0)
	if a.id=="levia":
		for other in living(false):
			if other.id!=e.id: _break(other,round(abyss*.07))
	if a.class_id=="sanctioned" and action_id in ["attack","burst"] and e.hp>0:
		var delay=800.0; var warp=sig(a,"sa_warp")
		if not warp.is_empty(): delay=100*warp[0]; x(a).pull=maxf(x(a).get("pull",0),warp[0]*warp[2]/10000.0)
		e.remaining+=delay
	if a.class_id=="unsanctioned":
		var dot=a.base.int*.24*(1+bonus(a,"dot"))
		if not sig(a,"un_seep").is_empty(): dot*=1+sig(a,"un_seep")[0]/100.0
		_effect(e,"dot",4,minf(fx(e,"dot")+dot,dot*5)); x(e).dot_owner=a.id; x(e).dot_stacks=int(x(e).get("dot_stacks",0))+1
		var chain=sig(a,"un_chain")
		if not chain.is_empty() and x(e).dot_stacks>=chain[0]:
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

func act(id: String) -> bool:
	if not unavailable(id).is_empty(): return false
	var a=ally(current_id); var sk=actions()[id]; var e=enemy(selected_enemy)
	var t=ally(selected_ally)
	if id.begins_with("item:"): return _use_supply(sk.item,t)
	if sk.target=="아군 1" and (t.is_empty() or t.hp<=0): return false
	if sk.target.begins_with("적") and living(false).is_empty(): return false
	events=[]; critical_this_action=false; a.mp-=cost(id); action_id=id; selected_action=id
	x(a).haste_done=false
	var echo=proc(a,"echo")
	if sk.mp>0 and not echo.is_empty() and _roll(echo.p/100.0): a.mp=mini(a.mmp,a.mp+int(cost(id)*echo.x/100.0))
	_event(a.name+" · "+sk.name)
	match id:
		"tactic": _tactic(a,e,t,sk)
		"personal": _personal(a,e,t,sk)
		"attack","snipe","rift":
			var brk=sk.brk*(1.5 if id=="rift" and a.effects.has("rift_charge") else 1.0)
			_damage(a,e,sk.power,brk)
			if id=="rift": a.effects.erase("rift_charge")
		"chaoswave":
			for foe in living(false): _damage(a,foe,sk.power,sk.brk*(1.5 if a.effects.has("rift_charge") else 1))
			a.effects.erase("rift_charge")
		"guard": _effect(a,"guard",sk.turns,sk.power)
		"taunt","ptaunt": _effect(a,"taunt",2); _break(e,sk.brk)
		"burst":
			a.charging=true
			var warp=sig(a,"sa_warp")
			var delay=2500.0 if warp.is_empty() else warp[1]*100.0
			e.remaining+=delay
			if not warp.is_empty(): x(a).pull=maxf(x(a).get("pull",0),delay*warp[2]/1000000.0)
		"pshield","hshield":
			for member in living(true):
				_shield(member,a.base[a.line]*sk.power*(1+sig(a,"pa_layer")[0]/100.0 if not sig(a,"pa_layer").is_empty() else 1),2)
				if not sig(a,"pr_swift").is_empty(): member.remaining=maxf(0,member.remaining-100*sig(a,"pr_swift")[0])
		"bless":
			for member in living(true): _effect(member,"bless",3,.15*(1+sig(a,"pr_bless")[0]/100.0 if not sig(a,"pr_bless").is_empty() else 1)*(1+bonus(a,"buff")))
		"heal":
			for member in living(true): _heal(a,member,.7)
		"acid":
			_effect(e,"defense_down",3,.2); _break(e,12)
			if not sig(a,"al_splash").is_empty():
				var index=data.enemies.find(e)
				for other in living(false):
					if absi(data.enemies.find(other)-index)==1: _effect(other,"defense_down",3,sig(a,"al_splash")[0]/100.0)
		"tonic": _effect(t,"attack_up",3,.15)
		"ruin":
			for foe in living(false):
				_damage(a,foe,.6,0); _effect(foe,"dot",3,a.base.int*.5); _effect(foe,"attack_down",3,.15)
		"blood": a.hp-=hp_cost(a,id); _effect(a,"blood",2,1)
	if a.effects.has("taunt") and not sig(a,"wa_wall").is_empty(): _effect(a,"gear_guard",int(sig(a,"wa_wall")[1]),sig(a,"wa_wall")[0]/100.0)
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
			if q.kind=="regen": _effect(target,"regen",3,a.base[a.line]*2*q.value)
			if q.kind=="guard": _effect(target,"guard",2,q.value)
			if q.kind=="crit": _effect(target,"crit_up",2,q.value)

func _use_supply(item: Dictionary,t: Dictionary) -> bool:
	if t.is_empty() or t.level<item.level or inventory.get(item.id,0)<=0: return false
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
				for key in ["dot","corrosion","bleed","foxflame"]:
					if t.effects.has(key): t.effects.erase(key); count+=1
				if count==0: return false
	inventory[item.id]-=1; events=[]; action_id="supply"; _event(item.name+" → "+t.name); _finish_turn(); return true

func _personal(a: Dictionary,e: Dictionary,t: Dictionary,sk: Dictionary) -> void:
	match a.id:
		"marceline": x(a).cover=t.id
		"naran": _effect(e,"mark",4,1); _break(e,3)
		"teiris":
			a.once=true
			for foe in living(false): _damage(a,foe,1.9,0)
		"haldric":
			for m in living(true):
				if m.row==a.row: _effect(m,"contract",3,.2)
		"erdene":
			a.hp=mini(a.mhp,a.hp+int(x(a).get("prevented",0)*.25)); x(a).prevented=0; _effect(a,"taunt",3)
			for foe in living(false): _effect(foe,"attack_down",2,.15); _break(foe,20)
		"saya": e.remaining+=4000; _break(e,3)
		"gerda":
			var other=_behind(e); _damage(a,e,1.3,3)
			if not other.is_empty(): _damage(a,other,1.3,3,true)
		"judith": _effect(e,"defense_down",3,.2); _effect(e,"attack_down",3,.15); _effect(e,"slow",3,.15); _effect(e,"corrosion",2,a.base.int*1.5); _break(e,3)
		"levia": a.hp-=hp_cost(a,"personal"); _effect(a,"rift_charge",99,1)
		"urda":
			for key in t.effects:
				if key in ["bless","attack_up","guard","duty","haste","next_power"]: t.effects[key].amount*=2
		"lynette":
			for m in living(true): _heal(a,m,.5); _shield(m,a.base.int,2)
		"felice": _heal(a,t,.4); _cleanse(t)
		"sorel":
			for m in living(true): _heal(a,m,1); _effect(m,"regen",3,a.base.int*.6)
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
			_effect(a,"defense_down",1,.2)
		"tove": _break(e,40); _effect(a,"taunt",2)
		"miko": _heal(a,t,1); t.remaining=maxf(0,t.remaining-3000)
		"adeline":
			for m in living(true): _heal(a,m,.4); _effect(m,"adeline_guard",2,.1); _effect(m,"regen",3,a.base.int*.16)
		_: _damage(a,e,1.4 if a.id=="bianca" else 1.2,sk.brk)

func _finish_turn(interval_scale: float=1) -> void:
	var a=ally(current_id)
	if not a.is_empty():
		interval_scale*=1-float(x(a).get("pull",0)); x(a).pull=0
		if a.id=="tika" and action_id in ["attack","personal"] and x(a).get("free",0)>0 and not (action_id=="personal"):
			x(a).free-=1; interval_scale=0
		if a.id=="hedwig" and (int(a.actions)+1)%3==0: _effect(a,"next_power",4,.6)
	super(interval_scale)
	if result.is_empty() and unit(current_id).hp<=0: _finish_turn()

func automatic_turn() -> bool:
	if not result.is_empty(): return false
	var a=ally(current_id)
	if a.is_empty(): return super()
	if not a.charging: return false
	events=[]; action_id="burst"; a.charging=false; _event(a.name+" · 마력 폭발 발동")
	for e in living(false): _damage(a,e,a.skills.burst.power,a.skills.burst.brk)
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
	if t.id=="hildegard" and e.redirected: t.hp=mini(t.mhp,t.hp+int(t.mhp*.04))
	return t

func _enemy_hit(e: Dictionary,a: Dictionary,sk: Dictionary) -> void:
	if a.hp<=0 or e.hp<=0: return
	if _roll(bonus(a,"evade")+(.01 if a.get("nation")=="나에린" else 0)): _event(a.name+" · 회피"); return
	if sk.kind=="spell" and e.effects.has("silence"): _event("마법 봉인 · 행동 취소"); return
	var covered=false
	if has_alive("marceline") and x(ally("marceline")).get("cover")==a.id:
		a=ally("marceline"); x(a).erase("cover"); covered=true
	if a.id=="saya" and _roll(.1):
		_event("사야 · 회피 후 반격"); _damage(a,e,1.5,0,true); return
	var n=e.level-1
	var k=40*(1+data.def_curve.a*n+data.def_curve.b*n*n)
	var defense=a.base.def*(1+fx(a,"bless")+fx(a,"defense_up"))*(1-fx(a,"defense_down"))
	var hit=e.attack*sk.get("m",1)*k/(k+defense)*(1-fx(e,"attack_down"))
	if a.id=="hildegard": hit*=.85
	if a.get("race")=="하프엘프": hit*=.98
	if count_tag("race","하프엘프")>=3: hit*=.98
	var nox=count_tag("race","녹스")
	if nox>=2: hit*=.95 if nox>=3 else .97
	if nox>=3 and a.effects.has("taunt"): hit*=.92
	if count_tag("nation","신성 세레디아 제국")>=2 and a.row=="전열": hit*=.97
	if a.get("nation")=="케른 연방" and a.effects.has("taunt"): hit*=.98
	if a.id=="zahar" and not sk.get("magic",false): hit*=.62
	if a.id=="erdene" and a.effects.has("taunt"): x(a).prevented=x(a).get("prevented",0)+hit*.15; hit*=.85
	if has_alive("haldric"):
		if a.id=="haldric" or ally("haldric").effects.has("taunt"): hit*=.85
		hit*=1-fx(a,"contract")
	if has_alive("adeline"): hit*=1-fx(a,"adeline_guard")
	for key in ["guard","duty"]: hit*=1-fx(a,key)
	hit*=1-fx(a,"gear_guard")
	for member in living(true): hit*=1-fx(member,"wall_party")
	if a.shield>0 and not sig(a,"pa_wrath").is_empty(): hit*=1-sig(a,"pa_wrath")[1]/100.0
	if a.charging and not sig(a,"sa_ward").is_empty():
		var ward=sig(a,"sa_ward"); x(a).charge_damage=x(a).get("charge_damage",0)+hit*ward[0]*ward[1]/10000.0; hit*=1-ward[0]/100.0
	if covered: hit*=.7
	if a.class_id=="gladiator": hit*=1-.1*float(a.hp)/a.mhp
	hit*=1-minf(.8,a.get("gear_fx",{}).get("dr",0)/100.0)
	if has_alive("altan") and sk.get("m",1)>=1.5 and x(ally("altan")).get("refresh",0)<2:
		_shield(a,ally("altan").base.int*2,3); x(ally("altan")).refresh=x(ally("altan")).get("refresh",0)+1
	var damage=maxi(1,int(floor(hit))); var absorbed=mini(a.shield,damage)
	a.shield-=absorbed; damage-=absorbed; a.hp=maxi(0,a.hp-damage)
	if not sig(a,"wa_scar").is_empty():
		var scar=sig(a,"wa_scar"); x(a).scar=minf(a.mhp*scar[1]/100.0,x(a).get("scar",0)+damage*scar[0]/100.0)
	e.hp=maxi(0,e.hp-int(damage*bonus(a,"reflect")))
	if absorbed>0 and a.shield==0:
		var thorns=proc(a,"thorns_shd")
		if not thorns.is_empty(): e.hp=maxi(0,e.hp-int(absorbed*thorns.x/100.0))
		var echo=0.0
		for member in living(true):
			if not sig(member,"pa_echo").is_empty(): echo=maxf(echo,sig(member,"pa_echo")[0]/100.0)
		a.hp=mini(a.mhp,a.hp+int(absorbed*echo))
	_event("%s → %s · %d 피해" % [sk.name,a.name,damage])
	if a.hp==0:
		if not sig(a,"wa_last").is_empty() and not x(a).get("wall_saved",false):
			var wall=sig(a,"wa_last"); x(a).wall_saved=true; a.hp=int(a.mhp*wall[0]/100.0); _effect(a,"wall_party",int(wall[1]),wall[2]/100.0)
		elif a.id=="marceline" and not x(a).get("saved",false):
			x(a).saved=true; a.hp=1+int(a.mhp*.25); _shield(a,a.mhp*.15,3)
		else:
			var priest=false
			for m in living(true):
				if m.class_id=="priest": priest=true
			if priest and not a.ward_used:
				a.ward_used=true; a.hp=int(a.mhp*.5)
				for member in living(true):
					var miracle=sig(member,"pr_miracle")
					if not miracle.is_empty(): a.hp=maxi(a.hp,int(a.mhp*miracle[0]/100.0)); _shield(a,a.mhp*miracle[1]/100.0,3)
			elif has_alive("felice") and not x(ally("felice")).get("revive",false):
				x(ally("felice")).revive=true; x(a).reviving=true; _event("펠리체 · 다음 차례에 소생")
	var stand=proc(a,"last_stand")
	if not stand.is_empty() and a.hp>0 and a.hp<a.mhp*stand.x/100.0 and not x(a).get("stood",false):
		x(a).stood=true; _effect(a,"gear_guard",int(stand.n),.3)
	if a.hp>0 and a.hp<=a.mhp*.25 and has_alive("sorel") and x(ally("sorel")).get("rescue",0)<2:
		x(ally("sorel")).rescue=x(ally("sorel")).get("rescue",0)+1; _heal(ally("sorel"),a,1)

func effects_text(a: Dictionary) -> String:
	if a.hp<=0: return "부상 이탈"
	var names={"taunt":"도발","guard":"방어","duty":"피해 감소","shield":"보호막","bless":"공격·방어 강화","attack_up":"공격 강화","defense_up":"방어 강화","attack_down":"공격 약화","defense_down":"방어 약화","slow":"감속","haste":"가속","regen":"재생","dot":"지속 피해","corrosion":"부식","bleed":"출혈","mark":"확정 치명 표식","foxflame":"여우불","next_power":"다음 공격 강화","magic_amp":"마법 강화","contract":"면책","adeline_guard":"피해 감소","silence":"마법 봉인","rift_charge":"심연 강화","blood":"피의 갈증"}
	var out=[]
	for key in a.effects: out.append(names.get(key,key)+" %d턴" % a.effects[key].turns)
	return " · ".join(out) if not out.is_empty() else "걸린 효과 없음"

func snapshot() -> Dictionary:
	var v=super(); v.schema_version=3; v.extra_state=extra_state.duplicate(true); v.selected_ally=selected_ally
	v.inventory=inventory.duplicate(true)
	return v

func restore(value: Variant) -> bool:
	if not value is Dictionary or value.get("schema_version")!=3 or value.get("build")!=data.build: return false
	if not _shape_valid(value,snapshot()): return false
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
		if v.hp<0 or v.hp>u.mhp or v.remaining<0 or v.remaining>1000000: return false
		if u.has("mp") and (v.mp<0 or v.mp>u.mmp or v.shield<0 or v.shield>100000): return false
		if u.has("gauge") and (v.gauge<0 or v.gauge>u.max or v.act_index<0 or v.act_index>=u.acts.size()): return false
		for key in v.effects:
			var eff=v.effects[key]
			if not eff is Dictionary or not _number(eff.get("turns")) or not _number(eff.get("amount")) or eff.turns<1 or eff.turns>100 or absf(eff.amount)>100000: return false
		for key in value.extra_state[u.id]:
			var cell=value.extra_state[u.id][key]
			if cell is String:
				if cell.length()>100: return false
			elif cell is bool: pass
			elif not _number(cell) or absf(cell)>10000000: return false
	var alive_a=0; var alive_e=0
	for a in data.allies:
		if value.units[a.id].hp>0 or value.extra_state[a.id].get("reviving",false): alive_a+=1
	for e in data.enemies:
		if value.units[e.id].hp>0: alive_e+=1
	if (value.result=="victory")!=(alive_e==0) or (value.result=="defeat")!=(alive_a==0): return false
	for u in data.allies+data.enemies:
		for key in value.units[u.id]: u[key]=value.units[u.id][key].duplicate(true) if value.units[u.id][key] is Dictionary else value.units[u.id][key]
	current_id=value.current_id; last_ally=value.last_ally; selected_enemy=value.selected_enemy; selected_action=value.selected_action; selected_ally=value.selected_ally
	result=value.result; rng_state=int(value.rng); turn_count=int(value.turn_count); history=value.history.duplicate(); events=value.events.duplicate(); extra_state=value.extra_state.duplicate(true)
	inventory=value.inventory.duplicate(true)
	refresh_forecast(); return true
