extends "res://game/persona_world.gd"
## P5 facade. Old runs retain their original payment contract; new floors use P5.
const ExpeditionRules=preload("res://game/expedition_rules_r22.gd")
var expedition_rules=ExpeditionRules.new()
const ExpeditionUI=preload("res://game/expedition_ui_r23.gd")

func source_expedition_state() -> Dictionary:
	var r=s.run;var record={"floor":r.get("floor",1),"step":r.get("step",0),"phase":r.get("phase","explore"),"avg":expedition_party().avg,"pm":r.get("persona_pm",[]),"hp":[],"mp":[],"mhp":[],"mmp":[],"loot":{"gold":r.get("gold",0),"items":r.get("loot_items",{}),"gear":r.get("loot_gear",[])},"exp":r.get("xp",0),"real":r.get("wins",0)>0,"last":r.get("last", ""),"ask":r.get("ask",false)}
	var count=0;var levels=0.0
	for m in record.pm:
		if m.get("id","")!="":count+=1;levels+=m.L
	record.avg=levels/count if count>0 else 1.0
	var plan=dungeon_rules.floor_enc(int(record.floor),record.avg,count,"boss",dungeon_rules.battle_seed(int(r.get("seed",1)),int(record.floor),99,true))
	record.boss_kind=plan.enc.kind;record.boss_name=dungeon_rules.foes[plan.enc.fl[0]].name
	for m in record.pm:
		var id=m.get("id","");var maximum=r.get("maxima",{}).get(id,{"hp":0,"mp":0});var member=s.members.get(id,{"hp":0,"mp":0})
		record.hp.append(member.hp);record.mp.append(member.mp);record.mhp.append(maximum.hp);record.mmp.append(maximum.mp)
	if not s.summary.is_empty():
		var q=s.summary
		record.summary={"result":q.result,"floor":q.floor,"gold":q.gold,"exp":q.xp,"items":q.items,"lv":[],"aff":expedition_summary_aff_lines(),"gear":q.gear,"gear_lost":q.gear_lost,"kept_gear":q.gear,"lost_gear":q.lost_gear,"lost_gold":q.lost,"penalty":q.penalty,"first":q.first,"steps":q.steps,"wins":q.wins}
		for gain in q.gains:
			if gain.level>gain.before:record.summary.lv.append(ExpeditionText.u("{name} Lv {before} → {after}",{"name":expedition_member_name(gain.id),"before":gain.before,"after":gain.level},ExpeditionText.language(s)))
		if r.get("next_available",false):record.note=true
	return record

func source_expedition_view(kind: String,g: Dictionary={},r: Dictionary={},extra: Dictionary={}) -> Array:
	if g.is_empty():
		var items={}
		for id in s.items:items[source_item_id(id)]=s.items[id]
		g={"items":items,"persona":s.persona,"dungeon":s.dungeon_r21,"lang":ExpeditionText.language(s)}
	if r.is_empty():r=source_expedition_state()
	return ExpeditionUI.new().build(self,kind,g,r,extra)

func source_run(g: Dictionary) -> Variant:
	return normalize_dungeon_record(g).get("run",false)

func source_sortie_view(kind: String) -> Array:return ExpeditionUI.new().sortie(self,kind)
func source_preparation_view(kind: String,extra: Dictionary={}) -> Array:return ExpeditionUI.new().preparation(self,kind,extra)
func source_portrait_record(id: String,provided: Variant=null) -> Dictionary:
	# A native provider succeeds only with a usable texture. Missing/invalid
	# resources follow the same translated first-character path as tw_face.
	if provided is Texture2D:return {"texture":provided,"fallback":""}
	var ui=ExpeditionUI.new();ui.lang=ExpeditionText.language(s)
	return {"texture":null,"fallback":ui.t(town_source_name(id)).left(1)}
func sortie_mode() -> int:return 0 if s.ui.get("sel","")=="sortie:quest" else 1
func set_sortie_mode(mode: int) -> bool:
	if active() or mode not in [0,1]:return false
	# ui.sel is an existing free-text native/cloud field; D.mode is source-only.
	s.ui.sel="sortie:quest" if mode==0 else "sortie:dungeon"
	return true

func expedition_ui_text(text: String,values: Dictionary={}) -> String:
	var ui=ExpeditionUI.new();ui.lang=ExpeditionText.language(s);return ui.u(text,values)

func start_selected_dungeon() -> bool:
	var floor_no=maxi(1,int(selected_floor))
	if not dungeon_allowed(floor_no):floor_no=dungeon_max()
	return depart_dungeon(floor_no)
const ExpeditionText=preload("res://game/localization_r22.gd")
# 10-data.lua ITEMS names; the older native bag captions abbreviate these.
const EXPEDITION_ITEM_NAMES={"hp_s":"소형 회복약","hp_m":"중형 회복약","hp_l":"대형 회복약","mp_s":"소형 마나 물약","mp_m":"중형 마나 물약","mp_l":"대형 마나 물약","sh_s":"소형 보호막 물약","sh_m":"중형 보호막 물약","sh_l":"대형 보호막 물약","antidote":"해독약","bandage":"붕대","scroll":"귀환 두루마리","level_scroll":"레벨업 스크롤"}
# Original EQUIP_ORDER labels registered in ITEMS by 77-explore.lua. Display
# metadata only; these do not create equipment or alter the native bag schema.
const EXPEDITION_LEGACY_LABELS={
	"eq_w_iron_sword":["철제 장검","common"],"eq_w_hunter_bow":["사냥꾼의 활","common"],"eq_w_verdigris_blade":["녹청 단검","fine"],"eq_w_scribe_staff":["필사생의 지팡이","fine"],"eq_w_blue_spear":["푸른 창","rare"],"eq_w_oath_mace":["서약의 철퇴","rare"],"eq_w_amethyst_wand":["자수정 마장","epic"],"eq_w_faded_gold_blade":["바랜 금 대검","legend"],
	"eq_a_leather_coat":["가죽 외투","common"],"eq_a_chain_vest":["쇠사슬 조끼","common"],"eq_a_verdigris_plate":["녹청 흉갑","fine"],"eq_a_scholar_robe":["학술원 로브","fine"],"eq_a_blue_mail":["청강 갑옷","rare"],"eq_a_guard_cloak":["근위대의 망토","rare"],"eq_a_amethyst_plate":["자수정 판금","epic"],"eq_a_faded_gold_armor":["바랜 금 갑주","legend"],
	"eq_c_iron_ring":["철 반지","common"],"eq_c_bone_charm":["뼈 부적","common"],"eq_c_verdigris_pin":["녹청 브로치","fine"],"eq_c_ink_pendant":["잉크 결정 목걸이","fine"],"eq_c_blue_earring":["청옥 귀걸이","rare"],"eq_c_lamp_locket":["등불 로켓","rare"],"eq_c_amethyst_crown":["자수정 관","epic"],"eq_c_faded_gold_seal":["바랜 금 인장","legend"]}
func expedition_item_name(id: String) -> String:
	var roll=combat_gear_rules.gear_roll(id)
	if not roll.is_empty():return roll.item.name
	if EXPEDITION_LEGACY_LABELS.has(id):return EXPEDITION_LEGACY_LABELS[id][0]
	return EXPEDITION_ITEM_NAMES.get(source_item_id(id),id)
func expedition_item_rarity(id: String) -> Variant:
	var roll=combat_gear_rules.gear_roll(id)
	return roll.rarity if not roll.is_empty() else EXPEDITION_LEGACY_LABELS[id][1] if EXPEDITION_LEGACY_LABELS.has(id) else null
func expedition_gear_label(code: String,english_scene: bool=false) -> String:
	var lang="en" if english_scene else ExpeditionText.language(s);var roll=combat_gear_rules.gear_roll(code)
	if roll.is_empty():return "Unknown equipment" if lang=="en" else "알 수 없는 장비"
	var key=expedition_item_rarity(code)
	var rarity={"common":"Common","fine":"Uncommon","rare":"Rare","epic":"Epic","legend":"Legendary"}[key] if lang=="en" else combat_gear_rules.RARITY[key]
	return ExpeditionText.u("{item} ({rarity}, Lv {lv})",{"item":roll.item.name,"rarity":rarity,"lv":roll.lv},lang)

func expedition() -> bool:return r21() and s.run.get("expedition_version",0)==22
func expedition_source_pm() -> Array:
	# Complete 26-start snapshot, including equipment/forge and optional skill.
	# No clean here: dn_party itself preserves duplicate valid source slots.
	var out=[];var ids=[]
	if s.persona.get("fight",1)==1:ids.append("persona")
	ids.append_array(s.party)
	var forge={}
	for entry in s.gear:
		if entry.get("source_r21",false) and (entry.get("forge",0)>0 or entry.get("tries",0)>0):
			forge[combat_gear_rules.code(entry)]={"lv":entry.get("forge",0),"tries":entry.get("tries",0)}
	for id in ids:
		if out.size()>=4:break
		if id!="persona" and (id not in s.owned or not config.companions.any(func(c):return c.id==id)):continue
		var c=persona_rules.cls(s.persona.get("cls","")) if id=="persona" else class_def(id)
		var m={"id":id,"cls":c.get("id","warrior"),"L":expedition_level(id),"forge":forge}
		if id=="persona":
			m.merge({"race":s.persona.get("race",""),"lin":s.persona.get("lineage",""),"nat":s.persona.get("nation","")})
			if s.persona.get("stats") is Dictionary:m.ps=s.persona.stats.duplicate(true)
			if PersonaResearch.ready(s.persona.get("skill")):m.skill=PersonaResearch.clean(s.persona.skill)
		var eq={}
		for slot in ["weapon","armor","acc"]:
			var e=gear_entry(int(s.equipment.get(id,{}).get(slot,0)))
			if not e.is_empty() and e.get("source_r21",false):eq[slot]=combat_gear_rules.code(e)
		if not eq.is_empty():m.eq=eq
		out.append(m)
	while out.size()<4:out.append({"id":"","cls":"","L":1})
	return out
func expedition_party() -> Dictionary:
	var pm=expedition_source_pm();var n=0;var total=0.0
	for m in pm:
		if m.id!="":n+=1;total+=m.get("L",1)
	return {"pm":pm,"n":n,"avg":total/n if n>0 else 1.0}
func expedition_zero4() -> Array:return [0,0,0,0]
func expedition_label() -> String:
	var lang=ExpeditionText.language(s);var f=s.run.get("floor")
	var suffix=ExpeditionText.u(" {n}층",{"n":f},lang) if f!=null and not (f is bool and not f) else ""
	return ExpeditionText.u("대던전{floor}",{"floor":suffix},lang)
func expedition_floor_context(f: int) -> String:
	var info=dungeon_rules.floor_info(f)
	return "floor %d (%s%s)"%[f,ExpeditionText.t(dungeon_rules.zones[info.zone].name,"en"),", depth %d"%info.dc if info.dk>0 else ""]
func expedition_ids() -> Array:
	return expedition_members().map(func(e):return e.m.id) if active() and s.run.has("persona_pm") else sortie_ids()
func expedition_members() -> Array:
	var out=[];var pm=s.run.get("persona_pm",[])
	for i in range(mini(4,pm.size())):
		if pm[i] is Dictionary and pm[i].get("id","")!="":out.append({"slot":i+1,"m":pm[i]})
	return out
func expedition_equip_key(slot: int) -> String:
	for e in expedition_members():
		if e.slot==slot:return e.m.id
	return ""
func expedition_member_name(id: String) -> String:
	if id=="persona":
		var p=s.get("persona",{});var name=p.get("name","") if p is Dictionary else ""
		return name if name!="" else "당신"
	for c in config.companions:
		if c.id==id:return c.name
	return id
func person(id: String) -> Dictionary:
	var value=super(id)
	if id=="persona" and not value.is_empty():value.name=expedition_member_name(id)
	return value
func sortie_persona_role() -> Dictionary:
	var name=s.get("persona",{}).get("cls","");var c=persona_rules.cls(name)
	return {"row":c.get("row",""),"cls":c.get("name",name)}
func sortie_members() -> Array:
	s.party=persona_rules.clean(s.party,s.owned,int(s.persona.fight),config.companions.map(func(c):return c.id))
	var out=[]
	if s.persona.fight==1:
		var role=sortie_persona_role()
		out.append({"id":"persona","name":expedition_member_name("persona"),"cls":role.cls,"row":role.row,"lv":expedition_level("persona")})
	for id in s.party:
		var c=person(id)
		out.append({"id":id,"name":c.name,"cls":c["class"],"row":c.row,"lv":expedition_level(id)})
	return out
func expedition_mods() -> Dictionary:return expedition_rules.modifiers(s.run.get("persona_pm",source_pm()),config.companions)
func supplies(id: String) -> int:
	return int(s.items.get(id,0))+int(s.run.get("loot_items",{}).get(source_item_id(id),0)) if expedition() and active() else int(s.items.get(id,0))
func source_item_id(id: String) -> String:return {"shield_s":"sh_s","shield_m":"sh_m","shield_l":"sh_l"}.get(id,id)

func expedition_numeric(value: Variant) -> Variant:
	if _num(value):return float(value)
	if value is String and value.strip_edges().is_valid_float():
		var number=float(value.strip_edges())
		if is_finite(number):return number
	return null

func expedition_level(who: String) -> int:
	var p=s.get("persona");var raw=p.get("lv") if p is Dictionary else null
	if raw==null or (raw is bool and not raw):raw=s.get("lv")
	var pl=expedition_numeric(raw);var level=int(clampf(floor(pl if pl!=null else 1),1,40))
	if who=="persona":return level
	if who not in s.get("owned",[]):return 1
	var member=s.get("members",{}).get(who,{})
	var own=expedition_numeric(member.get("level")) if member is Dictionary else null
	return int(clampf(floor(own),1,40)) if own!=null else level

func expedition_experience(who: String) -> int:
	var source=s.get("persona") if who=="persona" else s.get("members",{}).get(who,{})
	var value=expedition_numeric(source.get("exp" if who=="persona" else "xp")) if source is Dictionary else null
	return maxi(0,int(floor(value))) if value!=null else 0

func sortie_candidates(filter="") -> Array:
	return sortie_candidate_records(filter).map(func(e):return e.cid)
func sortie_candidate_records(filter: String="") -> Array:
	var out=[];var order=config.companions.map(func(c):return c.id);var f=sortie_filter(filter)
	for id in s.owned:
		if id not in order:continue
		var c=person(id)
		if f!="" and c.row!=("전열" if f=="front" else "후열"):continue
		out.append({"cid":id,"on":id in s.party,"lv":expedition_level(id),"i":order.find(id)+1})
	out.sort_custom(func(a,b):
		if a.on!=b.on:return a.on
		if a.lv!=b.lv:return a.lv>b.lv
		return a.i<b.i)
	return out

func sortie_filter(filter: String) -> String:
	return filter if filter in ["front","back"] else ""

func sortie_summary(enemy_level: int=0) -> Dictionary:
	var members=sortie_members();var total=0;var front=0;var warns=[]
	for m in members:
		total+=m.lv
		if m.row=="전열":front+=1
	var avg=int(floor(float(total)/members.size())) if not members.is_empty() else 0
	var lang=ExpeditionText.language(s)
	# These two original UI templates are absent from the older native pack.
	if not members.is_empty() and front==0:warns.append("No one can hold the front. Without a front-line fighter, the back row is exposed." if lang=="en" else "앞에서 막을 사람이 없습니다. 전열이 한 명도 없으면 후열이 바로 맞습니다.")
	if not members.is_empty() and enemy_level-avg>=5:warns.append("Danger: the enemy is %d levels above your party's average."%(enemy_level-avg) if lang=="en" else ExpeditionText.u("위험합니다. 적이 파티 평균보다 {gap}레벨 높습니다.",{"gap":enemy_level-avg}))
	return {"n":members.size(),"avg":avg,"elv":enemy_level,"front":front,"warns":warns}
func sortie_quest_summary(q: Variant) -> Dictionary:
	if not q is Dictionary:return sortie_summary(0)
	var value=expedition_numeric(q.get("lv"))
	if value!=null:return sortie_summary(int(clampf(floor(value),1,40)))
	var base=expedition_level("persona")
	for id in s.owned:base=maxi(base,expedition_level(id))
	var difficulty=q.get("difficulty","")
	if not dungeon_rules.config.quest_difficulty.has(difficulty):
		var stars=expedition_numeric(q.get("stars",1))
		difficulty="높음" if stars!=null and stars>=3 else "중간" if stars!=null and stars>=2 else "낮음"
	return sortie_summary(clampi(base+int(dungeon_rules.config.quest_difficulty[difficulty].delta),1,40))

func price(item: Dictionary) -> int:
	var count=0
	for id in sortie_ids():
		if person(id).nation=="마렌토 공화국":count+=1
	return TOWN_RULES.shop_price(float(item.price),count)

func depart_dungeon(f: int,seed: int=0,rift_id: String="",stars: int=1) -> bool:
	# G_rnd shares the guild's saved seed/counter. Consume one draw only after
	# departure succeeds; explicit deterministic seeds do not consume a draw.
	var draw=rift_id.is_empty() and seed<=0
	var next_counter=int(s.town_r21.counter)+1
	var chosen=int(floor(RulesR21.mix(int(s.town_r21.seed),next_counter,0,0)*2147483646))+1 if draw else seed
	if not super(f,chosen,rift_id,stars):return false
	if draw:s.town_r21.counter=next_counter
	if rift_id.is_empty():
		s.run.merge({"expedition_version":22,"log":[],"fell":false,"ask":false,"next_available":false,"maxima":{},"last":""},true)
		var party=expedition_party()
		var record=expedition_record_with_seed(f,party.pm,party.n,party.avg,int(s.run.id),int(s.run.seed))
		for i in range(party.pm.size()):
			var member=party.pm[i]
			var id=member.id
			if id=="":continue
			# ex_new uses party_stats before race, persona allocation, equipment,
			# and party synergies; the first battle builds its full stats afresh.
			s.run.maxima[id]={"hp":record.mhp[i],"mp":record.mmp[i]}
			s.members[id].hp=record.hp[i];s.members[id].mp=record.mp[i]
	return true

func new_expedition_record(f: int,pm: Array,n: int,avg: float,sid: int,random: Callable,stats_provider: Callable=Callable()) -> Dictionary:
	# The caller owns RNG storage. One draw is shared with the source constructor.
	var seed=int(floor(float(random.call())*2147483646))+1
	return expedition_record_with_seed(f,pm,n,avg,sid,seed,stats_provider)

func expedition_record_with_seed(f: int,pm: Array,n: int,avg: float,sid: int,seed: int,stats_provider: Callable=Callable()) -> Dictionary:
	var hp=expedition_zero4();var mp=expedition_zero4();var mhp=expedition_zero4();var mmp=expedition_zero4()
	for i in range(mini(4,pm.size())):
		var m=pm[i]
		if not m is Dictionary or m.get("id","")=="":continue
		var id=m.id
		# An explicit envelope maps Lua's pcall success/type checks.
		var response=stats_provider.call(m.cls,m.L,false if id=="persona" else id) if stats_provider.is_valid() else {"ok":true,"value":initial_expedition_stats(m.cls,int(m.L),false if id=="persona" else id)}
		if response.get("ok",false) and response.get("value") is Dictionary and not response.value.is_empty():
			var value=response.value
			mhp[i]=int(floor(value.hp+.5));mmp[i]=int(floor(value.mp+.5));hp[i]=mhp[i];mp[i]=mmp[i]
	var boss_seed=dungeon_rules.battle_seed(seed,f,99,true)
	var plan=dungeon_rules.floor_enc(f,avg,n,"boss",boss_seed)
	return {"v":1,"floor":f,"step":0,"phase":"explore","seed":seed,"sid":sid,"pm":pm,"n":n,"avg":avg,
		"loot":{"gold":0,"items":{},"gear":[]},"exp":0,"elites":0,"wins":0,"hp":hp,"mp":mp,"mhp":mhp,"mmp":mmp,"real":false,
		"log":[],"last":"","sel":1,"ask":false,"boss_seed":boss_seed,"boss_name":dungeon_rules.foes[plan.enc.fl[0]].name,"boss_kind":plan.enc.kind}

func initial_expedition_vitals(id: String,level: int) -> Dictionary:
	return initial_expedition_stats(class_def(id).id,level,false if id=="persona" else id)

func initial_expedition_stats(cls: String,level: int,id: Variant=false) -> Dictionary:
	var c={};var mod={}
	for candidate in config.classes:
		if candidate.id==cls or candidate.name==cls:c=candidate;break
	if c.is_empty():return {}
	for companion in config.companions:
		if id is String and companion.id==id:mod=companion.mod;break
	var out={};var x=clampi(level,1,40)-1
	for key in ["hp","mp"]:
		var curve=config.curves[key]
		out[key]=int(floor(c.base[key]*(1+mod.get(key,0)/100.0)*(1+c.grow.get(key,1)*(curve.a*x+curve.b*x*x))+.5))
	return out

func log_expedition(line: String) -> void:
	s.run.last=line;append_expedition_log(line)
	note(line)

func append_expedition_log(line: String) -> void:
	s.run.log.append(line)
	while s.run.log.size()>8:s.run.log.pop_front()

func expedition_item_weight(iid: String,f: int) -> float:
	var x=dungeon_rules.config.explore
	return float(x.ITEM_W.get(iid,0)) if f>=x.ITEM_FROM.get(iid,0) else 0.0
func expedition_roll(seed: int,f: int,step: int,elites: int,classes: Array) -> Dictionary:
	var out=dungeon_rules.ex_roll(seed,f,step,elites,classes)
	if out.kind!="item":return out
	var total=0.0
	for iid in dungeon_rules.config.item_order:total+=expedition_item_weight(iid,f)
	var x=RulesR21.mix(seed,f,step,3)*total;var pick=dungeon_rules.config.item_order[0]
	for iid in dungeon_rules.config.item_order:
		x-=expedition_item_weight(iid,f)
		if x<0:pick=iid;break
	return {"kind":"item","item":pick}

func advance() -> bool:
	if not expedition():return super()
	var r=s.run
	if not active() or r.phase!="explore" or r.step>=5 or r.ask:return false
	r.step+=1
	var out=expedition_rules.discovery(expedition_roll(int(r.seed),int(r.floor),int(r.step),int(r.elites),party_classes()),int(r.seed),int(r.floor),int(r.step),expedition_mods())
	r.event=out.kind
	if out.kind in ["battle","elite"]:
		if out.kind=="elite":r.elites+=1
		r.kind=out.kind;r.phase="battle";r.battle={};r.resolved=false
		return true
	if out.kind=="coin":r.gold+=out.gold;r.last=expedition_ui_text("낡은 주머니에서 주화 {gold}닢을 찾았다.",{"gold":out.gold})
	elif out.kind=="item":
		r.loot_items[out.item]=r.loot_items.get(out.item,0)+out.count
		var count=["하나","둘","셋"][out.count-1] if out.count in [1,2,3] else str(out.count)
		r.last=expedition_ui_text("{item} {count}{suffix} 주웠다.",{"item":expedition_item_name(out.item),"count":count,"suffix":"를" if out.count==1 else "을"})
	else:append_expedition_gear(out.code);r.last=expedition_ui_text("장비를 발견했다: {item}.",{"item":expedition_gear_label(out.code)})
	append_expedition_log(expedition_ui_text("탐색 {step}: {result}",{"step":r.step,"result":r.last}));note(r.last)
	if r.step>=5:enter_dungeon_rest()
	return true

func enter_dungeon_rest():
	if not expedition():super();return
	var r=s.run;r.phase="rest";r.ask=false
	r.rested=true
	var mods=expedition_mods();var gains=[]
	for id in expedition_ids():
		var b=r.maxima[id];var m=s.members[id];var h=m.hp;var p=m.mp
		m.hp=mini(b.hp,h+int(floor(b.hp*(dungeon_rules.config.explore.REST_HP+mods.rest_hp)+.5)))
		m.mp=mini(b.mp,p+int(floor(b.mp*(dungeon_rules.config.explore.REST_MP+mods.rest_mp)+.5)))
		var ui=ExpeditionUI.new();ui.lang=ExpeditionText.language(s)
		gains.append("%s HP +%d"%[ui.t(expedition_member_name(id)),m.hp-h]+(", MP +%d"%(m.mp-p) if b.mp>0 else ""))
	r.last=expedition_ui_text("휴식. 파티 전원이 숨을 돌렸다({gain})",{"gain":" / ".join(gains)})
	append_expedition_log(expedition_ui_text("휴식: 파티 HP +{pct}%",{"pct":int(floor((dungeon_rules.config.explore.REST_HP+mods.rest_hp)*100+.5))}))
	note(r.last)

func final_battle() -> bool:
	if not expedition():return super()
	if not active() or s.run.phase!="rest":return false
	# 77-explore.do_boss cancels the retreat prompt when starting the boss.
	s.run.ask=false;s.run.phase="battle";s.run.final=true;s.run.kind="boss";s.run.battle={}
	return true

func battle_data() -> Dictionary:
	var d=super()
	if not expedition():return d
	# Rest swaps change maxima at the next encounter; source carry clamps there.
	for a in d.allies:
		if s.run.wins==0:
			# R.real is false until snapshot_party after the first exploration
			# victory. The initial display values are never used as carry.
			a.hp=a.mhp;a.mp=a.mmp;a.erase("gear_vitals")
		else:a.hp=mini(a.hp,a.mhp);a.mp=mini(a.mp,a.mmp)
	for it in config.items:d.inventory[it.id]=supplies(it.id)
	return d

func take_supply(id: String,count: int=1) -> bool:
	if count<1 or supplies(id)<count:return false
	var key=source_item_id(id);var pouch=s.run.loot_items;var n=mini(count,int(pouch.get(key,0)))
	if n>0:
		pouch[key]-=n
		if pouch[key]==0:pouch.erase(key)
	s.items[id]=int(s.items.get(id,0))-(count-n)
	return true

func record_battle(snapshot: Dictionary) -> void:
	if not expedition():super(snapshot);return
	if not active() or s.run.phase!="battle" or snapshot.get("schema_version")!=3 or not snapshot.get("inventory") is Dictionary:return
	var inventory=snapshot.inventory
	for it in config.items:
		if not _num(inventory.get(it.id)) or inventory[it.id]<0 or inventory[it.id]!=floor(inventory[it.id]) or inventory[it.id]>supplies(it.id):return
	var battle=ModernBattle.new(battle_data())
	if not battle.restore(snapshot):return
	for it in config.items:
		var used=supplies(it.id)-int(inventory[it.id])
		if used>0:take_supply(it.id,used)
	s.run.battle=snapshot.duplicate(true)

func finish_battle() -> bool:
	if not expedition():return super()
	var r=s.run
	if not active() or r.phase!="battle" or r.battle.is_empty():return false
	var b=ModernBattle.new(battle_data())
	if not b.restore(r.battle) or b.result.is_empty():return false
	snapshot_expedition_party(b)
	if b.result=="defeat":return settle("defeat")
	var plan=b.data.encounter_r21;var mods=expedition_mods()
	var gold=dungeon_rules.gold(int(r.floor),plan.enc.kind if r.final else "battle")
	if not r.final:gold=int(floor(gold*(dungeon_rules.config.explore.GOLD_ELITE if r.kind=="elite" else dungeon_rules.config.explore.GOLD_BATTLE)+.5))
	gold=int(floor(gold*mods.gold+.5))
	var xp=dungeon_rules.exp_reward(plan.enc,int(plan.el),mods.exp)
	r.gold+=gold;r.xp+=xp
	var kind=plan.enc.kind if r.final else r.kind
	if kind in ["elite","chief","boss"]:
		var salt=22 if r.final else 21
		var sample=RulesR21.mix(int(r.seed),int(r.floor),99 if r.final else int(r.step),salt)
		roll_expedition_gear(kind,sample)
	if r.final:return settle("clear")
	r.wins+=1;r.phase="explore";r.battle={};r.resolved=true
	log_expedition("탐색 %d: 전투 승리 · 금화 %d · 경험치 %d"%[r.step,gold,xp])
	emit_bark("victory")
	if r.step>=5:enter_dungeon_rest()
	return true

func snapshot_expedition_party(b) -> void:
	var record={"hp":expedition_zero4(),"mp":expedition_zero4(),"mhp":expedition_zero4(),"mmp":expedition_zero4(),"fell":s.run.get("fell",false)};var units=[]
	for i in range(4):
		var id=s.run.persona_pm[i].id
		if id=="":units.append({"empty":1});continue
		var a=b.ally(id)
		units.append({"empty":0,"al":1 if a.hp>0 else 0,"hp":a.hp,"mp":a.mp,"mhp":a.mhp,"mmp":a.mmp})
	snapshot_expedition_record(record,units,dungeon_rules.config.explore.DOWN_HP)
	for e in expedition_members():
		var i=e.slot-1;var id=e.m.id
		s.run.maxima[id]={"hp":record.mhp[i],"mp":record.mmp[i]};s.members[id].hp=record.hp[i];s.members[id].mp=record.mp[i]
	s.run.fell=record.get("fell",false)
func snapshot_expedition_record(r: Dictionary,units: Array,down: float) -> void:
	for i in range(mini(4,units.size())):
		var u=units[i]
		if not u is Dictionary or u.get("empty",0)==1:continue
		r.mhp[i]=int(floor(u.mhp));r.mmp[i]=int(floor(u.mmp))
		r.hp[i]=maxi(1,int(floor(u.hp))) if u.get("al")==1 else (maxi(1,int(floor(u.mhp*down))) if down>0 else 0)
		r.mp[i]=maxi(0,int(floor(u.mp)))
		if u.get("al")!=1:r.fell=true
	r.real=true

func expedition_exp_note(r: Dictionary,amount: float,summary: Dictionary,provider: Callable=Callable(),available: bool=true) -> void:
	summary.exp=0;summary.lv=[]
	if amount<=0 or not available:return
	var st={"exp":amount,"pm":r.pm,"sid":r.sid}
	# Godot has no pcall. Providers return an explicit success/value envelope;
	# normal gameplay calls the already validated native award method.
	var result=provider.call(st) if provider.is_valid() else {"ok":true,"value":expedition_award_lines(st)}
	if result.get("ok",false) and (result.get("value") is Array or result.get("value") is Dictionary):summary.exp=amount;summary.lv=result.value
func expedition_award_lines(st: Dictionary) -> Array:
	var before={"persona":expedition_level("persona")};var order=["persona"]
	for m in st.pm:
		var id=m.id if m is Dictionary else m
		if id!="" and id!="persona" and id not in order:order.append(id);before[id]=expedition_level(id)
	var gains=award_persona_exp(st);var lines=[];var lang=ExpeditionText.language(s)
	for id in order:
		if gains.has(id) and expedition_level(id)>before[id]:lines.append(ExpeditionText.u("{name} Lv {before} → {after}",{"name":expedition_member_name(id),"before":before[id],"after":expedition_level(id)},lang))
	return lines
func expedition_aff_note(r: Dictionary,result: String,summary: Dictionary,provider: Callable=Callable(),available: bool=true) -> Dictionary:
	summary.aff=[]
	if not available:return {}
	var amount=r.get("wins",0)*dungeon_rules.config.affection.BATTLE+(dungeon_rules.config.affection.BOSS if result=="clear" else 0)
	if amount<=0:return {}
	var response=provider.call(r.pm,amount) if provider.is_valid() else {"ok":true,"value":expedition_aff_party(r.pm,amount)}
	if not response.get("ok",false) or not response.get("value") is Dictionary:return {}
	var got=response.value;var lang=ExpeditionText.language(s)
	for m in r.pm.slice(0,4):
		if m is Dictionary and m.get("id","")!="" and got.has(m.id):summary.aff.append(str(ExpeditionText.t(expedition_member_name(m.id),lang))+" +"+expedition_aff_format(got[m.id]))
	return got
func expedition_aff_format(value: float) -> String:
	value=floor(value*100+.5)/100
	if value==floor(value):return str(int(value))
	# Lua printf rounds the actual binary double, including values such as
	# 1.45 lying just below a decimal half. Native deltas are within [-300,300],
	# so the significand * 10 and the power-of-two denominator fit int64.
	var bytes=PackedByteArray();bytes.resize(8);bytes.encode_double(0,absf(value))
	var bits=bytes.decode_u64(0);var exponent=int((bits>>52)&2047)-1023
	var numerator=((bits&4503599627370495)|4503599627370496)*10
	var shift=52-exponent;var lower=numerator>>shift
	var remainder=numerator&((1<<shift)-1);var half=1<<(shift-1)
	var rounded=lower+(1 if remainder>half or (remainder==half and lower%2==1) else 0)
	return ("-" if value<0 else "")+str(int(rounded/10))+"."+str(rounded%10)
func expedition_aff_party(pm: Array,amount: float) -> Dictionary:
	var got={};var mods=expedition_rules.modifiers(pm,config.companions)
	for m in pm:
		var id=m.id if m is Dictionary else m
		if id=="" or id=="persona" or got.has(id) or id not in s.owned:continue
		var old=s.members[id].aff;s.members[id].aff=TOWN_RULES.aff_next(old,amount*mods.aff)
		got[id]=floor((s.members[id].aff-old)*100+.5)/100
	return got

func roll_expedition_gear(kind: String,seed: float) -> String:
	# ex_gear_roll passes its input through mix, which floors fractional seeds.
	var sample=int(floor(seed))
	if RulesR21.mix(sample,31,0,0)>=dungeon_rules.config.gear_drop.chance.get(kind,0):return ""
	var classes=[]
	for m in s.run.persona_pm:
		if m.get("id","")!="":classes.append(m.cls)
	var drop=dungeon_rules.gear_drop(int(floor(RulesR21.mix(sample,32,0,0)*2147483646))+1,int(s.run.floor),kind,classes)
	if drop.is_empty():return ""
	append_expedition_gear(drop.code)
	return drop.code

func append_expedition_gear(code: String) -> void:
	if not s.run.has("loot_gear"):s.run.loot_gear=[]
	s.run.loot_gear.append(code)

func outside_item_multiplier() -> float:
	return float(expedition_mods().item)

func bank_expedition_items(items: Dictionary) -> Array:
	var ids=[]
	for id in items:
		if items[id]>0:ids.append(id)
	ids.sort()
	for id in ids:
		var key=web_item_id(id);s.items[key]=s.items.get(key,0)+items[id]
	return ids

func bank_expedition_gear(codes: Array) -> Dictionary:
	return bank_expedition_record(codes)

func bank_expedition_record(codes: Array,provider: Callable=Callable(),request_id: String="") -> Dictionary:
	var out=[];var lost=0
	for code in codes:
		var added=provider.call(request_id,code) if provider.is_valid() else bank_expedition_code(code)
		if added:out.append(code)
		else:lost+=1
	return {"gear":out,"lost":lost}

func bank_expedition_code(code: String) -> bool:
	var entry=combat_gear_adapter.source_drop({"code":code},int(s.serial)+1)
	if entry.is_empty():return false
	var worn=[]
	for eq in s.equipment.values():worn.append_array(eq.values())
	if s.gear.filter(func(e):return e.uid not in worn).size()>=2000:
		return false
	s.serial+=1;s.gear.append(entry)
	return true

func settle(result: String) -> bool:
	if not expedition():return super(result)
	var r=s.run
	if not active() or result not in ["clear","retreat","defeat"]:return false
	if result=="retreat" and r.phase not in ["explore","rest"]:return false
	if result in ["clear","defeat"]:
		if r.phase!="battle" or r.battle.is_empty():return false
		var b=ModernBattle.new(battle_data())
		if not b.restore(r.battle) or b.result!=("victory" if result=="clear" else "defeat") or (result=="clear" and not r.final):return false
	var mods=expedition_mods();var keep=mods.keep if result=="defeat" else 1.0
	var amount=int(floor(r.gold*keep));var xp=0 if result=="defeat" else int(r.xp)
	var penalty=0
	if result=="defeat":penalty=int(floor(mini(s.gold,100*clampi(int(encounter_plan().star),1,4))/2.0*mods.loss))
	var items={};var lost_items={}
	for id in r.loot_items:
		var n=int(floor(r.loot_items[id]*keep))
		if n>0:items[id]=n
		if n<r.loot_items[id]:lost_items[id]=r.loot_items[id]-n
	bank_expedition_items(items)
	var kept=r.loot_gear.slice(0,int(floor(r.loot_gear.size()*keep)))
	var bank=bank_expedition_gear(kept)
	s.gold+=amount-penalty
	var before={};var gains=[];var affection={}
	for id in expedition_ids():before[id]=expedition_level(id)
	var source_summary={}
	# P5 source pays on settlement. Never replay XP paid by a pre-P5 run.
	expedition_exp_note({"sid":int(r.id)*32+31,"pm":r.persona_pm},xp,source_summary)
	if result!="defeat":affection=expedition_aff_note({"pm":r.persona_pm,"wins":r.wins},result,source_summary)
	else:source_summary.aff=[]
	for id in expedition_ids():
		var m=s.members[id]
		gains.append({"id":id,"before":before[id],"level":expedition_level(id),"xp":expedition_experience(id)})
	var first=false
	if result!="defeat":s.dungeon_r21.runs+=1
	if result=="clear":
		var info=dungeon_rules.floor_info(int(r.floor));s.dungeon_r21.best=maxi(s.dungeon_r21.best,r.floor)
		if info.dk==0 and info.ord>=3 and info.zone not in s.dungeon_r21.cleared_bosses:s.dungeon_r21.cleared_bosses.append(info.zone);first=true
		s.dungeon_r21.sel=mini(dungeon_max(),r.floor+1);selected_floor=int(s.dungeon_r21.sel)
		s.dungeon_r21.pg=int((selected_floor-1)/6)+1
	s.summary={"expedition_version":22,"result":result,"floor":r.floor,"gold":amount if result!="defeat" else 0,"kept_gold":amount if result=="defeat" else 0,"xp":xp,"wins":r.wins,"steps":r.step,"gains":gains,"items":items,"lost_items":lost_items,"gear":bank.gear,"gear_lost":bank.lost,"lost_gear":r.loot_gear.size()-bank.gear.size() if result=="defeat" else 0,"penalty":penalty,"lost":r.gold-amount,"first":first,"aff":affection,"fell":r.fell}
	r.phase="done";r.battle={};r.loot_items={};r.loot_gear=[];r.ask=false;r.next_available=result=="clear"
	s.day+=1;s.refreshes=0;s.dungeon_r21.last=s.summary.duplicate(true)
	log_expedition("%d층 %s · 금화 %d · 경험치 %d"%[r.floor,{"clear":"돌파","retreat":"퇴각","defeat":"도전 실패"}[result],amount,xp])
	emit_bark("defeat" if result=="defeat" else "return")
	if result=="defeat":
		var carry=mini(s.gold-amount+penalty,100*clampi(int(encounter_plan().star),1,4))
		var kept_ui=""
		if keep>0 and (amount>0 or not items.is_empty() or not bank.gear.is_empty()):
			kept_ui=expedition_ui_text(" 케른의 계약 덕에 모은 것의 일부(금화 {gold}{gear})는 챙겼다.",{"gold":amount,"gear":expedition_ui_text(", 장비 {n}개",{"n":bank.gear.size()}) if not bank.gear.is_empty() else ""})
			if s.summary.lost_gear>0:kept_ui+=expedition_ui_text(" 장비 {n}개는 잃었다.",{"n":s.summary.lost_gear})
		s.ui.msg=expedition_ui_text("대던전 {floor}층 도전 실패. 모은 것을 잃고, 들고 간 금화 {carry}의 {part}{loss}도 잃었다.{kept}",{"floor":r.floor,"carry":carry,"part":expedition_ui_text("일부 " if mods.loss<1 else "절반 "),"loss":penalty,"kept":kept_ui})
		# The completed summary remains in both native summary and D.last. Only
		# the finished live run is removed, as in 77-explore.finish_run.
		s.run={};s.scene="town";s.ui.sel="";s.ui.tab=""
	return true

func expedition_defeat_home() -> bool:
	return s.run.is_empty() and s.summary.get("expedition_version")==22 and s.summary.get("result")=="defeat" and s.get("scene")=="town"

func expedition_summary_aff_lines() -> Array:
	var out=[];var lang=ExpeditionText.language(s);var got=s.summary.get("aff",{})
	for m in s.run.get("persona_pm",[]).slice(0,4):
		if m.get("id","")!="" and got.has(m.id):out.append(str(ExpeditionText.t(expedition_member_name(m.id),lang))+" +"+expedition_aff_format(got[m.id]))
	return out

func next_dungeon_floor() -> bool:
	if not expedition() or active() or not s.run.next_available or s.summary.get("result")!="clear":return false
	var f=int(s.run.floor)+1
	if f>dungeon_max():return false
	# Calls the public departure boundary, including P10 record hooks.
	return depart_dungeon(f)

func expedition_home() -> bool:
	if active() or not expedition():return false
	s.run.next_available=false
	return true

func item_preview(id: String,who: String) -> Dictionary:
	if not expedition() or not active():return super(id,who)
	var it=item_def(id);var out={"usable":false,"reason":"출전한 대상과 보급품을 선택하세요.","before":0,"after":0,"maximum":1,"resource":"HP"}
	if it.is_empty() or who not in expedition_ids():return out
	var m=s.members[who];var b=s.run.maxima[who]
	out.before=m.hp;out.after=m.hp;out.maximum=b.hp
	if s.run.phase not in ["explore","rest"]:out.reason="전투의 보급품 메뉴에서 사용하세요.";return out
	if supplies(id)<=0:out.reason="보유한 보급품이 없습니다.";return out
	if expedition_level(who)<it.level:out.reason="Lv.%d부터 사용합니다."%it.level;return out
	if it.kind in ["hp","mp"]:
		var k=it.kind;out.resource=k.to_upper();out.before=m[k];out.maximum=b[k]
		out.after=mini(b[k],m[k]+int(floor(b[k]*it.fraction*outside_item_multiplier()+.5)))
		out.usable=m.hp>0 and m[k]<b[k];out.reason="쓰러진 동료에게는 붕대를 사용하세요." if m.hp<=0 else "이미 가득 찼습니다."
	elif it.kind=="revive":out.after=maxi(1,int(floor(b.hp*it.fraction)));out.usable=m.hp<=0;out.reason="쓰러진 동료에게 사용합니다."
	elif it.kind=="return":out.usable=true;out.reason="모은 보상을 정산하고 돌아갑니다."
	else:out.reason="전투의 보급품 메뉴에서 사용하세요."
	if out.usable:out.reason=""
	return out

func use_item(id: String,who: String) -> bool:
	if not expedition() or not active():return super(id,who)
	return use_expedition_item(id,who)
func use_expedition_item(id: String,who: String) -> bool:
	if not expedition() or not active():return false
	var p=item_preview(id,who)
	if not p.usable:return false
	if item_def(id).kind=="return":
		if not take_supply(id):return false
		return settle("retreat")
	if not take_supply(id):return false
	var resource="mp" if p.resource=="MP" else "hp";var old=s.members[who][resource]
	s.members[who][resource]=p.after
	var name=expedition_member_name(who)
	if item_def(id).kind=="revive":
		s.run.last=ExpeditionText.u("{name:을를} 붕대로 일으켰다. HP {hp}",{"name":name,"hp":p.after})
	else:s.run.last=ExpeditionText.u("{name}에게 {item}: "+p.resource+" +{n}",{"name":name,"item":expedition_item_name(id),"n":p.after-old})
	return true

func expedition_retreat(arg: String) -> bool:
	if not expedition() or not active() or s.run.phase not in ["explore","rest"]:return false
	if arg=="retreat":s.run.ask=true;return true
	if arg=="retreat_no":s.run.ask=false;return true
	if arg=="retreat_yes" and s.run.ask:return settle("retreat")
	return false
func can_expedition_equip(who: String) -> bool:
	if not expedition() or not active() or s.run.phase!="rest":return false
	for e in expedition_members():
		if expedition_equip_key(e.slot)==who:return true
	return false
func equip(who: String,uid: int) -> bool:
	if not can_expedition_equip(who):return super(who,uid)
	var e=gear_entry(uid)
	if e.is_empty():return false
	var it=gear.by_id[e.id]
	if it.cls!=class_def(who).id or s.members[who].level<gear.rules.equip_lv[it.rarity]:return false
	var old=wearer(uid)
	if old!="":s.equipment[old].erase(it.slot)
	s.equipment[who][it.slot]=uid;return true
func unequip(who: String,slot: String) -> bool:
	if not can_expedition_equip(who):return super(who,slot)
	if not s.equipment[who].has(slot):return false
	s.equipment[who].erase(slot);return true

func floor_page(pg: int) -> bool:
	var pages=maxi(1,int(ceil((dungeon_max()+1)/6.0)))
	if active() or pg<1 or pg>pages:return false
	s.dungeon_r21.pg=pg;return true
func select_dungeon_floor(f: int) -> bool:
	if active() or not dungeon_allowed(f):return false
	selected_floor=f;s.dungeon_r21.sel=f;return true

func restore(value: Variant) -> bool:
	if not value is Dictionary or not value.get("run",{}) is Dictionary:return false
	# 77-explore.move_old: merge both old potion aliases before the inherited
	# inventory validators. Work on a copy so a rejected save remains untouched.
	value=value.duplicate(true)
	if value.get("dungeon_r21") is Dictionary and value.dungeon_r21.has("mode"):
		var mode=value.dungeon_r21.mode
		if mode not in [0,1] or not value.get("ui") is Dictionary:return false
		value.ui.sel="sortie:quest" if mode==0 else "sortie:dungeon";value.dungeon_r21.erase("mode")
	if value.get("items") is Dictionary:
		if not migrate_expedition_items(value.items):return false
	if value.run.get("loot_items") is Dictionary:
		if not migrate_expedition_items(value.run.loot_items):return false
	if value.has("equipment_vitals_before_r14"):
		var archive=value.equipment_vitals_before_r14
		if not archive is Dictionary or archive.is_empty():return false
		for key in archive:
			if key not in ["hp","mp","battle_hp","battle_mp","maxima_hp","maxima_mp"] or not _num(archive[key]) or archive[key]<0 or archive[key]>1000000 or archive[key]!=floor(archive[key]):return false
	if value.get("run",{}).get("expedition_version",0)==22:
		var r=value.run
		if not _shape(r,{"log":[],"fell":false,"ask":false,"next_available":false,"maxima":{}}):return false
		if r.log.size()>8 or r.get("rift_id","")!="":return false
		for line in r.log:
			if not line is String:return false
		for key in r.get("loot_items",{}):
			if key not in dungeon_rules.config.item_order or not _num(r.loot_items[key]) or r.loot_items[key]<0 or r.loot_items[key]!=floor(r.loot_items[key]):return false
		for code in r.get("loot_gear",[]):
			if not code is String or not valid_gear_code(code):return false
		for id in r.get("persona_party",[]):
			if not _shape(r.maxima.get(id),{"hp":1,"mp":0}):return false
			for key in ["hp","mp"]:
				var n=r.maxima[id][key]
				if n<(1 if key=="hp" else 0) or n>1000000 or n!=floor(n):return false
		if r.next_available and (r.phase!="done" or not value.get("summary") is Dictionary or value.summary.get("result")!="clear"):return false
	return super(value)

func migrate_expedition_items(items: Dictionary) -> bool:
	for old in ["potion","mana"]:
		if not items.has(old):continue
		var key="hp_s" if old=="potion" else "mp_s"
		var amount=items[old];var present=items.get(key,0)
		if amount is String and amount.is_valid_float():amount=float(amount)
		if present is String and present.is_valid_float():present=float(present)
		if not _num(amount) or not _num(present) or amount<0 or present<0 or amount!=floor(amount) or present!=floor(present):return false
		items[key]=int(present)+int(amount);items.erase(old)
	return true

func migrate_equipment_vitals_r14(maximum: Dictionary,saved_run: Dictionary) -> bool:
	# The public P5 facade multiplied persona equipment twice. Keep exact excess
	# vitals in a bounded archive before moving that old save to the corrected cap.
	if s.run.get("expedition_version",0)!=22 or s.equipment.get("persona",{}).is_empty():return true
	var bonus=gear_bonus("persona",int(s.persona.lv));var old={}
	for key in ["hp","mp"]:old[key]=int(floor(maximum[key]*(1+bonus.get(key,0)/100.0)+.5))
	var changes={};var member=s.members.persona
	for key in ["hp","mp"]:
		var limit=maximum[key] if key=="mp" or (active() and "persona" in s.run.get("persona_party",[])) else stored_hp_limit(maximum[key])
		if member[key]>limit:
			if member[key]>old[key]:return false
			changes[key]=member[key]
	var snapshot=saved_run.get("battle",{})
	if not snapshot.get("units",{}) is Dictionary:return false
	var battle=snapshot.get("units",{}).get("persona",{})
	if not battle is Dictionary:return false
	for key in ["hp","mp"]:
		if battle.has(key) and not _num(battle[key]):return false
		if battle.get(key,0)>maximum[key]:
			if battle[key]>old[key]:return false
			changes["battle_"+key]=battle[key]
	if changes.is_empty():return true
	if s.has("equipment_vitals_before_r14"):return false
	s.equipment_vitals_before_r14=changes
	for key in ["hp","mp"]:
		member[key]=mini(member[key],maximum[key])
		if not battle.is_empty():battle[key]=mini(battle[key],maximum[key]);s.run.battle.units.persona[key]=battle[key]
		if s.run.get("maxima",{}).has("persona") and s.run.maxima.persona[key]>maximum[key]:
			changes["maxima_"+key]=s.run.maxima.persona[key];s.run.maxima.persona[key]=maximum[key]
	return true

func valid_gear_code(code: String) -> bool:
	var p=code.split(".")
	if p.size()!=3 or not gear.by_id.has(p[0]) or p[1].is_empty() or p[1].length()>8 or p[2]!=str(int(dungeon_rules.config.gear_version)):return false
	var seed=0
	for ch in p[1]:
		if ch not in "0123456789abcdefghijklmnopqrstuvwxyz":return false
		seed=seed*36+"0123456789abcdefghijklmnopqrstuvwxyz".find(ch)
	return seed>=1 and seed<=1099511627776
