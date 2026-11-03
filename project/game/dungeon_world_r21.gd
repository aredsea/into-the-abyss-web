extends "res://game/expansion_world.gd"
## New expeditions use the source floor state machine; existing runs finish unchanged.
const RulesR21=preload("res://game/dungeon_rules_r21.gd")
var dungeon_rules=RulesR21.new()
var selected_floor=1
var selected_rift=""
var selected_stars=1
const CombatGear=preload("res://game/gear_rules_r22.gd")
const CombatGearSave=preload("res://game/gear_save_r22.gd")
static var combat_gear_rules=CombatGear.new()
static var combat_gear_adapter=CombatGearSave.new()

func _init():
	super()
	ensure_dungeon()

func ensure_dungeon():
	if not s.has("dungeon_r21"): s.dungeon_r21={"best":0,"cleared_bosses":[],"runs":0,"sel":1}
	var source={"dungeon":s.dungeon_r21.duplicate(true)}
	var normalized=normalize_dungeon_record(source)
	# Native/cloud saves retain their established field allowlist. Source-only
	# defaults belong to the transient source record, not to persisted state.
	for key in s.dungeon_r21:
		# JSON restores numeric fields as floats. Preserve their existing type
		# when the value is valid so exact cloud roundtrips remain unchanged.
		if normalized.has(key) and s.dungeon_r21[key]!=normalized[key]:s.dungeon_r21[key]=normalized[key]
	selected_floor=int(s.dungeon_r21.sel)

func normalize_dungeon_record(g: Dictionary) -> Dictionary:
	# 76-dungeon.dn_G mutates and returns the same record. Save validation still
	# rejects invalid native saves before adoption; this never discards a save.
	if not g.get("dungeon") is Dictionary:g.dungeon={}
	var d=g.dungeon
	for pair in [["best",0],["runs",0],["sel",1],["pg",1]]:
		var n=preload("res://game/battle_stats_r23.gd").number(d.get(pair[0]),pair[1])
		d[pair[0]]=maxi(pair[1],int(floor(n)))
	d.mode=1 if (d.get("mode") is int or d.get("mode") is float) and d.mode==1 else 0
	if not (d.get("cleared_bosses") is Array or d.get("cleared_bosses") is Dictionary):d.cleared_bosses=[]
	if d.has("run") and not (d.run is Dictionary or d.run is Array):d.erase("run")
	return d

func r21() -> bool: return s.run.get("data_version",0)==21

func depart_rift_quest(q: Dictionary,seed: int=0) -> bool:
	# Branch D supplies the accepted source quest (26-start / 72-guild contract).
	var rid=""
	for r in dungeon_rules.config.rifts:
		if q.get("rift","") in [r.name,r.quest_name]: rid=r.id; break
	if rid.is_empty() or not q.get("cmp",false): return false
	var level=clampi(int(q.get("lv",highest_level()+dungeon_rules.config.quest_difficulty[dungeon_rules.quest_difficulty(q)].delta)),1,40)
	if not depart_dungeon(1,seed,rid,int(q.get("stars",1))): return false
	s.run.source_quest=q.duplicate(true); s.run.quest_level=level
	# The source town has an immutable seed; the web world has a saved RNG state.
	# D may supply that source seed explicitly; otherwise retain the entry state.
	s.run.quest_seed=int(q.get("town_seed",s.rng))
	return true
func dungeon_max() -> int:
	var m=int(s.dungeon_r21.best)+1
	for i in range(dungeon_rules.config.zone_order.size()-1):
		if dungeon_rules.config.zone_order[i] in s.dungeon_r21.cleared_bosses: m=maxi(m,3*(i+1)+1)
	return m

func dungeon_allowed(f: int) -> bool:
	return f>=1 and f<=dungeon_max()

func dungeon_floor_view(f: int,avg: float=1.0) -> Dictionary:
	var info=dungeon_rules.floor_info(f);var zone=dungeon_rules.zones[info.zone]
	var kind=dungeon_rules.floor_boss_kind(info)
	var out={"info":info,"zone":zone,"boss_kind":kind,"el":dungeon_rules.floor_level(avg,info),"star":dungeon_rules.floor_star(info),"reward":dungeon_rules.floor_mult(f).reward}
	if kind=="boss":out.lead=zone.boss
	return out

func depart_dungeon(f: int,seed: int=0,rift_id: String="",stars: int=1) -> bool:
	if active() or f<1 or (rift_id.is_empty() and not dungeon_allowed(f)) or (not rift_id.is_empty() and not dungeon_rules.rifts.has(rift_id)): return false
	if not rift_id.is_empty():
		var r=dungeon_rules.rifts[rift_id]
		if stars<r.star_min or stars>r.star_max: return false
	var town_gear=gear;gear=combat_gear_rules
	s.runs+=1; s.summary={}
	var rng_seed=seed if seed>0 else int(floor(next_random()*2147483646))+1
	s.run={"phase":"explore","step":0,"gold":0,"xp":0,"wins":0,"event":"","resolved":true,"final":false,"battle":{},"rested":false,"id":s.runs,"rules_version":3,"data_version":21,
		"floor":f,"seed":rng_seed,"rift_id":rift_id,"stars":stars,"elites":0,"kind":"battle","loot_items":{},"loot_gear":[],"last":"入場"}
	if not rift_id.is_empty(): s.run.phase="battle"; s.run.kind="boss"; s.run.final=true
	s.dungeon_r21.sel=f
	for id in s.party:
		var b=stats(id,s.members[id].level); s.members[id].hp=b.hp; s.members[id].mp=b.mp
	note(dungeon_title()+" 출발")
	gear=town_gear
	return true

func dungeon_title() -> String:
	if not s.run.get("rift_id","").is_empty(): return dungeon_rules.rifts[s.run.rift_id].quest_name
	var info=dungeon_rules.floor_info(int(s.run.get("floor",selected_floor)))
	return dungeon_zone_title(info)+" · %d층"%info.floor
func dungeon_zone_title(info: Dictionary) -> String:
	var text=preload("res://game/localization_r22.gd");var lang=text.language(s)
	var suffix=(" Depth %d"%info.dc if lang=="en" else text.u(" 심층 {n}",{"n":info.dc})) if info.dk>0 else ""
	return text.t(dungeon_rules.zones[info.zone].name,lang)+suffix

func party_classes() -> Array: return s.party.map(func(id):return class_def(id).id)
func average_level() -> float:
	var avg=0.0
	for id in s.party: avg+=s.members[id].level/float(s.party.size())
	return avg

func encounter_plan() -> Dictionary:
	var r=s.run
	var seed=dungeon_rules.battle_seed(int(r.seed),int(r.floor),int(r.step),r.final)
	if r.rift_id.is_empty(): return dungeon_rules.floor_enc(int(r.floor),average_level(),s.party.size(),r.kind,seed)
	var fight=dungeon_rules.quest_fight(r.source_quest) if r.has("source_quest") else "core"
	var enc=dungeon_rules.compose(seed,{"rift_id":r.rift_id,"stars":r.stars,"party_n":s.party.size(),"kind":"rift_core" if fight=="core" else fight})
	return {"enc":enc,"el":r.get("quest_level",clampi(int(floor(average_level()+.5)),1,40)),"star":enc.star}

func advance() -> bool:
	if not r21(): return super()
	var r=s.run
	if not active() or r.phase!="explore" or r.step>=dungeon_rules.config.explore.STEPS: return false
	r.step+=1
	var out=dungeon_rules.ex_roll(int(r.seed),int(r.floor),int(r.step),int(r.elites),party_classes())
	r.event=out.kind
	if out.kind in ["battle","elite"]:
		if out.kind=="elite": r.elites+=1
		r.kind=out.kind; r.phase="battle"; r.battle={}; r.resolved=false
	else:
		if out.kind=="coin": r.gold+=out.gold; r.last="주화 %d닢 발견"%out.gold
		elif out.kind=="item": r.loot_items[out.item]=r.loot_items.get(out.item,0)+1; r.last=item_def(web_item_id(out.item)).get("name",out.item)+" 발견"
		else: r.loot_gear.append(out.code); r.last="장비 발견 · "+out.rarity
		note(r.last)
		if r.step>=dungeon_rules.config.explore.STEPS: enter_dungeon_rest()
	return true

func enter_dungeon_rest():
	s.run.phase="rest"
	# Source heals on entering rest, including downed members. The button only continues.
	if s.run.rested: return
	s.run.rested=true
	for id in s.party:
		var m=s.members[id]; var b=stats(id,m.level)
		m.hp=mini(b.hp,m.hp+int(floor(b.hp*dungeon_rules.config.explore.REST_HP+.5)))
		m.mp=mini(b.mp,m.mp+int(floor(b.mp*dungeon_rules.config.explore.REST_MP+.5)))
	note("휴식: HP 30% · MP 60% 회복")

func rest() -> bool:
	if not r21(): return super()
	return active() and s.run.phase=="rest" and s.run.rested

func final_battle() -> bool:
	if not r21(): return super()
	if not active() or s.run.phase!="rest" or not s.run.rested: return false
	s.run.phase="battle"; s.run.final=true; s.run.kind="boss"; s.run.battle={}
	return true

func battle_data() -> Dictionary:
	var town_gear=gear
	if r21(): gear=combat_gear_rules
	var d=super()
	if not r21(): return d
	# P4 initializes from pre-equipment stats once. The displayed/world stats
	# already include equipment, so preserve current vitals separately.
	var worn=s.equipment; s.equipment={}
	for a in d.allies:
		var raw=stats(a.id,int(a.level))
		a.base=raw; a.mhp=raw.hp; a.mmp=raw.mp
		a.gear_fx={}; a.gear_special=[]
		a.gear_member=combat_gear_adapter.battle_member({"equipment":worn,"gear":s.gear},a.id,a.class_id,int(a.level))
		if not a.gear_member.native_eq.is_empty():
			a.gear_vitals={"hp":a.hp,"mp":a.mp}; a.hp=raw.hp; a.mp=raw.mp
	s.equipment=worn
	var plan=encounter_plan(); d.encounter_r21=plan; d.floor=s.run.floor if s.run.rift_id.is_empty() else 0
	d.location=dungeon_rules.zones[plan.enc.zone].name if s.run.rift_id.is_empty() else dungeon_rules.rifts[s.run.rift_id].quest_name
	d.build="r21-a-data-20261031-%d-%d-%s"%[s.run.id,s.run.step,str(s.run.final)]
	d.seed=dungeon_rules.battle_seed(int(s.run.seed),int(s.run.floor),int(s.run.step),s.run.final)
	d.enemy_power_r21=clampf(float(s.run.source_quest.get("strength",1.5)),1.5,2) if s.run.has("source_quest") and dungeon_rules.quest_difficulty(s.run.source_quest)=="엘리트" else 1.0
	d.enemies=make_enemies(plan,d.allies)
	d.queue=[]
	# P4's battle adapter must not replace P6's long-lived smithy facade.
	gear=town_gear
	return d

func make_enemies(plan: Dictionary,allies: Array) -> Array:
	var out=[]; var enc=plan.enc
	for i in range(enc.ne):
		var entry=make_enemy(enc,i,int(plan.el),allies,enc.fl[i] if i<enc.fl.size() else "")
		out.append(entry)
	return out

func make_enemy(enc: Dictionary,index: int,level: int,allies: Array,foe_id: String,phase: int=1) -> Dictionary:
	var slot=["executor","apprentice","orb","lantern"][index] if index<4 else "r21_slot_"+str(index+1)
	# Reserved summon slots are full source-backed units with HP 0 until summoned.
	var empty=foe_id.is_empty(); var f=dungeon_rules.foes["apprentice_doll" if empty else foe_id]
	var local_enc=enc.duplicate(true)
	while local_enc.fl.size()<=index: local_enc.fl.append(""); local_enc.fg.append("minion")
	local_enc.fl[index]=f.id
	var d=dungeon_rules.foe_def(local_enc,index,level); var value=dungeon_rules.foe_stats(enc,d,level)
	var power=clampf(float(s.run.source_quest.get("strength",1.5)),1.5,2) if s.run.has("source_quest") and dungeon_rules.quest_difficulty(s.run.source_quest)=="엘리트" else 1.0
	value.hp*=power; value.atk*=power
	var h=maxi(1,int(floor(value.hp+.5))); var art=art_for(f.id)
	var entry={"id":slot,"foe_id":"" if empty else f.id,"name":d.name,"short":d.name,"row":"전열" if d.row=="front" else "후열","role":d.role,"grade":d.grade,"weak":d.weak.duplicate(),"gauge":float(value.ay),"max":float(value.ay),
		"hp":0 if empty else h,"mhp":h,"attack":value.atk,"defense":value.de,"speed":value.sp,"level":level,"acts":d.acts.duplicate(true),"rules":d.get("rules",{}).duplicate(true),
		"act_index":0,"charged":false,"remaining":0.0 if d.get("rules",{}).get("first_move",false) else 10000.0,"target_id":"",
		"art":art.path,"bbox":art.bbox,"art_fallback":art.fallback,"phase":phase,"intent":"","target":"","kind":"","state":"","hint":"","top":"","aim":"","w":82,"h":100}
	if phase==2 and d.has("phase2"):
		entry.acts=d.phase2.acts.duplicate(true); entry.weak=d.phase2.weak.duplicate()
	return entry

func art_for(id: String) -> Dictionary:
	var f=dungeon_rules.foes[id]
	if ResourceLoader.exists(f.art):
		var texture=load(f.art)
		return {"path":f.art,"bbox":[0,0,texture.get_width(),texture.get_height()],"fallback":false}
	var legacy="lantern" if f.role in ["지원","소환"] else "orb" if f.role in ["사격","주술"] else "executor" if f.role=="방어" or f.grade in ["elite","boss","core","chief"] else "apprentice"
	var e=template.enemies.filter(func(x):return x.id==legacy)[0]
	return {"path":e.art,"bbox":e.bbox.duplicate(),"fallback":true}

func finish_battle() -> bool:
	if not r21(): return super()
	if not active() or s.run.phase!="battle" or s.run.battle.is_empty(): return false
	var battle=ModernBattle.new(battle_data())
	if not battle.restore(s.run.battle) or battle.result.is_empty(): return false
	for id in s.party:
		var a=battle.ally(id); s.members[id].hp=a.hp if a.hp>0 else maxi(1,int(floor(a.mhp*dungeon_rules.config.explore.DOWN_HP)))
		s.members[id].mp=a.mp
	if battle.result=="defeat": return settle("defeat")
	var plan=battle.data.encounter_r21; var enc=plan.enc
	var gold_value=dungeon_rules.gold(int(s.run.floor),enc.kind)
	if not s.run.final: gold_value=int(floor(gold_value*(dungeon_rules.config.explore.GOLD_ELITE if s.run.kind=="elite" else dungeon_rules.config.explore.GOLD_BATTLE)+.5))
	if not s.run.rift_id.is_empty(): gold_value=dungeon_rules.quest_gold(s.run.source_quest,int(plan.el)) if s.run.has("source_quest") else 0
	var qmult=dungeon_rules.config.quest_difficulty[dungeon_rules.quest_difficulty(s.run.source_quest)].reward if s.run.has("source_quest") and s.run.source_quest.get("reward_v",0)==2 else 1.0
	var xp=dungeon_rules.exp_reward(enc,int(plan.el),qmult)
	s.run.gold+=gold_value; s.run.xp+=xp
	if not s.run.final: s.run.wins+=1
	var drop_kind=enc.kind if s.run.final else s.run.kind
	if not s.run.rift_id.is_empty() and s.run.has("source_quest") and dungeon_rules.quest_difficulty(s.run.source_quest)=="엘리트":
		s.run.loot_gear.append_array(dungeon_rules.quest_gear(int(s.run.get("quest_seed",s.run.seed)),s.run.source_quest,party_classes()))
	elif s.run.rift_id.is_empty() and drop_kind in ["elite","chief","boss"]:
		var seed=RulesR21.mix(int(s.run.seed),int(s.run.floor),99 if s.run.final else int(s.run.step),22 if s.run.final else 21)
		if RulesR21.mix(int(seed),31,0,0)<dungeon_rules.config.gear_drop.chance.get(drop_kind,0):
			var drop=dungeon_rules.gear_drop(int(floor(RulesR21.mix(int(seed),32,0,0)*2147483646))+1,int(s.run.floor),drop_kind,party_classes())
			if not drop.is_empty(): s.run.loot_gear.append(drop.code)
	if s.run.final: return settle("clear")
	s.run.phase="explore"; s.run.resolved=true; s.run.battle={}; s.run.last="전투 승리 · 금화 %d"%gold_value
	if s.run.step>=dungeon_rules.config.explore.STEPS: enter_dungeon_rest()
	return true

func settle(result: String) -> bool:
	if not r21(): return super(result)
	if not active() or result not in ["clear","retreat","defeat"] or (result=="retreat" and s.run.phase not in ["explore","rest"]): return false
	var r=s.run; var amount=0 if result=="defeat" else int(r.gold); var xp=0 if result=="defeat" else int(r.xp); var penalty=0; var gains=[]
	if result=="defeat": penalty=int(floor(mini(s.gold,100*clampi(int(encounter_plan().star),1,4))/2.0)); s.gold-=penalty
	else:
		for id in r.loot_items:
			var key=web_item_id(id); s.items[key]=s.items.get(key,0)+r.loot_items[id]
		for code in r.loot_gear:
			var entry=combat_gear_adapter.source_drop({"code":code},int(s.serial)+1)
			# In-flight r21 saves may still contain the old two-part loot token.
			# Keep its legacy option RNG; only new versioned codes are source_r21.
			if entry.is_empty():
				var parts=code.split(".")
				if parts.size()==2 and gear.by_id.has(parts[0]) and not parts[1].is_empty():
					var n=0; var valid=true
					for ch in parts[1]:
						var digit="0123456789abcdefghijklmnopqrstuvwxyz".find(ch)
						if digit<0: valid=false; break
						n=n*36+digit
					if valid: entry={"uid":int(s.serial)+1,"id":parts[0],"seed":n,"forge":0,"tries":0}
			if entry.is_empty(): continue
			var worn=[]
			for eq in s.equipment.values():worn.append_array(eq.values())
			if s.gear.filter(func(e):return e.uid not in worn).size()<2000:s.serial+=1; s.gear.append(entry)
	s.gold+=amount
	for id in s.party:
		var m=s.members[id]; var before=m.level; m.xp+=xp
		if result!="defeat":
			var A=dungeon_rules.config.affection; var amount_aff=A.QUEST if not r.rift_id.is_empty() and result=="clear" else r.wins*A.BATTLE+(A.BOSS if result=="clear" else 0)
			var room=maxf(0,A.SOFT-m.aff)
			m.aff=minf(A.MAX,snappedf(m.aff+amount_aff if amount_aff<=room else maxf(m.aff,A.SOFT)+(amount_aff-room)*A.SLOW,.01))
		while m.level<40 and m.xp>=need(m.level): m.xp-=need(m.level); m.level+=1
		if m.level==40: m.xp=0
		gains.append({"id":id,"before":before,"level":m.level,"xp":m.xp})
	if result!="defeat": s.dungeon_r21.runs+=1
	if result=="clear" and r.rift_id.is_empty():
		var info=dungeon_rules.floor_info(int(r.floor)); s.dungeon_r21.best=maxi(s.dungeon_r21.best,r.floor)
		if info.dk==0 and info.ord>=3 and info.zone not in s.dungeon_r21.cleared_bosses: s.dungeon_r21.cleared_bosses.append(info.zone)
		s.dungeon_r21.sel=mini(dungeon_max(),r.floor+1)
	s.summary={"result":result,"gold":amount,"xp":xp,"wins":r.wins,"lost":r.gold if result=="defeat" else 0,"gains":gains,"floor":r.floor,"penalty":penalty}
	r.phase="done"; r.battle={}; r.loot_items={}; r.loot_gear=[]; s.day+=1
	note("원정 정산: 금화 %d · 경험치 %d"%[amount,xp]); return true

func web_item_id(id: String) -> String:
	return {"sh_s":"shield_s","sh_m":"shield_m","sh_l":"shield_l"}.get(id,id)

func restore(value: Variant) -> bool:
	if not value is Dictionary: return false
	var candidate=value.duplicate(true); var is_new=candidate.get("run",{}).get("data_version",0)==21
	if candidate.has("dungeon_r21"):
		var d=candidate.dungeon_r21
		if not _shape(d,{"best":0,"cleared_bosses":[],"runs":0,"sel":1}) or d.best<0 or d.best!=floor(d.best) or d.sel<1 or d.sel!=floor(d.sel) or d.runs<0: return false
	if is_new:
		var r=candidate.run
		if not _shape(r,{"floor":1,"seed":1,"rift_id":"","stars":1,"elites":0,"kind":"","loot_items":{},"loot_gear":[],"last":""}): return false
		if r.floor<1 or r.floor!=int(r.floor) or r.seed<1 or r.seed>=2147483647 or r.step<0 or r.step>5 or r.wins<0 or r.wins>6 or r.elites<0 or r.elites>2 or r.kind not in ["battle","elite","boss"]: return false
		if not r.rift_id.is_empty() and not dungeon_rules.rifts.has(r.rift_id): return false
	# The parent only knows legacy runs with <=2 wins. Validate common fields using
	# a temporary empty run, then validate the source-backed run and battle here.
	var run=candidate.get("run",{}).duplicate(true)
	if is_new: candidate.run={}
	var previous=s.duplicate(true)
	# Parent accepts extra keys, but its required shape must not require new keys.
	s.erase("dungeon_r21")
	if not super(candidate): s=previous; return false
	if is_new: s.run=run
	ensure_dungeon()
	var d=s.dungeon_r21
	if not _shape(d,{"best":0,"cleared_bosses":[],"runs":0,"sel":1}) or d.best<0 or d.sel<1 or d.sel>dungeon_max() or d.runs<0: s=previous; return false
	for z in d.cleared_bosses:
		if z not in dungeon_rules.config.zone_order: s=previous; return false
	if is_new:
		if not _shape(run,{"phase":"","step":0,"gold":0,"xp":0,"wins":0,"event":"","resolved":true,"final":false,"battle":{},"rested":false,"id":0}) or run.phase not in ["explore","battle","rest","done"] or run.id!=s.runs or run.gold<0 or run.xp<0: s=previous; return false
		if run.phase=="battle" and not run.battle.is_empty():
			var b=ModernBattle.new(battle_data())
			if not b.restore(run.battle): s=previous; return false
	return true
