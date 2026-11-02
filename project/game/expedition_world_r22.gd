extends "res://game/persona_world.gd"
## P5 facade. Old runs retain their original payment contract; new floors use P5.
const ExpeditionRules=preload("res://game/expedition_rules_r22.gd")
var expedition_rules=ExpeditionRules.new()

func expedition() -> bool:return r21() and s.run.get("expedition_version",0)==22
func expedition_ids() -> Array:return s.run.get("persona_party",s.party).duplicate() if active() else sortie_ids()
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
	return super(sortie_filter(filter))

func sortie_filter(filter: String) -> String:
	return filter if filter in ["front","back"] else ""

func sortie_summary(enemy_level: int=0) -> Dictionary:
	var ids=sortie_ids();var total=0;var front=0;var warns=[]
	for id in ids:
		total+=int(s.members[id].level)
		if person(id).row=="전열":front+=1
	var avg=int(floor(float(total)/ids.size())) if not ids.is_empty() else 0
	if not ids.is_empty() and front==0:warns.append("앞에서 막을 사람이 없습니다. 전열이 한 명도 없으면 후열이 바로 맞습니다.")
	if not ids.is_empty() and enemy_level-avg>=5:warns.append("위험합니다. 적이 파티 평균보다 %d레벨 높습니다."%(enemy_level-avg))
	return {"n":ids.size(),"avg":avg,"elv":enemy_level,"front":front,"warns":warns}

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
	if out.kind=="coin":r.gold+=out.gold;log_expedition("탐색 %d: 주화 %d닢 발견"%[r.step,out.gold])
	elif out.kind=="item":
		r.loot_items[out.item]=r.loot_items.get(out.item,0)+out.count
		log_expedition("탐색 %d: %s ×%d 발견"%[r.step,item_def(web_item_id(out.item)).name,out.count])
	else:append_expedition_gear(out.code);log_expedition("탐색 %d: 장비 발견 · %s"%[r.step,gear.by_id[out.code.split(".")[0]].name])
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
		gains.append("%s HP +%d · MP +%d"%[person(id).name,m.hp-h,m.mp-p])
	log_expedition("휴식: "+" / ".join(gains))

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
	var p=item_preview(id,who)
	if not p.usable:return false
	if item_def(id).kind=="return":
		if not take_supply(id):return false
		return settle("retreat")
	if not take_supply(id):return false
	s.members[who]["mp" if p.resource=="MP" else "hp"]=p.after
	log_expedition(person(who).name+" · "+item_def(id).name+" 사용")
	return true

func can_expedition_equip(who: String) -> bool:return expedition() and active() and s.run.phase=="rest" and who in expedition_ids()
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
