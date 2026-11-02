extends "res://game/battle_v3.gd"
# Read-only baseline 72bf1b2efbd090aca4ab6318e07ae0057922dcac blob b336ee32adc7931db2e7884e20298955a57af29a
func _enemy_hit(e: Dictionary,a: Dictionary,sk: Dictionary) -> void:
	last_enemy_hit_target=""
	if a.hp<=0 or e.hp<=0: return
	# Ordinary attacks also visit Felice's evade hook before the global roll.
	if dungeon_enemy_r21!=null: _felice_scan()
	if _roll(bonus(a,"evade")+(.01 if a.get("nation")=="나에린" else 0)): _event(a.name+" · 회피"); return
	if sk.kind=="spell" and e.effects.has("silence"): _event("마법 봉인 · 행동 취소"); return
	var covered=false
	if has_alive("marceline") and x(ally("marceline")).get("cover")==a.id:
		a=ally("marceline"); x(a).erase("cover"); covered=true
	if a.id=="saya" and _roll(.1):
		_event("사야 · 회피 후 반격"); _damage(a,e,1.5,0,true); return
	last_enemy_hit_target=a.id
	var n=e.level-1
	var k=40*(1+data.def_curve.a*n+data.def_curve.b*n*n)
	var defense=a.base.def*(1+fx(a,"bless")+fx(a,"defense_up")-fx(a,"defense_down")) if dungeon_enemy_r21!=null else a.base.def*(1+fx(a,"bless")+fx(a,"defense_up"))*(1-fx(a,"defense_down"))
	var hit=e.attack*sk.get("m",1)*k/(k+defense)*(1-fx(e,"attack_down"))
	if dungeon_enemy_r21!=null: hit=maxi(1,int(floor(hit*dungeon_enemy_r21.attack_mult(e))))
	_incoming_strike(a,hit,e,sk,covered)

func _incoming_strike(a: Dictionary,hit: float,e: Dictionary,sk: Dictionary,covered=false,fixed=false) -> void:
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
