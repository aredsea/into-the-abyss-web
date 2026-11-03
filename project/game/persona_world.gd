extends "res://game/town_world_r21.gd"
## Additive P1 facade. Battle files, assets and the legacy world remain untouched.
const PersonaRules=preload("res://game/persona_rules.gd")
const Adapter=preload("res://game/persona_save_adapter.gd")
const LegacyWorld=preload("res://game/town_world_r21.gd")
var persona_rules=PersonaRules.new()
var seed_source: Callable

func _init() -> void:
	super()
	s.schema=3;s.gold=300;s.owned=[];s.party=[];s.hand=[]
	for id in s.items:s.items[id]=0
	s.persona={"name":"","race":"","lineage":"","nation":"","cls":"","stats":{},"fight":1,"lv":1,"exp":0,"bonus_total":5,"bonus_custom":0,"skill":{"prefix":"","suffix":"","prefix_lv":{},"suffix_lv":{}}}
	s.creation_r22={"complete":false,"legacy":false};s.scene="create";s.ui={"page":1,"sel":"","msg":""};s.scenario="";s.xp_r22={}
	persona_rules.prepare(s.persona)
	s.erase("persona_progress_r21")
	ensure_persona_member()

func ensure_persona_member() -> void:
	if not s.members.has("persona"):s.members.persona={"level":s.persona.lv,"xp":s.persona.exp,"aff":0.0,"hp":1,"mp":0}
	if not s.equipment.has("persona"):s.equipment.persona={}
	if not s.research.has("persona"):s.research.persona=s.persona.skill.duplicate(true)
	if not s.has("persona_research_r22"):s.persona_research_r22={}

func research_work(who: String) -> Dictionary:
	if who!="persona":return super(who)
	return PersonaResearch.draft_work(s.persona.skill,{"psd":s.persona_research_r22.draft} if s.persona_research_r22.has('draft') else {})

func research_dirty(who: String) -> bool:
	if who!="persona":return super(who)
	return PersonaResearch.draft_dirty(s.persona.skill,{"psd":s.persona_research_r22.draft} if s.persona_research_r22.has('draft') else {})

func research_action(who: String,arg: String) -> bool:
	if who!="persona":return super(who,arg)
	if active():return false
	var e=s.persona_research_r22
	var out=PersonaResearch.transition(s.persona.skill,e.get("draft",{}),int(e.get("spent",0)),int(s.gold),arg)
	research_message=out.message
	var changed=out.saved!=s.persona.skill or out.draft!=e.get("draft",{}) or out.gold!=s.gold
	if not changed:return false
	s.persona.skill=out.saved;s.gold=out.gold
	s.persona_research_r22={} if out.draft.is_empty() else {"draft":out.draft,"spent":out.spent}
	return true

func create_action(arg: String,kind="cr") -> bool:
	if s.creation_r22.complete:return false
	var g={"persona":s.persona,"scene":s.scene,"ui":s.ui,"scenario":s.scenario,"roster":s.owned,"party":s.party,"gold":s.gold}
	s.ui.msg="";persona_rules.create_action(g,arg,kind,preload("res://game/localization_r22.gd").language(s))
	s.scene=g.scene;s.scenario=g.scenario;s.owned=g.roster;s.party=g.party;s.gold=g.gold
	if s.scene=="town":
		s.creation_r22.complete=true
		for id in s.owned:
			s.members[id].level=s.persona.lv;s.members[id].xp=0;s.members[id].aff=0.0
			var b=stats(id,int(s.persona.lv));s.members[id].hp=b.hp;s.members[id].mp=b.mp
		var b=stats("persona",int(s.persona.lv));s.members.persona.hp=b.hp;s.members.persona.mp=b.mp
		s.rng=seed_source.call() if seed_source.is_valid() else persona_rules.new_seed(int(floor(Time.get_unix_time_from_system())),Time.get_ticks_usec(),randi_range(1,2147483646));s.town_r21.seed=s.rng;s.town_r21.counter=0;s.town_r21.qn=0;refill_board()
	return true

func person(id: String) -> Dictionary:
	if id!="persona" or not s or not s.has("persona"):return super(id)
	var p=s.persona;var c=persona_rules.cls(p.cls)
	return {"id":"persona","name":"당신" if p.name in ["","{{user}}"] else p.name,"class":p.cls,"row":c.get("row","전열"),"race":p.race,"nation":p.nation,"lineage":p.lineage,"element":"none","mod":{},"trait":{"p":{}},"skill":{},"full_name":"당신"}

func stats(id: String,level: int) -> Dictionary:
	if id!="persona":return super(id,level)
	var p=s.persona;var c=class_def(id)
	if c.is_empty():return {"hp":1,"mp":0,"str":0,"agi":0,"int":0,"def":0,"spd":1,"crit":0}
	var out={};var x=clampi(level,1,40)-1;var made=p.stats
	for key in ["hp","mp","str","agi","int","def"]:
		var curve=config.curves[key if key in ["hp","mp","def"] else "atk"]
		var base=c.base[key]*(1+c.grow.get(key,1)*(curve.a*x+curve.b*x*x))
		if key in ["hp","mp"]:base=floor(base+.5)
		base*=float(made.get(key,c.base[key]))/float(c.base[key]) if c.base[key]>0 else 1.0
		out[key]=int(floor(base+.5)) if key in ["hp","mp"] else base
	out.spd=made.get("spd",c.base.spd)+config.curves.spd.add*x;out.crit=c.base.crit
	if p.race=="엘프":out.mp+=6
	if p.nation=="신성 세레디아 제국":out.def*=1.04
	var humans=party_count("race","인간")
	if humans>=2:out.hp=int(floor(out.hp*(1.07 if humans>=3 else 1.04)+.5))
	var equipped=gear_bonus(id,level)
	var main={"힘":"str","민첩":"agi","지능":"int"}[c.line]
	for key in ["hp","mp","str","agi","int","def"]:
		out[key]*=1+equipped.get(key,0)/100.0+(equipped.get("stat",0)/100.0 if key==main else 0)
		if key in ["hp","mp"]:out[key]=int(floor(out[key]+.5))
	out.spd*=1+equipped.get("spd",0)/100.0
	return out

func party_count(key: String,value: String) -> int:
	var ids=(s.run.persona_party if active() and s.run.has("persona_party") else sortie_ids()) if s.has("persona") else s.party
	var seen=[];var count=0
	for id in ids:
		if id not in seen and person(id).get(key)==value:count+=1
		seen.append(id)
	return count

func sortie_ids() -> Array:
	var ids=s.party.duplicate()
	if s.persona.fight==1:ids.push_front("persona")
	return ids
func can_persona_fight() -> bool:
	return not class_def("persona").is_empty()
func set_fight(fight: int) -> bool:
	if active() or fight not in [0,1]:return false
	if fight==1 and not can_persona_fight():return false
	s.party=persona_rules.clean(s.party,s.owned,int(s.persona.fight),config.companions.map(func(c):return c.id))
	s.persona.fight=fight
	if fight==1 and s.party.size()>3:
		var drop=s.party.pop_back();var ui=preload("res://game/expedition_ui_r23.gd").new();ui.lang=preload("res://game/localization_r22.gd").language(s)
		s.ui.msg=ui.u("출전이 4명이 되어 마지막 동료 {name:은는} 대기로 돌렸습니다.",{"name":person(drop).name})
	return true
func toggle_companion(id: String) -> bool:
	if active() or id not in s.owned:return false
	if id in s.party:s.party.erase(id);return true
	if s.party.size()>=(3 if s.persona.fight==1 else 4):
		var ui=preload("res://game/expedition_ui_r23.gd").new();ui.lang=preload("res://game/localization_r22.gd").language(s)
		s.ui.msg=ui.u("출전 자리가 찼습니다(최대 {cap}명). 한 명을 빼고 다시 고르세요.",{"cap":3 if s.persona.fight==1 else 4});return false
	s.party.append(id);return true
func sortie_candidates(filter="") -> Array:
	var ids=s.owned.filter(func(id):return filter=="" or person(id).row==("전열" if filter=="front" else "후열"))
	var order=config.companions.map(func(c):return c.id)
	ids.sort_custom(func(a,b):
		if (a in s.party)!=(b in s.party):return a in s.party
		if s.members[a].level!=s.members[b].level:return s.members[a].level>s.members[b].level
		return order.find(a)<order.find(b))
	return ids
func party_classes() -> Array:return sortie_ids().map(func(id):return class_def(id).id)
func average_level() -> float:
	var ids=sortie_ids();var value=0.0
	for id in ids:value+=s.members[id].level
	return value/maxi(1,ids.size())
func depart_dungeon(f: int,seed: int=0,rift_id: String="",stars: int=1) -> bool:
	if not s.creation_r22.complete or sortie_ids().is_empty():return false
	if s.persona.fight==1 and not can_persona_fight():return false
	var result=super(f,seed,rift_id,stars)
	if result:
		s.run.persona_party=sortie_ids();s.run.persona_pm=source_pm()
		var b=stats("persona",int(s.persona.lv));s.members.persona.hp=b.hp;s.members.persona.mp=b.mp
	return result
func source_pm() -> Array:
	var out=[]
	for id in sortie_ids():
		var entry={"id":id,"cls":class_def(id).id,"L":s.members[id].level}
		if id=="persona":entry.merge({"race":s.persona.race,"lin":s.persona.lineage,"nat":s.persona.nation,"ps":s.persona.stats.duplicate(true),"skill":s.persona.skill.duplicate(true)})
		out.append(entry)
	while out.size()<4:out.append({"id":"","cls":"","L":1})
	return out
func battle_data() -> Dictionary:
	if not s.has("persona") or not s.run.has("persona_party"):return super()
	var party=s.party;s.party=s.run.persona_party.duplicate()
	var d=super();s.party=party
	for ally in d.allies:
		if ally.id=="persona":
			ally.skills.erase("personal");ally.skills.erase("tactic");ally.trait={"p":{}}
			if not ally.skills.has("guard"):ally.skills.guard={"name":"방어","mp":0,"target":"자신","power":.4,"turns":1,"brk":0,"note":"다음 자기 차례까지 받는 피해 −40%"}
			var signature=preload("res://game/persona_combat_r22.gd").action(s.run.persona_pm[0].get("skill",{}))
			if not signature.is_empty():ally.skills.personal=signature
	d.persona_pm=s.run.persona_pm.duplicate(true)
	return d

func finish_battle() -> bool:
	var before_xp=int(s.run.get("xp",0))
	if s.run.has("persona_party") and "persona" in s.run.persona_party and not s.run.get("battle",{}).is_empty():
		var b=ModernBattle.new(battle_data())
		if not b.restore(s.run.battle) or b.result.is_empty():return false
		var a=b.ally("persona")
		s.members.persona.hp=a.hp if a.hp>0 else maxi(1,int(floor(a.mhp*dungeon_rules.config.explore.DOWN_HP)))
		s.members.persona.mp=a.mp
	var result=super()
	if result and s.run.has("persona_party") and s.run.phase!="done":
		var gained=int(s.run.xp)-before_xp
		award_persona_exp({"exp":gained,"sid":int(s.run.id)*32+int(s.run.step)*2,"pm":s.run.persona_pm})
		s.run.persona_xp_paid=int(s.run.xp)
	return result

func enter_dungeon_rest():
	var was_rested=s.run.get("rested",false)
	super()
	if not was_rested and s.run.has("persona_party") and "persona" in s.run.persona_party:
		var b=stats("persona",int(s.persona.lv));var m=s.members.persona
		m.hp=mini(b.hp,m.hp+int(floor(b.hp*dungeon_rules.config.explore.REST_HP+.5)))
		m.mp=mini(b.mp,m.mp+int(floor(b.mp*dungeon_rules.config.explore.REST_MP+.5)))

func award_persona_exp(st: Dictionary) -> Dictionary:
	# Source town defaults are transient. xp_r22 persists only its established
	# award marker; no source-only day/acts/bn fields enter cloud saves.
	var town=s.xp_r22.duplicate(true);town.bn=int(s.run.get("id",0))
	var g={"persona":s.persona,"roster":s.owned,"party":s.party,"lvl":{},"exp":{},"town":town}
	for id in s.owned:g.lvl[id]=s.members[id].level;g.exp[id]=s.members[id].xp
	var gains=persona_rules.award(g,st)
	if town.has("xp_bn"):s.xp_r22.xp_bn=town.xp_bn
	for id in s.owned:s.members[id].level=g.lvl[id];s.members[id].xp=g.exp[id]
	s.members.persona.level=s.persona.lv;s.members.persona.xp=s.persona.exp
	return gains

func settle(result: String) -> bool:
	var total_xp=maxi(0,int(s.run.get("xp",0))-int(s.run.get("persona_xp_paid",0)));var sid=int(s.run.get("id",0))*32+int(s.run.get("step",0))*2+(1 if s.run.get("final",false) else 0);var pm=s.run.get("persona_pm",[]).duplicate(true)
	var before={}
	for id in s.owned:before[id]={"level":s.members[id].level,"xp":s.members[id].xp}
	if not super(result):return false
	# The legacy settlement pays companion XP. Replace that payment once with
	# the source award contract, including commander's half XP and sid guard.
	for id in before:s.members[id].level=before[id].level;s.members[id].xp=before[id].xp
	# Pre-P1 active expeditions have no persona snapshot: their party consists
	# of companions only, so the migrated commander receives half XP.
	if pm.is_empty():
		for id in s.party:pm.append({"id":id})
	award_persona_exp({"exp":total_xp if result!="defeat" else 0,"sid":sid,"pm":pm})
	for gain in s.summary.gains:gain.level=s.members[gain.id].level;gain.xp=s.members[gain.id].xp
	return true

func restore(value: Variant) -> bool:
	var candidate=Adapter.migrate(value)
	if candidate.is_empty() or not Adapter.validate(candidate,config.companions.map(func(c):return c.id),persona_rules):return false
	if not PersonaResearch.valid_saved(candidate.persona.skill):return false
	if candidate.has("persona_research_r22"):
		var editor=candidate.persona_research_r22
		if not editor is Dictionary:return false
		if not editor.is_empty():
			if editor.size()!=2 or not _shape(editor,{"draft":{},"spent":0}) or not PersonaResearch.valid_saved(editor.draft):return false
			if editor.spent<0 or editor.spent>100000000 or editor.spent!=floor(editor.spent):return false
	# Reuse all existing gear/items/world validators on a disposable legacy view.
	# Padding exists only in this view; the actual party/ownership is never changed.
	var probe=candidate.duplicate(true);probe.schema=2;probe.party=IDS.duplicate()
	for id in IDS:
		if id not in probe.owned:probe.owned.append(id)
	probe.members.erase("persona");probe.equipment.erase("persona");probe.research.erase("persona")
	var saved_run=probe.run.duplicate(true)
	if not saved_run.is_empty():
		if not _shape(saved_run,{"phase":"","step":0,"gold":0,"xp":0,"wins":0,"event":"","resolved":true,"final":false,"battle":{},"rested":false,"id":0}):return false
		if saved_run.phase not in ["explore","battle","rest","done"] or saved_run.step<0 or saved_run.step>5 or saved_run.step!=floor(saved_run.step) or saved_run.id!=candidate.runs or saved_run.gold<0 or saved_run.xp<0 or saved_run.wins<0 or saved_run.wins>6:return false
		if saved_run.has("persona_party"):
			if not saved_run.persona_party is Array or saved_run.persona_party.is_empty() or saved_run.persona_party.size()>4 or not saved_run.get("persona_pm") is Array or saved_run.persona_pm.size()!=4:return false
			var ids=[]
			for entry in saved_run.persona_pm:
				if not _shape(entry,{"id":"","cls":"","L":1}):return false
				if entry.id=="":continue
				if entry.id in ids or (entry.id!="persona" and entry.id not in candidate.owned) or entry.L<1 or entry.L>40 or entry.L!=floor(entry.L) or persona_rules.by(persona_rules.data.classes,"id",entry.cls).is_empty():return false
				if entry.id=="persona":
					if entry.has("skill") and (not entry.skill is Dictionary or not PersonaResearch.valid_saved(entry.skill)):return false
					for key in ["race","lin","nat"]:
						if entry.has(key) and (not entry[key] is String or entry[key].length()>200):return false
					if entry.has("ps"):
						if not entry.ps is Dictionary:return false
						for key in entry.ps:
							if key not in ["hp","mp","str","agi","int","def","spd"] or not Adapter.numeric(entry.ps[key]) or entry.ps[key]<0 or entry.ps[key]>1000:return false
				ids.append(entry.id)
			if ids!=saved_run.persona_party:return false
		# The r21 parent checks the complete source run independently of its battle.
		probe.run=saved_run.duplicate(true);probe.run.battle={}
		probe.run.erase("persona_party");probe.run.erase("persona_pm")
	var legacy=LegacyWorld.new()
	# The legacy four-person probe cannot count a participating human persona.
	# Validate vitals with the real composition first; its disposable legacy view
	# then checks the remaining schema/equipment/run contracts with empty vitals.
	var validation_state=s;s=candidate
	for id in probe.members:
		var member=probe.members[id]
		if not member is Dictionary or not _shape(member,{"level":1,"xp":0,"aff":0.0,"hp":0,"mp":0}) or member.level<1 or member.level>40 or member.level!=floor(member.level):s=validation_state;return false
		var limit=stats(id,int(member.level))
		var hp_limit=limit.hp
		if not active() or id not in candidate.run.get("persona_party",candidate.party):hp_limit=stored_hp_limit(hp_limit)
		if member.hp<0 or member.mp<0 or member.hp>hp_limit or member.mp>limit.mp:s=validation_state;return false
		probe.members[id].hp=0;probe.members[id].mp=0
	s=validation_state
	if not legacy.restore(probe):return false
	var previous=s;s=candidate
	ensure_dungeon();ensure_town_r21();ensure_persona_member()
	var pm=s.members.persona
	if not _shape(pm,{"level":1,"xp":0,"aff":0.0,"hp":1,"mp":0}) or pm.level!=s.persona.lv or pm.xp!=s.persona.exp or pm.hp<0 or pm.mp<0:s=previous;return false
	var maximum=stats("persona",int(s.persona.lv))
	if not migrate_equipment_vitals_r14(maximum,saved_run):s=previous;return false
	if pm.hp>(maximum.hp if active() and "persona" in s.run.get("persona_party",[]) else stored_hp_limit(maximum.hp)) or pm.mp>maximum.mp:s=previous;return false
	if not saved_run.is_empty() and saved_run.get("phase")=="battle" and not saved_run.get("battle",{}).is_empty():
		var b=ModernBattle.new(battle_data())
		if not b.restore(saved_run.battle):s=previous;return false
	return true

func migrate_equipment_vitals_r14(_maximum: Dictionary,_saved_run: Dictionary) -> bool:
	return true # Only the P5 facade had the duplicate equipment multiplier.

func stored_hp_limit(current: int) -> int:
	# Inactive/benched native vitals may still carry an earlier human synergy.
	# Departure refreshes these vitals. Preserve them without admitting an active
	# combat unit above its actual maximum (battle.restore checks that separately).
	var humans=party_count("race","인간")
	var factor=1.07 if humans>=3 else 1.04 if humans>=2 else 1.0
	return maxi(current,int(ceil((current+.5)/factor*1.07)))
