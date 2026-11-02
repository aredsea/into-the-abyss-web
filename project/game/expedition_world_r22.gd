extends "res://game/persona_world.gd"
## P5 facade. Old runs retain their original payment contract; new floors use P5.
const ExpeditionRules=preload("res://game/expedition_rules_r22.gd")
var expedition_rules=ExpeditionRules.new()
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
	if not super(f,seed,rift_id,stars):return false
	if rift_id.is_empty():
		s.run.merge({"expedition_version":22,"log":[],"fell":false,"ask":false,"next_available":false,"maxima":{}})
		for id in expedition_ids():
			# ex_new uses party_stats before race, persona allocation, equipment,
			# and party synergies; the first battle builds its full stats afresh.
			var b=initial_expedition_vitals(id,int(s.members[id].level))
			s.run.maxima[id]=b;s.members[id].hp=b.hp;s.members[id].mp=b.mp
	return true

func initial_expedition_vitals(id: String,level: int) -> Dictionary:
	var c=class_def(id);var mod={} if id=="persona" else person(id).mod
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

func advance() -> bool:
	if not expedition():return super()
	var r=s.run
	if not active() or r.phase!="explore" or r.step>=5 or r.ask:return false
	r.step+=1
	var out=expedition_rules.discovery(dungeon_rules.ex_roll(int(r.seed),int(r.floor),int(r.step),int(r.elites),party_classes()),int(r.seed),int(r.floor),int(r.step),expedition_mods())
	r.event=out.kind
	if out.kind in ["battle","elite"]:
		if out.kind=="elite":r.elites+=1
		r.kind=out.kind;r.phase="battle";r.battle={};r.resolved=false
		return true
	if out.kind=="coin":r.gold+=out.gold;r.last="낡은 주머니에서 주화 %d닢을 찾았다."%out.gold
	elif out.kind=="item":
		r.loot_items[out.item]=r.loot_items.get(out.item,0)+out.count
		var count=["하나","둘","셋"][out.count-1] if out.count in [1,2,3] else str(out.count)
		r.last=ExpeditionText.u("{item} {count}{suffix} 주웠다.",{"item":expedition_item_name(out.item),"count":count,"suffix":"를" if out.count==1 else "을"})
	else:append_expedition_gear(out.code);r.last="장비를 발견했다: %s."%expedition_gear_label(out.code)
	append_expedition_log("탐색 %d: %s"%[r.step,r.last]);note(r.last)
	if r.step>=5:enter_dungeon_rest()
	return true

func enter_dungeon_rest():
	if not expedition():super();return
	var r=s.run;r.phase="rest";r.ask=false
	if r.rested:return
	r.rested=true
	var mods=expedition_mods();var gains=[]
	for id in expedition_ids():
		var b=r.maxima[id];var m=s.members[id];var h=m.hp;var p=m.mp
		m.hp=mini(b.hp,h+int(floor(b.hp*(dungeon_rules.config.explore.REST_HP+mods.rest_hp)+.5)))
		m.mp=mini(b.mp,p+int(floor(b.mp*(dungeon_rules.config.explore.REST_MP+mods.rest_mp)+.5)))
		gains.append("%s HP +%d"%[expedition_member_name(id),m.hp-h]+(", MP +%d"%(m.mp-p) if b.mp>0 else ""))
	r.last=ExpeditionText.u("휴식. 파티 전원이 숨을 돌렸다({gain})",{"gain":" / ".join(gains)})
	append_expedition_log("휴식: 파티 HP +%d%%"%int(floor((dungeon_rules.config.explore.REST_HP+mods.rest_hp)*100+.5)))
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
	for id in expedition_ids():
		var a=b.ally(id);var m=s.members[id]
		s.run.maxima[id]={"hp":int(floor(a.mhp)),"mp":int(floor(a.mmp))}
		m.hp=maxi(1,int(floor(a.hp))) if a.hp>0 else (maxi(1,int(floor(a.mhp*dungeon_rules.config.explore.DOWN_HP))) if dungeon_rules.config.explore.DOWN_HP>0 else 0)
		m.mp=maxi(0,int(floor(a.mp)))
		if a.hp<=0:s.run.fell=true

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
	var out=[];var lost=0
	for code in codes:
		var entry=combat_gear_adapter.source_drop({"code":code},int(s.serial)+1)
		if entry.is_empty():continue
		var worn=[]
		for eq in s.equipment.values():worn.append_array(eq.values())
		if s.gear.filter(func(e):return e.uid not in worn).size()>=2000:
			if not s.has("gear_r22"):s.gear_r22={}
			if not s.gear_r22.has("overflow"):s.gear_r22.overflow=[]
			s.gear_r22.overflow.append({"code":code,"forge":{"lv":0,"tries":0}})
			lost+=1;continue
		s.serial+=1;s.gear.append(entry);out.append(code)
	return {"gear":out,"lost":lost}

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
	if xp>0:
		# P5 source pays on settlement. Never replay XP already paid by a pre-P5 run.
		award_persona_exp({"exp":xp,"sid":int(r.id)*32+31,"pm":r.persona_pm})
	var aff=(r.wins*dungeon_rules.config.affection.BATTLE+(dungeon_rules.config.affection.BOSS if result=="clear" else 0))*mods.aff
	for id in expedition_ids():
		var m=s.members[id]
		gains.append({"id":id,"before":before[id],"level":expedition_level(id),"xp":expedition_experience(id)})
		if id!="persona" and result!="defeat" and aff>0:
			var old=m.aff;m.aff=TOWN_RULES.aff_next(m.aff,aff);affection[id]=snappedf(m.aff-old,.01)
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
	return true

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
